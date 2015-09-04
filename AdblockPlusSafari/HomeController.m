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

@property (nonatomic, weak) IBOutlet UIButton *activatedButton;

@end

@implementation HomeController

- (void)dealloc
{
  self.adblockPlus = nil;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.activatedButton.selected = self.adblockPlus.activated;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(activated))]) {
    [self loadViewIfNeeded];
    self.activatedButton.selected = self.adblockPlus.activated;
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setAdblockPlus:(AdblockPlus *)adblockPlus
{
  NSString *keyPath = NSStringFromSelector(@selector(activated));
  [_adblockPlus removeObserver:self forKeyPath:keyPath];
  _adblockPlus = adblockPlus;
  [_adblockPlus addObserver:self
                 forKeyPath:keyPath
                    options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                    context:nil];
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
