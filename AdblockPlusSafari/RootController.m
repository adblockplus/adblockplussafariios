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

#import "WelcomeController.h"

@interface RootController ()

@end

@implementation RootController

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.

  if (![[NSUserDefaults standardUserDefaults] boolForKey:WelcomeControllerHasBeenSeen]) {
    UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WelcomeController"];
    [self setViewControllers:@[controller] animated:false];
  }

  if ([self.topViewController respondsToSelector:@selector(setAdblockPlus:)]) {
    [(id)self.topViewController setAdblockPlus:self.adblockPlus];
  }
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated
{
  if ([viewControllers.firstObject respondsToSelector:@selector(setAdblockPlus:)]) {
    [(id)viewControllers.firstObject setAdblockPlus:self.adblockPlus];
  }
  [super setViewControllers:viewControllers animated:animated];
}

@end
