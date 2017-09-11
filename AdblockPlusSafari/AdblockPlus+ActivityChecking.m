/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-present eyeo GmbH
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
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "AdblockPlus+ActivityChecking.h"

@implementation AdblockPlus (ActivityChecking)

- (void)checkActivatedFlag
{
  BOOL activated = [self.adblockPlusDetails boolForKey:AdblockPlusActivated];
  if (self.activated != activated) {
    self.activated = activated;
  }
}

- (void)checkActivatedFlag:(NSDate *)lastActivity
{
  [self synchronize];
  BOOL activated = !!self.lastActivity && (!lastActivity || [self.lastActivity compare:lastActivity] == NSOrderedDescending);
  if (self.activated != activated) {
    self.activated = activated;
  }
}

- (void)performActivityTestWith:(id<ContentBlockerManagerProtocol>)manager
{  
  __weak __typeof(self) wSelf = self;
  NSDate *lastActivity = wSelf.lastActivity;
  wSelf.performingActivityTest = YES;
  [manager reloadWithIdentifier:self.contentBlockerIdentifier completionHandler:^(NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error) {
        NSLog(@"%@", error);
      }
      wSelf.performingActivityTest = NO;
      [wSelf checkActivatedFlag:lastActivity];
    });
  }];
}

- (BOOL)shouldRespondToActivityTest:(NSError **)error;
{
  self.activated = YES;
  self.lastActivity = [[NSDate alloc] init];

  if (self.performingActivityTest) {
    // Cancel the reloading. This will reduce time of execution of execution of content blocker
    // and therefore host application will be notified about result of testing ASAP.
    *error = [NSError errorWithDomain:AdblockPlusErrorDomain
                                 code:AdblockPlusErrorCodeActivityTest
                             userInfo:nil];
    return true;
  }

  *error = nil;
  return false;
}

@end
