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

#import "AdblockPlusShared.h"

@implementation AdblockPlusShared

#pragma mark - BackgroundNotificationSession

- (NSString *)backgroundNotificationSessionConfigurationPrefix
{
    return [NSString stringWithFormat:@"%@.AdblockPlusSafari.NotificationSession.", self.bundleName];
}

- (NSString *)generateBackgroundNotificationSessionConfigurationIdentifier
{
    NSString *UUID = [[NSUUID UUID] UUIDString];
    return [self.backgroundNotificationSessionConfigurationPrefix stringByAppendingString:UUID];
}

- (BOOL)isBackgroundNotificationSessionConfigurationIdentifier:(NSString *__nonnull)identifier
{
    return [identifier hasPrefix:self.backgroundNotificationSessionConfigurationPrefix];
}

- (NSURLSession *)backgroundNotificationSessionWithIdentifier:(NSString *)identifier
                                                     delegate:(id<NSURLSessionDelegate>)delegate
{
    NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    configuration.timeoutIntervalForRequest = 2;
    configuration.timeoutIntervalForResource = 2;
    configuration.sharedContainerIdentifier = self.group;
    if (delegate) {
        return [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:nil];
    } else {
        return [NSURLSession sessionWithConfiguration:configuration];
    }
}

@end
