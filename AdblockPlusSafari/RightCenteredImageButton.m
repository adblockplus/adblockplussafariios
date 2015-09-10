//
//  RightCenteredImageButton.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 03/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "RightCenteredImageButton.h"

const CGFloat ImageRightMargin = 25;

@interface RightCenteredImageButton ()

@end

@implementation RightCenteredImageButton

- (void)layoutSubviews
{
  [super layoutSubviews];
  CGFloat x = self.frame.size.width - ImageRightMargin - self.imageView.frame.size.width / 2;
  CGFloat y = self.frame.size.height / 2;
  self.imageView.center = CGPointMake(x, y);
}

@end
