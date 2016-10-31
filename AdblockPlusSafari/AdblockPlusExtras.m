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
#import "NSDictionary+FilterList.h"

static NSString *AdblockPlusNeedsDisplayErrorDialog = @"AdblockPlusNeedsDisplayErrorDialog";

@interface AdblockPlusExtras ()<NSURLSessionDownloadDelegate, NSFileManagerDelegate>

@property (nonatomic, weak) NSURLSession *backgroundSession;
@property (nonatomic, strong) NSMutableDictionary<NSString *, __kindof NSURLSessionTask *> *downloadTasks;
@property (nonatomic) BOOL needsDisplayErrorDialog;
@property (nonatomic) NSUInteger updatingGroupIdentifier;

@end

@implementation AdblockPlusExtras

- (instancetype)init
{
  if (self = [super init]) {
    // Remove updatingGroupIdentifier, which is only runtime attribute
    NSMutableDictionary *modifiedFilterLists = [self.filterLists mutableCopy];
    for (NSString *filterListName in self.filterLists) {
      NSMutableDictionary *modifiedFilterList = [self.filterLists[filterListName] mutableCopy];
      [modifiedFilterList removeObjectForKey:@"updatingGroupIdentifier"];
      modifiedFilterLists[filterListName] = modifiedFilterList;
    }
    self.filterLists = modifiedFilterLists;

    // Process running tasks
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
          NSString *url = task.originalRequest.URL.absoluteString;
          BOOL found = NO;
          for (NSString *filterListName in sSelf.filterLists) {
            NSDictionary *filterList = sSelf.filterLists[filterListName];
            if ([url isEqualToString:filterList[@"url"]]) {
              if (task.taskIdentifier == [sSelf.filterLists[filterListName] taskIdentifier]) {
                sSelf.downloadTasks[task.originalRequest.URL.absoluteString] = task;
              } else {
                [task cancel];
              }
              found = YES;
              break;
            }
          }

          if (!found) {
            [task cancel];
          }
        }

        // Remove filter lists whose tasks have been found
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

@dynamic updating;

- (BOOL)updating
{
  return [[[self.filterLists allValues] valueForKeyPath:@"@sum.updating"] integerValue] > 0;
}

- (void)setFilterLists:(NSDictionary<NSString *,NSDictionary<NSString *,NSObject *> *> *)filterLists
{
  NSAssert([NSThread isMainThread], @"This method should be called from main thread only!");

  BOOL wasUpdating = self.updating;
  BOOL hasAnyLastUpdateFailed = self.anyLastUpdateFailed;

  [self willChangeValueForKey:@"updating"];
  super.filterLists = filterLists;
  [self didChangeValueForKey:@"updating"];

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
  for (NSString *filterListName in self.filterLists) {
    NSDictionary *filterList = self.filterLists[filterListName];
    if ([filterList[@"updatingGroupIdentifier"] unsignedIntegerValue] == self.updatingGroupIdentifier
        && [filterList[@"lastUpdateFailed"] boolValue]
        && [filterList[@"userTriggered"] boolValue]) {
      return YES;
    }
  }

  return NO;
}

#pragma mark -

- (void)setEnabled:(BOOL)enabled
{
  super.enabled = enabled;
  [self reloadContentBlockerWithCompletion:nil];
}

- (void)setAcceptableAdsEnabled:(BOOL)enabled
{
  super.acceptableAdsEnabled = enabled;
  [self reloadContentBlockerWithCompletion:nil];
  [self updateFilterListsWithNames:self.outdatedFilterListNames userTriggered:NO];
}

-(void)setDefaultFilterListEnabled:(BOOL)defaultFilterListEnabled
{
  super.defaultFilterListEnabled = defaultFilterListEnabled;
  [self reloadContentBlockerWithCompletion:nil];
  [self updateFilterListsWithNames:self.outdatedFilterListNames userTriggered:NO];
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

- (void)updateActiveFilterLists:(BOOL)userTriggered
{
  [self updateFilterListsWithNames:@[self.activeFilterListName] userTriggered:userTriggered];
}

- (void)updateFilterListsWithNames:(NSArray<NSString *> *)filterListNames userTriggered:(BOOL)userTriggered
{
  if ([filterListNames count] == 0) {
    return;
  }

  self.updatingGroupIdentifier += 1;

  NSMutableDictionary *scheduledTasks = [NSMutableDictionary dictionary];

  NSMutableDictionary *modifiedFilterLists = [self.filterLists mutableCopy];
  for (NSString *filterListName in filterListNames) {
    FilterList *filterList = [[FilterList alloc] initWithDictionary:self.filterLists[filterListName]];

    NSURL *url = [NSURL URLWithString:filterList.url];
    NSURLSessionTask *task = [self.backgroundSession downloadTaskWithURL:url];
    scheduledTasks[filterListName] = task;

    filterList.updating = YES;
    filterList.taskIdentifier = task.taskIdentifier;
    filterList.updatingGroupIdentifier = self.updatingGroupIdentifier;
    filterList.userTriggered = userTriggered;
    filterList.lastUpdateFailed = NO;
    modifiedFilterLists[filterListName] = filterList.dictionary;
  }
  self.filterLists = modifiedFilterLists;

  for (NSString *filterListName in scheduledTasks) {
    NSURLSessionTask *task = scheduledTasks[filterListName];

    [self.downloadTasks[filterListName] cancel];
    // Store key to task cache
    self.downloadTasks[filterListName] = task;

    [task resume];
  }
}

- (NSArray<NSString *> *)outdatedFilterListNames
{
  NSDate *now = [NSDate date];
  NSMutableArray<NSString *> *outdatedFilterListNames = [NSMutableArray array];

  NSString *filterListName = self.activeFilterListName;
  FilterList *filterList = [[FilterList alloc] initWithDictionary:self.filterLists[filterListName]];
  if (filterList) {
    NSDate *lastUpdate = filterList.lastUpdate;
    if (lastUpdate == nil || lastUpdate.timeIntervalSince1970 + filterList.expires <= now.timeIntervalSince1970) {
      [outdatedFilterListNames addObject:filterListName];
    }
  }

  return outdatedFilterListNames;
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
  NSString *filterListName = [self filterListNameForTaskTaskIdentifier:task.taskIdentifier];
  FilterList *filterList = [[FilterList alloc] initWithDictionary:self.filterLists[filterListName]];
  if (filterList) {
    filterList.lastUpdateFailed = YES;
    filterList.updating = NO;
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
  NSString *filterListName = [self filterListNameForTaskTaskIdentifier:downloadTask.taskIdentifier];
  FilterList *filterList = [[FilterList alloc] initWithDictionary:self.filterLists[filterListName]];
  if (filterList) {
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
    destination = [destination URLByAppendingPathComponent:filterList.fileName isDirectory:NO];

    NSError *error;
    // http://stackoverflow.com/questions/20683696/how-to-overwrite-a-folder-using-nsfilemanager-defaultmanager-when-copying
    if (![fileManager moveItemAtURL:location toURL:destination error:&error]) {
      NSLog(@"Moving has failed: %@", error);
      return;
    }

    // Success, store the result
    filterList.lastUpdate = [NSDate date];
    filterList.downloaded = YES;
    filterList.lastUpdateFailed = NO;
    filterList.updating = NO;
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

- (NSString *)filterListNameForTaskTaskIdentifier:(NSUInteger)taskIdentifier
{
  for (NSString *filterListName in self.filterLists) {
    NSDictionary *filterList = self.filterLists[filterListName];
    if (taskIdentifier == filterList.taskIdentifier) {
      return filterListName;
    }
  }
  return nil;
}

@end
