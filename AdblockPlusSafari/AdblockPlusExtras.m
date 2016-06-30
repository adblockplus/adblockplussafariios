/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-2016 Eyeo GmbH
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

#import "RootController.h"
#import "HomeController.h"
#import "FilterList+Processing.h"

static NSString *AdblockPlusNeedsDisplayErrorDialog = @"AdblockPlusNeedsDisplayErrorDialog";

@interface AdblockPlusExtras ()<NSURLSessionDownloadDelegate, NSFileManagerDelegate>

@property (nonatomic, weak) NSURLSession *backgroundSession;
@property (nonatomic, strong) NSMutableDictionary<NSString *, __kindof NSURLSessionTask *> *downloadTasks;
@property (nonatomic) BOOL needsDisplayErrorDialog;

@end

@implementation AdblockPlusExtras

- (instancetype)init
{
  if (self = [super init]) {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.backgroundSessionConfigurationIdentifier];
    _backgroundSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    _downloadTasks = [[NSMutableDictionary alloc] init];
    _needsDisplayErrorDialog = [self.adblockPlusDetails boolForKey:AdblockPlusNeedsDisplayErrorDialog];

    // Update filter lists with statuses of task running in background (outside application scope).
    __weak __typeof(self) wSelf = self;
    [_backgroundSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
      __strong __typeof(wSelf) sSelf = wSelf;
      if (sSelf) {
        NSMutableSet<NSString *> *set = [NSMutableSet setWithArray:sSelf.filterLists.allKeys];

        // Remove filter lists whose tasks are still running
        for (NSURLSessionTask *task in tasks) {
          NSString *filterListName = task.originalRequest.URL.absoluteString;
          [set removeObject:filterListName];
          if (task.taskIdentifier == [sSelf.filterLists[filterListName][@"taskIdentifier"] unsignedIntegerValue]) {
            sSelf.downloadTasks[task.originalRequest.URL.absoluteString] = task;
          } else {
            [task cancel];
          }
        }

        // Remove filter lists whose tasks have been planned again
        for (NSString *filterListName in self.downloadTasks) {
          [set removeObject:filterListName];
        }

        // Set updating flag to false of filter list, which was cancelled by user (user killed application).
        if ([set count] > 0) {
          NSMutableDictionary *filterLists = [sSelf.filterLists mutableCopy];
          for (NSString *key in set) {
            NSMutableDictionary *filterList = [filterLists[key] mutableCopy];
            filterList[@"updating"] = @NO;
            filterLists[key] = filterList;
          }
          sSelf.filterLists = filterLists;
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
  BOOL wasUpdating = self.updating;
  BOOL hasAnyLastUpdateFailed = self.anyLastUpdateFailed;

  [self willChangeValueForKey:@"lastUpdate"];
  [self willChangeValueForKey:@"updating"];
  super.filterLists = filterLists;
  [self didChangeValueForKey:@"updating"];
  [self didChangeValueForKey:@"lastUpdate"];

  BOOL updating = self.updating;
  BOOL anyLastUpdateFailed = self.anyLastUpdateFailed;

  if (self.installedVersion < self.downloadedVersion && wasUpdating && !updating) {
    // Force content blocker to load newer version of filter lists
    [self reloadContentBlockerWithCompletion:nil];
  }

  if (hasAnyLastUpdateFailed != anyLastUpdateFailed) {
    self.needsDisplayErrorDialog = anyLastUpdateFailed;
    [self displayErrorDialogIfNeeded];
  }
}

- (void)setWhitelistedWebsites:(NSArray<NSString *> *)whitelistedWebsites
{
  super.whitelistedWebsites = whitelistedWebsites;
  [self reloadContentBlockerWithCompletion:nil];
}

- (void)setNeedsDisplayErrorDialog:(BOOL)needsDisplayErrorDialog
{
  _needsDisplayErrorDialog = needsDisplayErrorDialog;
  [self.adblockPlusDetails setBool:needsDisplayErrorDialog forKey:AdblockPlusNeedsDisplayErrorDialog];
  [self.adblockPlusDetails synchronize];
}

- (BOOL)anyLastUpdateFailed
{
  return [[[self.filterLists allValues] valueForKeyPath:@"@sum.lastUpdateFailed"] integerValue] > 0;
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

- (void)updateAllFilterLists:(BOOL)userTriggered
{
  [self updateFilterLists:self.filterLists userTriggered:YES];
}

- (void)updateFilterLists:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)filterLists userTriggered:(BOOL)userTriggered
{
  NSMutableDictionary *modifiedFilterLists = [self.filterLists mutableCopy];
  for (NSString *filterListName in filterLists) {
    NSURL *url = [NSURL URLWithString:filterListName];

    NSURLSessionTask *task = [self.backgroundSession downloadTaskWithURL:url];

    FilterList *filterList = [[FilterList alloc] initWithDictionary:filterLists[filterListName]];
    filterList.updating = YES;
    filterList.taskIdentifier = task.taskIdentifier;
    filterList.userTriggered = userTriggered;
    filterList.lastUpdateFailed = NO;
    modifiedFilterLists[filterListName] = filterList.dictionary;

    [self.downloadTasks[filterListName] cancel];
    // Store key to task cache
    self.downloadTasks[filterListName] = task;

    [task resume];
  }
  self.filterLists = modifiedFilterLists;
}

- (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)outdatedFilterLists
{
  NSDate *now = [NSDate date];
  NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *outdatedFilterLists = [self.filterLists mutableCopy];
  for (NSString *filterListName in self.filterLists) {
    FilterList *filterList = [[FilterList alloc] initWithDictionary:self.filterLists[filterListName]];

    NSDate *lastUpdate = filterList.lastUpdate;
    if (lastUpdate == nil) {
      continue;
    }

    if (lastUpdate.timeIntervalSince1970 + filterList.expires < now.timeIntervalSince1970) {
      continue;
    }

    [outdatedFilterLists removeObjectForKey:filterListName];
  }
  return outdatedFilterLists;
}

- (void)displayErrorDialogIfNeeded
{
  if (!self.needsDisplayErrorDialog) {
    return;
  }

  // Do not show message, if update was automatic.
  if ([[[self.filterLists allValues] valueForKeyPath:@"@sum.userTriggered"] integerValue] == 0) {
    return;
  }

  if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
    return;
  }

  UIViewController *viewController = UIApplication.sharedApplication.delegate.window.rootViewController;
  if ([viewController isKindOfClass:[RootController class]]) {
    RootController *rootController = (RootController *)viewController;
    if (![rootController.viewControllers.firstObject isKindOfClass:[HomeController class]]) {
      return;
    }
  }

  while (viewController.presentedViewController) {
    viewController = viewController.presentedViewController;
  }

  NSString *title = NSLocalizedString(@"Filter list update failed", "Title of filter update failure dialog");
  NSString *message = NSLocalizedString(@"Failed to update filter lists. Please try again later.", @"Message of filter update failure dialog");

  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
  alertController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [viewController presentViewController:alertController animated:YES completion:nil];

  self.needsDisplayErrorDialog = NO;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  NSString *filterListName = task.originalRequest.URL.absoluteString;
  FilterList *filterList = [[FilterList alloc] initWithDictionary:self.filterLists[filterListName]];

  if (filterList.taskIdentifier == task.taskIdentifier && filterList.updating) {

    filterList.updating = NO;
    filterList.lastUpdateFailed = YES;
    filterList.taskIdentifier = 0;

    NSMutableDictionary *modifiedFilterLists = [self.filterLists mutableCopy];
    modifiedFilterLists[filterListName] = filterList.dictionary;
    self.filterLists = modifiedFilterLists;

    // Remove key from task cache
    [self.downloadTasks removeObjectForKey:filterListName];
  }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
  NSString *filterListName = downloadTask.originalRequest.URL.absoluteString;
  FilterList *filterList = [[FilterList alloc] initWithDictionary:self.filterLists[filterListName]];

  if (filterList.taskIdentifier == downloadTask.taskIdentifier) {
    if (![downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
      // This error occurs in rare cases. The error message is meaningless to ordinary user.
      NSLog(@"Downloading has failed: %@", downloadTask.error);
      return;
    }

    NSHTTPURLResponse *response = (NSHTTPURLResponse *)downloadTask.response;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      NSLog(@" Remote server responded: %ld (%@).", response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]);
      return;
    }

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    fileManager.delegate = self;

    // http://www.atomicbird.com/blog/sharing-with-app-extensions
    NSURL *destination = [fileManager containerURLForSecurityApplicationGroupIdentifier:self.group];
    destination = [destination URLByAppendingPathComponent:filterList.filename isDirectory:NO];

    NSError *error;
    // http://stackoverflow.com/questions/20683696/how-to-overwrite-a-folder-using-nsfilemanager-defaultmanager-when-copying
    if (![fileManager moveItemAtURL:location toURL:destination error:&error]) {
      NSLog(@"Moving has failed: %@", error);
      return;
    }

    // Success, store the result
    filterList.lastUpdate = [NSDate date];
    filterList.downloaded = YES;
    filterList.updating = NO;
    filterList.lastUpdateFailed = NO;
    filterList.taskIdentifier = 0;
    self.downloadedVersion += 1;

    if (![filterList parseFilterListFromURL:destination error:&error]) {
      NSLog(@"Filter list parsing has failed: %@", error);
      return;
    }

    // Commit changes
    NSMutableDictionary *modifiedFilterLists = [self.filterLists mutableCopy];
    modifiedFilterLists[filterListName] = [filterList dictionary];
    self.filterLists = modifiedFilterLists;
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

@end
