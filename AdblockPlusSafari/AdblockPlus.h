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

#import <Foundation/Foundation.h>

extern NSString *_Nonnull AdblockPlusErrorDomain;
extern NSString *_Nonnull AdblockPlusActivated;

typedef NS_ENUM(NSUInteger, AdblockPlusErrorCode) {
  AdblockPlusErrorCodeActivityTest = 10
};

@interface AdblockPlus : NSObject

@property (nonatomic, strong, readonly) NSUserDefaults *__nonnull adblockPlusDetails;

- (NSString *__nonnull)group;

- (NSString *__nonnull)contentBlockerIdentifier;

- (NSString *__nonnull)backgroundSessionConfigurationIdentifier;

@property (nonatomic) BOOL enabled;

@property (nonatomic) BOOL acceptableAdsEnabled;

@property (nonatomic) BOOL activated;

@property (nonatomic) NSDate *__nullable lastActivity;

@property (nonatomic) NSInteger installedVersion;

@property (nonatomic) NSInteger downloadedVersion;

@property (nonatomic, strong) NSDictionary<NSString *, NSDictionary<NSString *, id> *> *__nonnull filterLists;

@property (nonatomic, strong) NSArray<NSString *> *__nonnull whitelistedWebsites;

@property (nonatomic) BOOL performingActivityTest;

- (void)synchronize;

@end
