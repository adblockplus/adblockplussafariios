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

#import "AppDelegate.h"

#import "Appearence.h"
#import "RootController.h"

// Update filter list every 5 days
const NSTimeInterval FilterlistsUpdatePeriod = 3600*24*5;
// Wake up application every hour (just hint for iOS)
const NSTimeInterval BackgroundFetchInterval = 3600;

@interface AppDelegate ()

@property (nonatomic, strong) AdblockPlusExtras *adblockPlus;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *backgroundFetches;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic) BOOL firstUpdateTriggered;

@end

@implementation AppDelegate

- (void)dealloc
{
  self.adblockPlus = nil;
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [Appearence applyAppearence];
  return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.adblockPlus = [[AdblockPlusExtras alloc] init];
  self.firstUpdateTriggered = NO;

  if ([self.window.rootViewController isKindOfClass:[RootController class]]) {
    ((RootController *)self.window.rootViewController).adblockPlus = self.adblockPlus;
  }

  [application setMinimumBackgroundFetchInterval:BackgroundFetchInterval];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  if (!self.adblockPlus.reloading) {
    return;
  }

  __weak __typeof(self) wSelf = self;
  __weak __typeof(application) wApplication = application;

  self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
    [wSelf setBackgroundTaskIdentifier:UIBackgroundTaskInvalid withApplication:wApplication];
  }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  [self setBackgroundTaskIdentifier:UIBackgroundTaskInvalid withApplication:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  [self.adblockPlus checkActivatedFlag];

  if (!self.firstUpdateTriggered && !self.adblockPlus.updating && self.adblockPlus.lastUpdate == nil) {
    [self.adblockPlus updateFilterlists: NO];
    self.firstUpdateTriggered = YES;
  }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

#pragma mark - Background mode

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  NSDate *lastUpdate = self.adblockPlus.lastUpdate;
  if (!lastUpdate) {
    lastUpdate = [NSDate distantPast];
  }

  if ([lastUpdate timeIntervalSinceNow] <= -FilterlistsUpdatePeriod) {
    [self.adblockPlus updateFilterlists: NO];
    if (!self.backgroundFetches) {
      self.backgroundFetches = [NSMutableArray array];
    }
    [self.backgroundFetches addObject:
     @{@"completion": completionHandler,
       @"lastUpdate": lastUpdate,
       @"version": @(self.adblockPlus.downloadedVersion),
       @"startDate": [NSDate date]}];
  } else {
    // No need to perform background refresh
    NSLog(@"List is up to date");
    completionHandler(UIBackgroundFetchResultNoData);
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(reloading))]) {

    BOOL reloading = [change[NSKeyValueChangeNewKey] boolValue];

    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid && !reloading) {
      self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }

    UIApplication *application = UIApplication.sharedApplication;

    BOOL isBackground = application.applicationState != UIApplicationStateActive;

    if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid && reloading && isBackground) {
      __weak __typeof(self) wSelf = self;
      __weak __typeof(application) wApplication = application;

      self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        [wSelf setBackgroundTaskIdentifier:UIBackgroundTaskInvalid withApplication:wApplication];
      }];
    }
  } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(filterLists))]) {

    AdblockPlusExtras *adblockPlus = object;
    if (!adblockPlus.updating) {

      for (NSDictionary *backgroundFetch in self.backgroundFetches) {

        // The date of the last known successful update
        NSDate *lastUpdate = backgroundFetch[@"lastUpdate"];
        BOOL updated = !!lastUpdate && [adblockPlus.lastUpdate compare:lastUpdate] == NSOrderedDescending;

        void (^completion)(UIBackgroundFetchResult) = backgroundFetch[@"completion"];
        if (completion) {
          completion(updated ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultFailed);
        }

        NSTimeInterval timeElapsed = -[backgroundFetch[@"startDate"] timeIntervalSinceNow];
        NSLog(@"Background Fetch Duration: %f seconds, Updated: %d", timeElapsed, updated);
      }
      [self.backgroundFetches removeAllObjects];
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier
                    withApplication:(UIApplication *)application
{
  if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
    [application endBackgroundTask:self.backgroundTaskIdentifier];
  }
  self.backgroundTaskIdentifier = backgroundTaskIdentifier;
}

#pragma mark -

-(void)setAdblockPlus:(AdblockPlusExtras *)adblockPlus
{
  AdblockPlusExtras *oldAdblockPlus = _adblockPlus;
  _adblockPlus = adblockPlus;

  for (NSString *keyPath in @[NSStringFromSelector(@selector(filterLists)),
                              NSStringFromSelector(@selector(reloading))]) {
    [oldAdblockPlus removeObserver:self
                        forKeyPath:keyPath
                           context:nil];
    [adblockPlus addObserver:self
                  forKeyPath:keyPath
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                     context:nil];
  }
}

@end
