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
