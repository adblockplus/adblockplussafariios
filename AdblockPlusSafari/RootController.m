//
//  RootController.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 03/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

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
