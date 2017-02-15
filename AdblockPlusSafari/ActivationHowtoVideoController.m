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


#import "ActivationHowtoVideoController.h"

#import "Appearence.h"
#import "NSAttributedString+TextRenderer.h"

@import AVKit;
@import AVFoundation;

@interface ActivationHowtoVideoController ()

@property (nonatomic, weak) IBOutlet UILabel *firstStepLabel;
@property (nonatomic, weak) IBOutlet UILabel *secondStepLabel;

@end

@implementation ActivationHowtoVideoController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if (self = [super initWithCoder:aDecoder]) {
    // Subscribe to the AVPlayerItem's DidPlayToEndTime notification.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPlayerItemDidPlayToEndTimeNotification:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  CGFloat fontSize = self.firstStepLabel.font.pointSize;
  UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
  
  self.firstStepLabel.fontFamilyName = @".SFUIText";
  self.firstStepLabel.attributedText = [self.firstStepLabel.attributedText renderSpanMarkedByChar:@"*"
                                                                                           asFont:font];
  
  self.secondStepLabel.fontFamilyName = @".SFUIText";
  self.secondStepLabel.attributedText = [self.secondStepLabel.attributedText renderSpanMarkedByChar:@"*"
                                                                                           asFont:font];
}

#pragma mark - Actions

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
