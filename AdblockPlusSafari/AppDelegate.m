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

@interface AppDelegate ()

@property (nonatomic, strong) AdblockPlus *adblockPlus;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
/*  for (NSString* family in [UIFont familyNames])
  {
    NSLog(@"%@", family);

    for (NSString* name in [UIFont fontNamesForFamilyName: family])
    {
      NSLog(@"  %@", name);
    }
  }
*/
  [Appearence applyAppearence];
  return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.adblockPlus = [[AdblockPlus alloc] init];

  if (!self.adblockPlus.activated) {
    [self.adblockPlus reloadContentBlockerWithCompletion:nil];
  }

  if ([self.window.rootViewController isKindOfClass:[RootController class]]) {
    ((RootController *)self.window.rootViewController).adblockPlus = self.adblockPlus;
  }

  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  [self.adblockPlus checkActivatedFlag];
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
