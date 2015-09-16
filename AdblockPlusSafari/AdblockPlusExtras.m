//
//  AdblockPlusExtras.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 16/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "AdblockPlusExtras.h"

@import SafariServices;



@interface AdblockPlusExtras ()<NSURLSessionDownloadDelegate, NSFileManagerDelegate>

@property (nonatomic, weak) NSURLSession *backgroundSession;
@property (nonatomic, strong) NSMutableDictionary<NSString *, __kindof NSURLSessionTask *> *downloadTasks;

@end

@implementation AdblockPlusExtras

- (instancetype)init
{
  if (self = [super init]) {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.backgroundSessionConfigurationIdentifier];
    _backgroundSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    _downloadTasks = [[NSMutableDictionary alloc] init];

    _updating = [[[self.filterlists allValues] valueForKeyPath:@"@sum.updating"] integerValue] > 0;
    _lastUpdate = [[self.filterlists allValues] valueForKeyPath:@"@min.lastUpdate"];

    __weak __typeof(self) wSelf = self;
    [_backgroundSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
      __strong __typeof(wSelf) sSelf = wSelf;
      if (sSelf) {
        NSMutableSet<NSString *> *set = [NSMutableSet setWithArray:sSelf.filterlists.allKeys];
        for (NSURLSessionTask *task in tasks) {
          [set removeObject:task.originalRequest.URL.absoluteString];
          sSelf.downloadTasks[task.originalRequest.URL.absoluteString] = task;
        }
        if ([set count] > 0) {
          NSMutableDictionary *filterlists = [sSelf.filterlists mutableCopy];
          for (NSString *key in set) {
            NSMutableDictionary *filterlist = [filterlists[key] mutableCopy];
            filterlist[@"updating"] = @NO;
            filterlists[key] = filterlist;
          }
          sSelf.filterlists = filterlists;
        }
      }
    }];
  }
  return self;
}

#pragma mark - property

- (void)setFilterlists:(NSDictionary<NSString *,NSDictionary<NSString *,NSObject *> *> *)filterlists
{
  super.filterlists = filterlists;

  self.updating = [[[filterlists allValues] valueForKeyPath:@"@sum.updating"] integerValue] > 0;
  self.lastUpdate = [[filterlists allValues] valueForKeyPath:@"@min.lastUpdate"];
}

- (void)setUpdating:(BOOL)updating
{
  // Force content blocker to load newer version of filterlist
  if (_updating && !updating && self.installedVersion < self.downloadedVersion) {
    [self reloadContentBlockerWithCompletion:nil];
  }
  _updating = updating;
}

#pragma mark -

- (void)setEnabled:(BOOL)enabled reload:(BOOL)reload
{
  self.enabled = enabled;

  if (reload) {
    [self reloadContentBlockerWithCompletion:nil];
  }
}

- (void)setAcceptableAdsEnabled:(BOOL)enabled reload:(BOOL)reload
{
  self.acceptableAdsEnabled = enabled;

  if (reload) {
    [self reloadContentBlockerWithCompletion:nil];
  }
}

- (void)reloadContentBlockerWithCompletion:(void(^__nullable)(NSError * __nullable error))completion;
{
  __weak __typeof(self) wSelf = self;
  wSelf.reloading = YES;
  [SFContentBlockerManager reloadContentBlockerWithIdentifier:self.contentBlockerIdentifier completionHandler:^(NSError *error) {
    NSLog(@"%@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
      wSelf.reloading = NO;
      [wSelf checkActivatedFlag];
      if (completion) {
        completion(error);
      }
    });
  }];
}

- (void)checkActivatedFlag
{
  BOOL activated = [self.adblockPlusDetails boolForKey:AdblockPlusActivated];
  if (self.activated != activated) {
    self.activated = activated;
  }
}

