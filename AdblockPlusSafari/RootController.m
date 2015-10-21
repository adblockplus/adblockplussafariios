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

#import "RootController.h"

#import "WelcomeDialogController.h"

@interface RootController (AdblockPlus) <DialogControllerProtocol>
@end

@implementation RootController (AdblockPlus)
@end



@interface RootController ()
@end

@implementation RootController {
  BOOL _readyToShowDialog;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
  if (self = [super initWithCoder:coder]) {
    _readyToShowDialog = NO;
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

  if ([self.topViewController respondsToSelector:@selector(setAdblockPlus:)]) {
    [(id)self.topViewController setAdblockPlus:self.adblockPlus];
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  _readyToShowDialog = YES;
  [self showDialogIfNeeded];
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated
{
  if ([viewControllers.firstObject respondsToSelector:@selector(setAdblockPlus:)]) {
    [(id)viewControllers.firstObject setAdblockPlus:self.adblockPlus];
  }
  [super setViewControllers:viewControllers animated:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(activated))]
      || [keyPath isEqualToString:NSStringFromSelector(@selector(needsDisplayErrorDialog))]) {
    if (_readyToShowDialog) {
      [self showDialogIfNeeded];
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setAdblockPlus:(AdblockPlusExtras *)adblockPlus
{
  NSArray<NSString *> *keyPaths = @[NSStringFromSelector(@selector(activated)),
                                    NSStringFromSelector(@selector(needsDisplayErrorDialog))];

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

#pragma mark - Private

- (void)showDialogIfNeeded
{
  if ([WelcomeDialogController shouldShowWelcomeDialogController:self.adblockPlus]) {
    [self showWelcomeDialogIfNeeded];
    return;
  }

  [self showErrorDialogIfNeeded];
}

- (void)showWelcomeDialogIfNeeded
{
  UIViewController *presenter = self;

  while (presenter.presentedViewController) {
    presenter = presenter.presentedViewController;
    if ([presenter isKindOfClass:[WelcomeDialogController class]]) {
      return;
    }
  }

  WelcomeDialogController *controller = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([WelcomeDialogController class])];
  controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
  controller.adblockPlus = self.adblockPlus;
  [presenter presentViewController:controller animated:YES completion:nil];
}

- (void)showErrorDialogIfNeeded
{
  if (!self.adblockPlus.needsDisplayErrorDialog) {
    return;
  }

  if ([[self.adblockPlus.filterLists.allValues valueForKeyPath:@"@sum.userTriggered"] integerValue] == 0) {
    return;
  }

  UIViewController *viewController = UIApplication.sharedApplication.delegate.window.rootViewController;

  while (viewController.presentedViewController) {
    viewController = viewController.presentedViewController;
    if ([viewController conformsToProtocol:@protocol(DialogControllerProtocol) ]) {
      return;
    }
  }

  NSString *title = @"​Filter lists Updating​";
  NSString *message = @"Automatic updating failed. Please try updating manually.";

  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
  alertController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [viewController presentViewController:alertController animated:YES completion:nil];

  self.adblockPlus.needsDisplayErrorDialog = NO;
}

@end
