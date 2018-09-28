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

@import libadblockplus_ios;

@implementation AdblockPlus (ActivityChecking)

/// Update the activated flag with the stored value.
- (void)checkActivatedFlag
{
    BOOL activated = [self.adblockPlusDetails boolForKey:AdblockPlusActivated];
    if (self.activated != activated) {
        self.activated = activated;
    }
}

/// Determines if the content blocker is enabled. This will be removed when
/// the minimum deployment SDK is >= 10.
///
/// Set the activated flag to TRUE if content blocking is enabled as determined
/// by the logic below.
- (void)checkActivatedFlag:(NSDate *__nullable)lastActivity
{
    [self synchronize];
    BOOL activated = FALSE;
    if (self.lastActivity != nil) {
        if (lastActivity != nil) {
            if ([self.lastActivity compare:lastActivity] == NSOrderedDescending) {
                activated = TRUE;
            }
        } else {
            activated = TRUE;
        }
    }
    if (self.activated != activated) {
        self.activated = activated;
    }
}

/// Initiates a test that ends up setting the internal activated state for the
/// content blocker. This is currently used when the app enters the
/// foreground.
- (void)performActivityTestWith:(id<ContentBlockerManagerProtocol>)manager
{
    __weak __typeof(self) wSelf = self;
    NSDate *lastActivity = wSelf.lastActivity;
    wSelf.performingActivityTest = YES;
    [manager reloadWithIdentifier:[[AppExtensionRelay sharedInstance] legacyContentBlockerIdentifier]
                completionHandler:^(NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
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
        if (error != NULL) {
            *error = [NSError errorWithDomain:AdblockPlusErrorDomain
                                         code:AdblockPlusErrorCodeActivityTest
                                     userInfo:nil];
        }
        return true;
    }
    if (error != NULL) {
        *error = nil;
    }
    return false;
}

@end
