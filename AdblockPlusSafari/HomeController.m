//
//  HomeController.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 02/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "HomeController.h"

@import AVKit;
@import AVFoundation;

@interface HomeController ()

@end

@implementation HomeController

- (void)dealloc
{
  self.adblockPlus = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  [super viewWillAppear:animated];
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
  [self.navigationController presentViewController:playerViewController animated:true completion:nil];
}

@end
