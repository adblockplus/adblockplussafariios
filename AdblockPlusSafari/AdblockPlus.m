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

#import "AdblockPlus.h"

@import libadblockplus_ios;
#import "NSDictionary+FilterList.h"

NSString *DefaultFilterListName = @"easylist";
NSString *DefaultFilterListPlusExceptionRulesName = @"easylist+exceptionrules";
NSString *CustomFilterListName = @"customFilterList";

NSString *AdblockPlusErrorDomain = @"AdblockPlusError";
NSString *AdblockPlusActivated = @"AdblockPlusActivated";
static NSString *AdblockPlusEnabled = @"AdblockPlusEnabled";
static NSString *AdblockPlusAcceptableAdsEnabled = @"AdblockPlusAcceptableAdsEnabled";
static NSString *AdblockPlusDefaultFilterListEnabled = @"AdblockPlusDefaultFilterListEnabled";
static NSString *AdblockPlusFilterLists = @"AdblockPlusFilterLists";
static NSString *AdblockPlusFilterListsVersion2 = @"AdblockPlusFilterListsVersion2";
static NSString *AdblockPlusInstalledVersion = @"AdblockPlusInstalledVersion";
static NSString *AdblockPlusDownloadedVersion = @"AdblockPlusDownloadedVersion";
static NSString *AdblockPlusWhitelistedWebsites = @"AdblockPlusWhitelistedWebsites";
static NSString *AdblockPlusLastActivity = @"AdblockPlusLastActivity";
static NSString *AdblockPlusPerformingActivityTest = @"AdblockPlusPerformingActivityTest";

/// Duplicated in libadblockplus-ios.
static NSString *AdblockPlusSafariExtension = @"AdblockPlusSafariExtension";

/// Duplicated in libadblockplus-ios.
static NSString *AdblockPlusSafariActionExtension = @"AdblockPlusSafariActionExtension";

@interface AdblockPlus ()

@property (nonatomic, strong) NSString *bundleName;

@end

@implementation AdblockPlus

- (instancetype)init
{
    if (self = [super init]) {

        // Try to extract group from bundle name from bundle id (in host app and extension):
        // org.adblockplus.AdblockPlusSafari           -> org.adblockplus
        // org.adblockplus.devbuilds.AdblockPlusSafari -> org.adblockplus.devbuilds
        NSArray<NSString *> *components = [[[NSBundle mainBundle] bundleIdentifier] componentsSeparatedByString:@"."];

        // Check, if the object is being created in the sharing or action extension.
        if ([components.lastObject isEqualToString:AdblockPlusSafariExtension]
            || [components.lastObject isEqualToString:AdblockPlusSafariActionExtension]) {
            components = [components subarrayWithRange:NSMakeRange(0, [components count] - 2)];
        } else {
            components = [components subarrayWithRange:NSMakeRange(0, [components count] - 1)];
        }

        _bundleName = [components componentsJoinedByString:@"."];

        /// Above code duplicated in libadblockplus-ios.

        _adblockPlusDetails = [[NSUserDefaults alloc] initWithSuiteName:[[AppExtensionRelay sharedInstance] legacyGroup]];
        [_adblockPlusDetails registerDefaults:
                                 @{ AdblockPlusEnabled : @YES,
                                     AdblockPlusAcceptableAdsEnabled : @YES,
                                     AdblockPlusActivated : @NO,
                                     AdblockPlusDefaultFilterListEnabled : @YES,
                                     AdblockPlusInstalledVersion : @0,
                                     AdblockPlusDownloadedVersion : @1,
                                     AdblockPlusWhitelistedWebsites : @[] }];

        _enabled = [_adblockPlusDetails boolForKey:AdblockPlusEnabled];
        _acceptableAdsEnabled = [_adblockPlusDetails boolForKey:AdblockPlusAcceptableAdsEnabled];
        _activated = [_adblockPlusDetails boolForKey:AdblockPlusActivated];
        _defaultFilterListEnabled = [_adblockPlusDetails boolForKey:AdblockPlusDefaultFilterListEnabled];
        _filterLists = [_adblockPlusDetails objectForKey:AdblockPlusFilterListsVersion2];
        _installedVersion = [_adblockPlusDetails integerForKey:AdblockPlusInstalledVersion];
        _downloadedVersion = [_adblockPlusDetails integerForKey:AdblockPlusDownloadedVersion];
        _whitelistedWebsites = [_adblockPlusDetails objectForKey:AdblockPlusWhitelistedWebsites];
        _lastActivity = [_adblockPlusDetails objectForKey:AdblockPlusLastActivity];
        _performingActivityTest = [_adblockPlusDetails boolForKey:AdblockPlusPerformingActivityTest];

        if (!_filterLists) {
            // Load default filter lists
            NSString *path = [[NSBundle mainBundle] pathForResource:@"FilterLists" ofType:@"plist"];
            _filterLists = [NSDictionary dictionaryWithContentsOfFile:path];
            if (!_filterLists) {
                _filterLists = @{};
            }

            // If no filter lists of version 1 is stored in user defaults,
            // then default filter lists are used

            NSDictionary *filterListsVersion1 = [_adblockPlusDetails objectForKey:AdblockPlusFilterLists];
            if (filterListsVersion1) {
                // Old version of filter lists was loaded, convert old version to new version

                NSDictionary *defaultFilterListsFileNames =
                    @{ DefaultFilterListName :
                            @"easylist_content_blocker.json",
                        DefaultFilterListPlusExceptionRulesName :
                            @"easylist+exceptionrules_content_blocker.json"
                    };
                NSMutableDictionary *filterListsVersion2 = [_filterLists mutableCopy];

                for (NSString *defaultFilterListName in defaultFilterListsFileNames) {
                    NSString *defaultFilterListFileName = defaultFilterListsFileNames[defaultFilterListName];
                    for (NSString *filterListUrl in filterListsVersion1) {
                        NSDictionary *filterList = filterListsVersion1[filterListUrl];
                        if ([filterList[@"filename"] isEqualToString:defaultFilterListFileName]) {
                            NSMutableDictionary *modifiedFilterList = [filterList mutableCopy];
                            modifiedFilterList[@"url"] = filterListUrl;
                            modifiedFilterList[@"fileName"] = defaultFilterListFileName;
                            [modifiedFilterList removeObjectForKey:@"filename"];

                            filterListsVersion2[defaultFilterListName] = modifiedFilterList;
                        }
                    }
                }

                _filterLists = filterListsVersion2;
            }
        }

        NSAssert(_filterLists[DefaultFilterListName], @"Default filter list is not set");
        NSAssert(_filterLists[DefaultFilterListPlusExceptionRulesName], @"Default filter list with exceptions is not set");
    }
    return self;
}

