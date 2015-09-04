//
//  AdblockPlus.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 02/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

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
  [SFContentBlockerManager reloadContentBlockerWithIdentifier:self.contentBlockerIdentifier completionHandler:^(NSError *error) {
    NSLog(@"%@", error);
    [wSelf checkActivatedFlag];
    if (completion) {
      completion(error);
    }
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
