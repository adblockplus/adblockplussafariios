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

@import SafariServices;

static NSString *AdblockPlusActivated = @"AdblockPlusActivated";
static NSString *AdblockPlusEnabled = @"AdblockPlusEnabled";
static NSString *AdblockPlusAcceptableAdsEnabled = @"AdblockPlusAcceptableAdsEnabled";

@interface AdblockPlus ()

@property (nonatomic, strong) NSUserDefaults *adblockPlusDetails;
@property (nonatomic, strong) NSString *bundleName;

@end

@implementation AdblockPlus

- (instancetype)init
{
  if (self = [super init]) {
    _bundleName = [[[[[NSBundle mainBundle] bundleIdentifier] componentsSeparatedByString:@"."] subarrayWithRange:NSMakeRange(0, 2)] componentsJoinedByString:@"."];
    NSString *group = [NSString stringWithFormat:@"group.%@.%@", _bundleName, @"AdblockPlusSafari"];
    _adblockPlusDetails = [[NSUserDefaults alloc] initWithSuiteName:group];
    [_adblockPlusDetails registerDefaults:
     @{ AdblockPlusActivated: @NO,
        AdblockPlusEnabled: @YES,
        AdblockPlusAcceptableAdsEnabled: @YES}];

    _enabled = [_adblockPlusDetails boolForKey:AdblockPlusEnabled];
    _acceptableAdsEnabled = [_adblockPlusDetails boolForKey:AdblockPlusAcceptableAdsEnabled];
    _activated = [_adblockPlusDetails boolForKey:AdblockPlusActivated];
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

#pragma mark -

- (NSString *)contentBlockerIdentifier
{
    return [NSString stringWithFormat:@"%@.AdblockPlusSafari.AdblockPlusSafariExtension", _bundleName];
}

- (void)setEnabled:(BOOL)enabled reload:(BOOL)reload
{
  self.enabled = enabled;

  if (reload) {
    [self reloadContentBlockerWithCompletion:nil];
  }
}

- (void)setAcceptableAdsEnabled:(BOOL)enabled reload:(BOOL)reload
{
  self.acceptableAdsEnabled = enabled;

  if (reload) {
    [self reloadContentBlockerWithCompletion:nil];
  }
}

- (void)reloadContentBlockerWithCompletion:(void(^__nullable)(NSError * __nullable error))completion;
{
  __weak __typeof(self) wSelf = self;
  wSelf.reloading = YES;
  [SFContentBlockerManager reloadContentBlockerWithIdentifier:self.contentBlockerIdentifier completionHandler:^(NSError *error) {
    NSLog(@"%@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
      wSelf.reloading = NO;
      [wSelf checkActivatedFlag];
      if (completion) {
        completion(error);
      }
    });
  }];
}

- (void)checkActivatedFlag
{
  BOOL activated = [_adblockPlusDetails boolForKey:AdblockPlusActivated];
  if (self.activated != activated) {
    self.activated = activated;
  }
}

@end
