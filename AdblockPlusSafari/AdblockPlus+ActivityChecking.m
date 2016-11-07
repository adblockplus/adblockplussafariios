//
//  AdblockPlus+ActivityChecking.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 03/11/16.
//  Copyright © 2016 Eyeo GmbH. All rights reserved.
//

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
