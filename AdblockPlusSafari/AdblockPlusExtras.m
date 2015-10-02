/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-2015 Eyeo GmbH
 *
 * Adblock Plus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Adblock Plus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/&gt.
 */

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

    // Update filter lists with statuses of task running in background (outside application scope).
    __weak __typeof(self) wSelf = self;
    [_backgroundSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
      __strong __typeof(wSelf) sSelf = wSelf;
      if (sSelf) {
        NSMutableSet<NSString *> *set = [NSMutableSet setWithArray:sSelf.filterLists.allKeys];

        // Remove filter lists whose tasks are still running
        for (NSURLSessionTask *task in tasks) {
          NSString *filterlistName = task.originalRequest.URL.absoluteString;
          [set removeObject:filterlistName];
          if (task.taskIdentifier == [sSelf.filterLists[filterlistName][@"taskIdentifier"] unsignedIntegerValue]) {
            sSelf.downloadTasks[task.originalRequest.URL.absoluteString] = task;
          } else {
            [task cancel];
          }
        }

        // Remove filter lists whose tasks have been planned again
        for (NSString *filterlistName in self.downloadTasks) {
          [set removeObject:filterlistName];
        }

        // Set updating flag to false of filterlist, which was cancelled by user (user killed application).
        if ([set count] > 0) {
          NSMutableDictionary *filterlists = [sSelf.filterLists mutableCopy];
          for (NSString *key in set) {
            NSMutableDictionary *filterlist = [filterlists[key] mutableCopy];
            filterlist[@"updating"] = @NO;
            filterlists[key] = filterlist;
          }
          sSelf.filterLists = filterlists;
        }
      }
    }];
  }
  return self;
}

#pragma mark - property

@dynamic lastUpdate;
@dynamic updating;

- (NSDate *)lastUpdate
{
  return [[self.filterLists allValues] valueForKeyPath:@"@min.lastUpdate"];
}

- (BOOL)updating
{
  return [[[self.filterLists allValues] valueForKeyPath:@"@sum.updating"] integerValue] > 0;
}

- (void)setFilterLists:(NSDictionary<NSString *,NSDictionary<NSString *,NSObject *> *> *)filterLists
{
  BOOL updating = self.updating;

  [self willChangeValueForKey:@"lastUpdate"];
  [self willChangeValueForKey:@"updating"];
  super.filterLists = filterLists;
  [self didChangeValueForKey:@"updating"];
  [self didChangeValueForKey:@"lastUpdate"];

  if (self.installedVersion < self.downloadedVersion && updating && !self.updating) {
    // Force content blocker to load newer version of filterlist
    [self reloadContentBlockerWithCompletion:nil];
  }
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
  NSMutableDictionary *filterlists = [self.filterLists mutableCopy];
  for (NSString *filterlistName in self.filterLists) {
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
  self.filterLists = filterlists;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  NSString *filterlistName = task.originalRequest.URL.absoluteString;
  NSDictionary *filterlist = self.filterLists[filterlistName];

  if ([filterlist[@"taskIdentifier"] unsignedIntegerValue] == task.taskIdentifier && [filterlist[@"updating"] boolValue]) {

    NSMutableDictionary *mutableFilterlist = [filterlist mutableCopy];
    mutableFilterlist[@"updating"] = @NO;
    [mutableFilterlist removeObjectForKey:@"taskIdentifier"];

    NSMutableDictionary *mutableFilterlists = [self.filterLists mutableCopy];
    mutableFilterlists[filterlistName] = mutableFilterlist;
    self.filterLists = mutableFilterlists;

    // Remove key from task cache
    [self.downloadTasks removeObjectForKey:filterlistName];
  }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
  NSString *filterListName = downloadTask.originalRequest.URL.absoluteString;
  NSDictionary *filterList = self.filterLists[filterListName];

  if ([filterList[@"taskIdentifier"] unsignedIntegerValue] == downloadTask.taskIdentifier) {
    if (![downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
      // This error occurs in rare cases. The error message is meaningless to ordinary user.
      NSLog(@"Downloading has failed: %@", downloadTask.error);
      [self displayErrorDialog:filterListName withErrorMessage:@""];
      return;
    }

    NSHTTPURLResponse *response = (NSHTTPURLResponse *)downloadTask.response;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      NSString *errorMessage = [NSString stringWithFormat:@" Remote server responded: %ld (%@).", response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
      [self displayErrorDialog:filterListName withErrorMessage:errorMessage];
      return;
    }

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    fileManager.delegate = self;

    // http://www.atomicbird.com/blog/sharing-with-app-extensions
    NSURL *destination = [fileManager containerURLForSecurityApplicationGroupIdentifier:self.group];
    destination = [destination URLByAppendingPathComponent:filterList[@"filename"] isDirectory:NO];

    NSError *error;
    // http://stackoverflow.com/questions/20683696/how-to-overwrite-a-folder-using-nsfilemanager-defaultmanager-when-copying
    if (![fileManager moveItemAtURL:location toURL:destination error:&error]) {
      NSLog(@"Moving has failed: %@", error);
      [self displayErrorDialog:filterListName withErrorMessage:@""];
      return;
    }

    // Success, store the result
    NSMutableDictionary *mutableFilterList = [filterList mutableCopy];
    mutableFilterList[@"updating"] = @NO;
    mutableFilterList[@"lastUpdate"] = [NSDate date];
    mutableFilterList[@"downloaded"] = @YES;
    self.downloadedVersion += 1;

    NSMutableDictionary *mutableFilterLists = [self.filterLists mutableCopy];
    mutableFilterLists[filterListName] = mutableFilterList;
    self.filterLists = mutableFilterLists;
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

#pragma mark - Private

- (void)displayErrorDialog:(NSString *)filterlistName withErrorMessage:(NSString *)errorMessage
{
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

@end
