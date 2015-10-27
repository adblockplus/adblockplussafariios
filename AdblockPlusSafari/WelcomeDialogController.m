//
//  WelcomeDialogController.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 21/10/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "WelcomeDialogController.h"

#import "RootController.h"

@import AVKit;
@import AVFoundation;

static NSString *WelcomeDialogControllerShown = @"WelcomeDialogControllerShown";

@interface WelcomeDialogController () <DialogControllerProtocol>

@property (nonatomic, weak) IBOutlet UIView *firstDialogView;
@property (nonatomic, weak) IBOutlet UIView *secondDialogView;

@end

@implementation WelcomeDialogController

+ (BOOL)shouldShowWelcomeDialogController:(AdblockPlusExtras *)adblockPlus
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  return !adblockPlus.activated || ![userDefaults boolForKey:WelcomeDialogControllerShown];
}

- (void)dealloc
{
  self.adblockPlus = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.

  // Subscribe to the AVPlayerItem's DidPlayToEndTime notification.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onPlayerItemDidPlayToEndTimeNotification:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:nil];

  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  BOOL shown = [userDefaults boolForKey:WelcomeDialogControllerShown];
  self.firstDialogView.hidden = shown;
  self.secondDialogView.hidden = !shown;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(activated))]) {
    BOOL activated = [change[NSKeyValueChangeNewKey] boolValue];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (activated && [userDefaults boolForKey:WelcomeDialogControllerShown]) {
      [self dismissViewController];
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setAdblockPlus:(AdblockPlusExtras *)adblockPlus
{
  NSArray<NSString *> *keyPaths = @[NSStringFromSelector(@selector(activated))];

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

#pragma mark - Action

- (IBAction)onStartAdblockPlusButtonTouched:(id)sender
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setBool:YES forKey:WelcomeDialogControllerShown];

  if (self.adblockPlus.activated) {
    [self dismissViewController];
  } else {
    [UIView transitionFromView:self.firstDialogView
                        toView:self.secondDialogView
                      duration:0.6
                       options:UIViewAnimationOptionShowHideTransitionViews|UIViewAnimationOptionTransitionCrossDissolve
                    completion:nil];
  }
}

- (IBAction)onOpenSettingsButtonTouched:(id)sender
{
  // How to open settings page:
  // http://stackoverflow.com/questions/8246070/ios-launching-settings-restrictions-url-scheme?rq=1
  // Shortcut for Safari setting page is not working.
  if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root="]]) {
    // This command is used as fallback, it will open local setting page of the application.
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
  }
}

- (IBAction)onVideoButtonTouched:(id)sender
{
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"screencast" withExtension:@"mp4"];
  AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
  playerViewController.player = [[AVPlayer alloc] initWithURL:url];
  [playerViewController.player play];
  playerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [self presentViewController:playerViewController animated:YES completion:nil];
}

#pragma mark - Private

- (void)dismissViewController
{
  [self dismissViewControllerAnimated:YES completion:^{
    UIViewController *viewController = UIApplication.sharedApplication.delegate.window.rootViewController;
    if ([viewController isKindOfClass:[RootController class]]) {
      [((RootController *)viewController) showDialogIfNeeded];
    }
  }];
}

- (void)onPlayerItemDidPlayToEndTimeNotification:(NSNotification *)notification
{
  if ([self.presentedViewController isKindOfClass:[AVPlayerViewController class]]) {
    AVPlayerViewController *playerViewController = (AVPlayerViewController *)self.presentedViewController;

    if ([notification.object isKindOfClass:[AVPlayerItem class]]) {
      AVPlayerItem *item = (AVPlayerItem *)notification.object;

      if (playerViewController.player.currentItem == item) {
        [playerViewController dismissViewControllerAnimated:YES completion:nil];
      }
    }
  }
}

@end
