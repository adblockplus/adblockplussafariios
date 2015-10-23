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

#import "HomeController.h"

@import AVKit;
@import AVFoundation;

@interface HomeController ()

@end

@implementation HomeController

- (void)dealloc
{
  self.adblockPlus = nil;

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Subscribe to the AVPlayerItem's DidPlayToEndTime notification.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onPlayerItemDidPlayToEndTimeNotification:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.adblockPlus displayErrorDialogIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated
{
  if (self.navigationController.topViewController != self) {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
  }
  [super viewWillDisappear:animated];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.destinationViewController respondsToSelector:@selector(setAdblockPlus:)]) {
    [(id)segue.destinationViewController setAdblockPlus:self.adblockPlus];
  }
}

#pragma mark - Action

- (IBAction)onVideoButtonTouched:(id)sender
{
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"screencast" withExtension:@"mp4"];
  AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
  playerViewController.player = [[AVPlayer alloc] initWithURL:url];
  [playerViewController.player play];
  playerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [self.navigationController presentViewController:playerViewController animated:YES completion:nil];
}

#pragma mark - private

- (void)onPlayerItemDidPlayToEndTimeNotification:(NSNotification *)notification
{
  if ([self.navigationController.presentedViewController isKindOfClass:[AVPlayerViewController class]]) {
    AVPlayerViewController *playerViewController = (AVPlayerViewController *)self.navigationController.presentedViewController;

    if ([notification.object isKindOfClass:[AVPlayerItem class]]) {
      AVPlayerItem *item = (AVPlayerItem *)notification.object;

      if (playerViewController.player.currentItem == item) {
        [playerViewController dismissViewControllerAnimated:YES completion:nil];
      }
    }
  }
}

@end
