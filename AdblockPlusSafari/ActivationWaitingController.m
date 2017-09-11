/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-present eyeo GmbH
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
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "ActivationWaitingController.h"

static const CGFloat ActivityIndicatorViewWidth = 44;

@interface ActivationWaitingController ()

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end

@implementation ActivationWaitingController

- (void)viewDidLoad
{
  [super viewDidLoad];
  CGFloat width = self.activityIndicatorView.bounds.size.width;
  self.activityIndicatorView.transform = CGAffineTransformMakeScale(ActivityIndicatorViewWidth / width, ActivityIndicatorViewWidth / width);
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.activityIndicatorView startAnimating];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self.activityIndicatorView stopAnimating];
}

@end
