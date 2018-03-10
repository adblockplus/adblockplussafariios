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

#import <Foundation/Foundation.h>

extern NSString *_Nonnull DefaultFilterListName;
extern NSString *_Nonnull DefaultFilterListPlusExceptionRulesName;
extern NSString *_Nonnull CustomFilterListName;

extern NSString *_Nonnull AdblockPlusErrorDomain;
extern NSString *_Nonnull AdblockPlusActivated;

typedef NS_ENUM(NSUInteger, AdblockPlusFilterListType) {
    AdblockPlusFilterListTypeVersion1,
    AdblockPlusFilterListTypeVersion2
};

typedef NS_ENUM(NSUInteger, AdblockPlusErrorCode) {
    AdblockPlusErrorCodeActivityTest = 10
};

@interface AdblockPlus : NSObject

@property (nonatomic, strong, readonly) NSString *__nonnull bundleName;

@property (nonatomic, strong, readonly) NSUserDefaults *__nonnull adblockPlusDetails;

- (NSString *__nonnull)group;

- (NSString *__nonnull)backgroundSessionConfigurationIdentifier;

- (NSString *__nonnull)contentBlockerIdentifier;

@property (nonatomic) BOOL enabled;

@property (nonatomic) BOOL acceptableAdsEnabled;

@property (nonatomic) BOOL activated;

@property (nonatomic) BOOL defaultFilterListEnabled;

@property (nonatomic) NSDate *__nullable lastActivity;

@property (nonatomic) NSInteger installedVersion;

@property (nonatomic) NSInteger downloadedVersion;

/// This property should never be used to access the current filter list data from the Swift side
/// as it is not guaranteed to be synchronized with the saved data.
@property (nonatomic, strong) NSDictionary<NSString *, NSDictionary<NSString *, id> *> *__nonnull filterLists;

@property (nonatomic, strong) NSArray<NSString *> *__nonnull whitelistedWebsites;

- (NSString *__nonnull)activeFilterListName;

@property (nonatomic) BOOL performingActivityTest;

- (void)synchronize;

@end
