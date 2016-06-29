/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-2016 Eyeo GmbH
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

#import "WelcomeController.h"

NSString *WelcomeControllerHasBeenSeen = @"WelcomeControllerHasBeenSeen";

@interface WelcomeController () <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *button1;
@property (nonatomic, weak) IBOutlet UIButton *button2;
@property (nonatomic, weak) IBOutlet UIImageView *indicator1;
@property (nonatomic, weak) IBOutlet UIImageView *indicator2;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@end

@implementation WelcomeController
{
  UIImage *_activeImage;
  UIImage *_inactiveImage;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
    // Do any additional setup after loading the view.

  _activeImage = [UIImage imageNamed:@"pageindicator_active"];
  _inactiveImage = [UIImage imageNamed:@"pageindicator_inactive"];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  [super viewWillAppear:animated];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  CGFloat progress = scrollView.contentOffset.x / scrollView.contentSize.width * 2;
  progress = MAX(0, MIN(1, progress));
  self.button1.alpha = 1.0 - progress;
  self.button2.alpha = progress;

  self.indicator1.image = progress < 0.5 ? _activeImage : _inactiveImage;
  self.indicator2.image = progress < 0.5 ? _inactiveImage : _activeImage;
}

#pragma mark - Action

- (IBAction)onButton1Touch:(id)sender
{
  CGPoint point = CGPointMake(self.scrollView.contentSize.width / 2, 0);
  [self.scrollView setContentOffset:point animated:true];
}

- (IBAction)onButton2Touch:(id)sender
{
  UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"HomeController"];
  [UIView transitionWithView:self.navigationController.view
                    duration:0.5
                     options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromLeft
                  animations:^{
                    [self.navigationController setViewControllers:@[controller] animated:false];
                  }
                  completion:nil];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:true forKey:WelcomeControllerHasBeenSeen];
  [defaults synchronize];
}

@end