- (void)updateFilterlists
{
  NSMutableDictionary *filterlists = [self.filterlists mutableCopy];
  for (NSString *filterlistName in self.filterlists) {
    NSURL *url = [NSURL URLWithString:filterlistName];

    NSURLSessionTask *task = [self.backgroundSession downloadTaskWithURL:url];

    NSMutableDictionary *filterlist = [filterlists[filterlistName] mutableCopy];
    filterlist[@"updating"] = @YES;
    filterlist[@"taskIdentifier"] = @(task.taskIdentifier);
    filterlists[filterlistName] = filterlist;

    [self.downloadTasks[filterlistName] cancel];
    // Store key to task cache
    self.downloadTasks[filterlistName] = task;

    [task resume];
  }
  self.filterlists = filterlists;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  NSString *filterlistName = task.originalRequest.URL.absoluteString;
  NSDictionary *filterlist = self.filterlists[filterlistName];

  if ([filterlist[@"taskIdentifier"] unsignedIntegerValue] == task.taskIdentifier && [filterlist[@"updating"] boolValue]) {

    NSMutableDictionary *mutableFilterlist = [filterlist mutableCopy];
    mutableFilterlist[@"updating"] = @NO;
    [mutableFilterlist removeObjectForKey:@"taskIdentifier"];

    NSMutableDictionary *mutableFilterlists = [self.filterlists mutableCopy];
    mutableFilterlists[filterlistName] = mutableFilterlist;
    self.filterlists = mutableFilterlists;

    // Remove key from task cache
    [self.downloadTasks removeObjectForKey:filterlistName];
  }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
  NSString *filterlistName = downloadTask.originalRequest.URL.absoluteString;
  NSDictionary *filterlist = self.filterlists[filterlistName];

  if ([filterlist[@"taskIdentifier"] unsignedIntegerValue] == downloadTask.taskIdentifier) {

    NSString *errorMessage;

    {
      if (![downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
        // This error occurs in rare cases. The error message is meaningless to ordinary user.
        NSLog(@"Downloading has failed: %@", downloadTask.error);
        errorMessage = @"";
        goto END;
      }

      NSHTTPURLResponse *response = (NSHTTPURLResponse *)downloadTask.response;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        errorMessage = [NSString stringWithFormat:@" Remote server responded: %ld (%@).", response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
        goto END;
      }

      NSFileManager *fileManager = [[NSFileManager alloc] init];
      fileManager.delegate = self;

      // http://www.atomicbird.com/blog/sharing-with-app-extensions
      NSURL *destination = [fileManager containerURLForSecurityApplicationGroupIdentifier:self.group];
      destination = [destination URLByAppendingPathComponent:filterlist[@"filename"] isDirectory:NO];

      NSError *error;
      // http://stackoverflow.com/questions/20683696/how-to-overwrite-a-folder-using-nsfilemanager-defaultmanager-when-copying
      if (![fileManager moveItemAtURL:location toURL:destination error:&error]) {
        NSLog(@"Moving has failed: %@", error);
        errorMessage = @"";
        goto END;
      }

      // Success, store the result
      NSMutableDictionary *mutableFilterlist = [filterlist mutableCopy];
      mutableFilterlist[@"updating"] = @NO;
      mutableFilterlist[@"lastUpdate"] = [NSDate date];
      mutableFilterlist[@"downloaded"] = @YES;
      self.downloadedVersion += 1;

      NSMutableDictionary *mutableFilterlists = [self.filterlists mutableCopy];
      mutableFilterlists[filterlistName] = mutableFilterlist;
      self.filterlists = mutableFilterlists;
    }

  END:
    if (errorMessage) {
      UIViewController *viewController = UIApplication.sharedApplication.delegate.window.rootViewController;
      while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
      }

      NSString *title = @"Updating filterlists";
      NSString *message = [NSString stringWithFormat:@"Filterlist %@ cannot be updated.%@", filterlistName, errorMessage];

      UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
      alertController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
      [viewController presentViewController:alertController animated:YES completion:nil];
    }
  }
}

#pragma mark - NSFileManagerDelegate

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
  if ([error code] == NSFileWriteFileExistsError) {
    return YES;
  } else {
    return NO;
  }
}

@end