#pragma mark - Property

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    [[AppExtensionRelay sharedInstance] legacyEnabledSet:enabled];
    [_adblockPlusDetails setBool:enabled forKey:AdblockPlusEnabled];
    [_adblockPlusDetails synchronize];
}

- (void)setAcceptableAdsEnabled:(BOOL)acceptableAdsEnabled
{
    _acceptableAdsEnabled = acceptableAdsEnabled;
    [[AppExtensionRelay sharedInstance] legacyAcceptableAdsEnabledSet:acceptableAdsEnabled];
    [_adblockPlusDetails setBool:acceptableAdsEnabled forKey:AdblockPlusAcceptableAdsEnabled];
    [_adblockPlusDetails synchronize];
}

- (void)setActivated:(BOOL)activated
{
    _activated = activated;
    [_adblockPlusDetails setBool:activated forKey:AdblockPlusActivated];
    [_adblockPlusDetails synchronize];
}

- (void)setDefaultFilterListEnabled:(BOOL)defaultFilterListEnabled
{
    _defaultFilterListEnabled = defaultFilterListEnabled;
    [[AppExtensionRelay sharedInstance] legacyDefaultFilterListEnabledSet:defaultFilterListEnabled];
    [_adblockPlusDetails setBool:defaultFilterListEnabled forKey:AdblockPlusDefaultFilterListEnabled];
    [_adblockPlusDetails synchronize];
}

- (void)setLastActivity:(NSDate *)lastActivity
{
    _lastActivity = lastActivity;
    [[AppExtensionRelay sharedInstance] legacyLastActivitySet:lastActivity];
    [_adblockPlusDetails setObject:lastActivity forKey:AdblockPlusLastActivity];
    [_adblockPlusDetails synchronize];
}

/// Called from AdblockPlusExtras when updating filter lists.
- (void)setFilterLists:(NSDictionary<NSString *, NSDictionary<NSString *, NSObject *> *> *)filterLists
{
    _filterLists = filterLists;
    [[AppExtensionRelay sharedInstance] legacyFilterListsSet:filterLists];
    [_adblockPlusDetails setObject:filterLists forKey:AdblockPlusFilterListsVersion2];
    [_adblockPlusDetails synchronize];
}

- (void)setInstalledVersion:(NSInteger)installedVersion
{
    _installedVersion = installedVersion;
    [[AppExtensionRelay sharedInstance] legacyInstalledVersionSet:installedVersion];
    [_adblockPlusDetails setInteger:installedVersion forKey:AdblockPlusInstalledVersion];
    [_adblockPlusDetails synchronize];
}

- (void)setDownloadedVersion:(NSInteger)downloadedVersion
{
    _downloadedVersion = downloadedVersion;
    [[AppExtensionRelay sharedInstance] legacyDownloadedVersionSet:downloadedVersion];
    [_adblockPlusDetails setInteger:downloadedVersion forKey:AdblockPlusDownloadedVersion];
    [_adblockPlusDetails synchronize];
}

- (void)setWhitelistedWebsites:(NSArray<NSString *> *)whitelistedWebsites
{
    _whitelistedWebsites = whitelistedWebsites;
    [[AppExtensionRelay sharedInstance] legacyWhitelistedWebsitesSet:whitelistedWebsites];
    [_adblockPlusDetails setObject:whitelistedWebsites forKey:AdblockPlusWhitelistedWebsites];
    [_adblockPlusDetails synchronize];
}

- (void)setPerformingActivityTest:(BOOL)performingActivityTest
{
    _performingActivityTest = performingActivityTest;
    [_adblockPlusDetails setBool:performingActivityTest forKey:AdblockPlusPerformingActivityTest];
    [_adblockPlusDetails synchronize];
}

#pragma mark -

- (NSString *)backgroundSessionConfigurationIdentifier
{
    return [NSString stringWithFormat:@"%@.AdblockPlusSafari.BackgroundSession", _bundleName];
}

- (NSString *__nonnull)activeFilterListName
{
    if (!self.defaultFilterListEnabled && [self.filterLists[CustomFilterListName] downloaded]) {
        return CustomFilterListName;
    }
    if (self.acceptableAdsEnabled) {
        return DefaultFilterListPlusExceptionRulesName;
    }
    return DefaultFilterListName;
}

- (void)synchronize
{
    [self.adblockPlusDetails synchronize];
    [self willChangeValueForKey:@"lastActivity"];
    _lastActivity = [self.adblockPlusDetails objectForKey:AdblockPlusLastActivity];
    [self didChangeValueForKey:@"lastActivity"];
}

@end
