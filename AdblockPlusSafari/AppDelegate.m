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

#import "AppDelegate.h"

#import "Appearence.h"
#import "RootController.h"
#import "FilterList.h"

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

  if (!self.firstUpdateTriggered && !self.adblockPlus.updating) {
    NSDictionary *filterLists = [self.adblockPlus outdatedFilterLists];
    if (filterLists.count > 0) {
      [self.adblockPlus updateFilterLists:filterLists userTriggered:NO];
      self.firstUpdateTriggered = YES;
    }
  }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

#pragma mark - Background mode

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  NSDictionary *outdatedFilterLists = self.adblockPlus.outdatedFilterLists;

  if ([outdatedFilterLists count] > 0) {
    [self.adblockPlus updateFilterLists:outdatedFilterLists userTriggered:NO];

    [self.backgroundFetches addObject:
     @{@"completion": completionHandler,
       @"filterLists": outdatedFilterLists,
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

        BOOL updated = NO;

        NSDictionary<NSString *, id> *filterLists = backgroundFetch[@"filterLists"];
        for (NSString *filterListName in filterLists) {
          NSDictionary<NSString *, id> *filterList = filterLists[filterListName];
          // The date of the last known successful update
          NSDate *lastUpdate = filterList[@"lastUpdate"];

          NSDate *currentLastUpdate = self.adblockPlus.filterLists[filterListName][@"lastUpdate"];

          updated = updated || (!lastUpdate && currentLastUpdate) || (currentLastUpdate && [currentLastUpdate compare:lastUpdate] == NSOrderedDescending);
        }

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

- (NSMutableArray<NSDictionary *> *)backgroundFetches
{
  if (!_backgroundFetches) {
    _backgroundFetches = [NSMutableArray array];
  }
  return _backgroundFetches;
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
