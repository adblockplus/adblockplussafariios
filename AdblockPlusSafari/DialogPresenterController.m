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


#import "DialogPresenterController.h"

#import "RootController.h"

typedef NS_ENUM(NSUInteger, DialogControllerType) {
  DialogControllerTypeAcceptableAdsExplanation,
  DialogControllerTypeActivationHowtoVideo,
  DialogControllerTypeActivationWaiting,
  DialogControllerTypeActivationConfirmation
};

static NSString *FirstDialogControllerShown = @"FirstDialogControllerShown";
static NSString *FilterListsUpdated = @"FilterListsUpdated";

@interface DialogPresenterController () <DialogControllerProtocol>

@property (nonatomic) BOOL timeoutHasExpired;
@property (nonatomic) BOOL currentDialogLocked;
@property (nonatomic) DialogControllerType currentDialogControllerType;
@property (nonatomic, weak) UIViewController *currentViewController;

@end

@implementation DialogPresenterController

+ (BOOL)wasFirstDialogControllerShown
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  return [userDefaults boolForKey:FirstDialogControllerShown];
}

+ (BOOL)wasFilterListsUpdated
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  return [userDefaults boolForKey:FilterListsUpdated];
}

+ (BOOL)shouldShowWelcomeDialogController:(AdblockPlusExtras *)adblockPlus
{
  return !adblockPlus.activated || ![self wasFirstDialogControllerShown];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if (self = [super initWithCoder:aDecoder]) {
    _timeoutHasExpired = NO;
    _currentDialogLocked = NO;
    if (![[self class] wasFirstDialogControllerShown]) {
      self.currentDialogControllerType = DialogControllerTypeAcceptableAdsExplanation;
    } else {
      self.currentDialogControllerType = DialogControllerTypeActivationHowtoVideo;
    }
  }
  return self;
}

- (void)dealloc
{
  self.adblockPlus = nil;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self setViewControllerForType:self.currentDialogControllerType];
}

- (void)reload
{
  [self.adblockPlus updateActiveFilterLists:NO];
}

#pragma MARK: - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(activated))]
      || [keyPath isEqualToString:NSStringFromSelector(@selector(reloading))]
      || [keyPath isEqualToString:@"updating"]) {
    [self update];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setAdblockPlus:(AdblockPlusExtras *)adblockPlus
{
  NSArray<NSString *> *keyPaths =
  @[NSStringFromSelector(@selector(activated)),
    NSStringFromSelector(@selector(reloading)), @"updating"];

  for (NSString *keyPath in keyPaths) {
    [_adblockPlus removeObserver:self
                      forKeyPath:keyPath];
  }
  _adblockPlus = adblockPlus;
  for (NSString *keyPath in keyPaths) {
    [_adblockPlus addObserver:self
                   forKeyPath:keyPath
                      options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                      context:nil];
  }
}

#pragma mark - Interface

- (void)firstDialogControllerDidFinish:(UIViewController *)controller
{
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:FirstDialogControllerShown];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self update];
}

- (void)fourthDialogControllerDidFinish:(UIViewController *)controller
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)releaseDialogLocked
{
  self.currentDialogLocked = NO;
  [self update];
}

- (void)setDialogLock
{
  self.currentDialogLocked = YES;
  [self performSelector:@selector(releaseDialogLocked) withObject:nil afterDelay:4];
}

- (void)expireTimeout
{
  self.timeoutHasExpired = YES;
  [self update];
}

- (void)setTimeout
{
  [self performSelector:@selector(expireTimeout) withObject:nil afterDelay:10];
}

- (void)update
{
  if (self.currentDialogLocked) {
    return;
  }

  void(^tryPresentThirdDialog)() = ^() {
    if (self.adblockPlus.updating || self.adblockPlus.reloading) {
      if ([[self class] wasFilterListsUpdated]) {
        [self dismissViewControllerAnimated:YES completion:nil];
      } else {
        [self setDialogLock];
        [self setTimeout];
        self.currentDialogControllerType = DialogControllerTypeActivationWaiting;
      }
    } else if (!self.adblockPlus.updating) {
      if ([[self class] wasFilterListsUpdated]) {
        [self dismissViewControllerAnimated:YES completion:nil];
      } else {
        [self.adblockPlus updateActiveFilterLists:NO];
      }
    }
  };

  DialogControllerType oldValue = self.currentDialogControllerType;

  switch (self.currentDialogControllerType) {
    case DialogControllerTypeAcceptableAdsExplanation:
      if ([[self class] wasFirstDialogControllerShown]) {
        if (self.adblockPlus.activated) {
          tryPresentThirdDialog();
        } else {
          [self setDialogLock];
          self.currentDialogControllerType = DialogControllerTypeActivationHowtoVideo;
        }
      }
      break;
    case DialogControllerTypeActivationHowtoVideo:
      if (self.adblockPlus.activated) {
        tryPresentThirdDialog();
      }
      break;
    case DialogControllerTypeActivationWaiting:
      if (!(self.adblockPlus.updating || self.adblockPlus.reloading) || self.timeoutHasExpired) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:FilterListsUpdated];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.currentDialogControllerType = DialogControllerTypeActivationConfirmation;
      }
      break;
    case DialogControllerTypeActivationConfirmation:
      break;
  }

  if ([self isViewLoaded] && oldValue != self.currentDialogControllerType) {
    [self setViewControllerForType:self.currentDialogControllerType];
  }
}

- (UIViewController *)viewControllerFor:(DialogControllerType)type
{
  switch (type) {
    case DialogControllerTypeAcceptableAdsExplanation:
      return [self.storyboard instantiateViewControllerWithIdentifier:@"FirstDialogController"];
    case DialogControllerTypeActivationHowtoVideo:
      return [self.storyboard instantiateViewControllerWithIdentifier:@"SecondDialogController"];
    case DialogControllerTypeActivationWaiting:
      return [self.storyboard instantiateViewControllerWithIdentifier:@"ThirdDialogController"];
    case DialogControllerTypeActivationConfirmation:
      return [self.storyboard instantiateViewControllerWithIdentifier:@"FourthDialogController"];
  }
}

- (void)setViewControllerForType:(DialogControllerType)type
{
  UIViewController *viewController = [self viewControllerFor:type];
  if ([viewController respondsToSelector:@selector(setAdblockPlus:)]) {
    [(id)viewController setAdblockPlus:self.adblockPlus];
  }
  [self addChildViewController:viewController];

  if (self.currentViewController == nil) {
    viewController.view.bounds = self.view.bounds;
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
    self.currentViewController = viewController;
  } else if ([self.currentViewController class] != [viewController class]) {
    UIViewController *previousViewController = self.currentViewController;
    [previousViewController willMoveToParentViewController:nil];
    [self transitionFromViewController:previousViewController
                      toViewController:viewController
                              duration:0.5
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:nil
                            completion:^(BOOL finished) {
                              [viewController didMoveToParentViewController:self];
                              [previousViewController removeFromParentViewController];
                            }];
    self.currentViewController = viewController;
  } else {
    // Do Nothing
  }
}

@end
