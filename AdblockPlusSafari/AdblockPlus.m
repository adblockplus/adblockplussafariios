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

#import "AdblockPlus.h"

NSString *AdblockPlusErrorDomain = @"AdblockPlusError";
NSString *AdblockPlusActivated = @"AdblockPlusActivated";
static NSString *AdblockPlusEnabled = @"AdblockPlusEnabled";
static NSString *AdblockPlusAcceptableAdsEnabled = @"AdblockPlusAcceptableAdsEnabled";
static NSString *AdblockPlusFilterLists = @"AdblockPlusFilterLists";
static NSString *AdblockPlusInstalledVersion = @"AdblockPlusInstalledVersion";
static NSString *AdblockPlusDownloadedVersion = @"AdblockPlusDownloadedVersion";
static NSString *AdblockPlusWhitelistedWebsites = @"AdblockPlusWhitelistedWebsites";

static NSString *AdblockPlusSafariExtension = @"AdblockPlusSafariExtension";

@interface AdblockPlus ()

@property (nonatomic, strong) NSString *bundleName;

@end

@implementation AdblockPlus

- (instancetype)init
{
  if (self = [super init]) {

    NSString *path = [[NSBundle mainBundle] pathForResource:@"FilterLists" ofType:@"plist"];
    NSDictionary *filterLists = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!filterLists) {
      filterLists = @{};
    }

    // Try to extract group from bundle name from bundle id (in host app and extension):
    // org.adblockplus.AdblockPlusSafari           -> org.adblockplus
    // org.adblockplus.devbuilds.AdblockPlusSafari -> org.adblockplus.devbuilds
    NSArray<NSString *> *components = [[[NSBundle mainBundle] bundleIdentifier] componentsSeparatedByString:@"."];

    // Check, if the object is being created in the sharing extension.
    if ([components.lastObject isEqualToString:AdblockPlusSafariExtension]) {
      components = [components subarrayWithRange:NSMakeRange(0, [components count] - 2)];
    } else {
      components = [components subarrayWithRange:NSMakeRange(0, [components count] - 1)];
    }

    _bundleName = [components componentsJoinedByString:@"."];

    _adblockPlusDetails = [[NSUserDefaults alloc] initWithSuiteName:self.group];
    [_adblockPlusDetails registerDefaults:
     @{ AdblockPlusActivated: @NO,
        AdblockPlusEnabled: @YES,
        AdblockPlusAcceptableAdsEnabled: @YES,
        AdblockPlusInstalledVersion: @0,
        AdblockPlusDownloadedVersion: @1,
        AdblockPlusFilterLists: filterLists,
        AdblockPlusWhitelistedWebsites: @[]}];

    _enabled = [_adblockPlusDetails boolForKey:AdblockPlusEnabled];
    _acceptableAdsEnabled = [_adblockPlusDetails boolForKey:AdblockPlusAcceptableAdsEnabled];
    _activated = [_adblockPlusDetails boolForKey:AdblockPlusActivated];
    _filterLists = [_adblockPlusDetails objectForKey:AdblockPlusFilterLists];
    _installedVersion = [_adblockPlusDetails integerForKey:AdblockPlusInstalledVersion];
    _downloadedVersion = [_adblockPlusDetails integerForKey:AdblockPlusDownloadedVersion];
    _whitelistedWebsites = [_adblockPlusDetails objectForKey:AdblockPlusWhitelistedWebsites];
  }
  return self;
}

#pragma mark - Property

- (void)setEnabled:(BOOL)enabled
{
  _enabled = enabled;
  [_adblockPlusDetails setBool:enabled forKey:AdblockPlusEnabled];
  [_adblockPlusDetails synchronize];
}

- (void)setAcceptableAdsEnabled:(BOOL)acceptableAdsEnabled
{
  _acceptableAdsEnabled = acceptableAdsEnabled;
  [_adblockPlusDetails setBool:acceptableAdsEnabled forKey:AdblockPlusAcceptableAdsEnabled];
  [_adblockPlusDetails synchronize];
}

- (void)setActivated:(BOOL)activated
{
  _activated = activated;
  [_adblockPlusDetails setBool:activated forKey:AdblockPlusActivated];
  [_adblockPlusDetails synchronize];
}

- (void)setFilterLists:(NSDictionary<NSString *,NSDictionary<NSString *,NSObject *> *> *)filterLists
{
  _filterLists = filterLists;
  [_adblockPlusDetails setObject:filterLists forKey:AdblockPlusFilterLists];
  [_adblockPlusDetails synchronize];
}

- (void)setInstalledVersion:(NSInteger)installedVersion
{
  _installedVersion = installedVersion;
  [_adblockPlusDetails setInteger:installedVersion forKey:AdblockPlusInstalledVersion];
  [_adblockPlusDetails synchronize];
}

- (void)setDownloadedVersion:(NSInteger)downloadedVersion
{
  _downloadedVersion = downloadedVersion;
  [_adblockPlusDetails setInteger:downloadedVersion forKey:AdblockPlusDownloadedVersion];
  [_adblockPlusDetails synchronize];
}

- (void)setWhitelistedWebsites:(NSArray<NSString *> *)whitelistedWebsites
{
  _whitelistedWebsites = whitelistedWebsites;
  [_adblockPlusDetails setObject:whitelistedWebsites forKey:AdblockPlusWhitelistedWebsites];
  [_adblockPlusDetails synchronize];
}

#pragma mark -

- (NSString *)contentBlockerIdentifier
{
  return [NSString stringWithFormat:@"%@.AdblockPlusSafari.%@", _bundleName, AdblockPlusSafariExtension];
}

- (NSString *)group
{
  return [NSString stringWithFormat:@"group.%@.%@", _bundleName, @"AdblockPlusSafari"];
}

- (NSString *)backgroundSessionConfigurationIdentifier
{
  return [NSString stringWithFormat:@"%@.AdblockPlusSafari.BackgroundSession", _bundleName];
}

@end
