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

#import "WhitelistedSiteCell.h"

const CGFloat imageOffset = 20;

@implementation WhitelistedSiteCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.deleteButton.bounds = CGRectMake(0, 0, 50, 44);
  self.deleteButton.tintColor = UIColor.blackColor;
  [self.deleteButton setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
  [self.deleteButton addTarget:self
                        action:@selector(onDeleteButtonTouched:)
              forControlEvents:UIControlEventTouchUpInside];
  self.accessoryView = self.deleteButton;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  CGFloat width = [self.deleteButton imageForState:UIControlStateNormal].size.width / 2;
  CGPoint center = [self convertPoint:self.deleteButton.center toView:self];

  CGFloat offset;
  if ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft) {
    offset = imageOffset + width;
  } else {
    offset = self.frame.size.width - imageOffset - width;
  }
  self.deleteButton.center = CGPointMake(offset, center.y);
}

#pragma mark - Actions

- (void)onDeleteButtonTouched:(UIButton *)sender
{
  UIView *view = self.superview;
  while (view) {
    if ([view isKindOfClass:[UITableView class]]) {
      UITableView *tableView = (UITableView *)view;
      NSIndexPath *indexPath = [tableView indexPathForCell:self];
      if (indexPath && [tableView.delegate conformsToProtocol:@protocol(WhitelistingDelegate)]) {
        [((id<WhitelistingDelegate>)tableView.delegate) tableView:tableView didTouchedDeleteButtonAtIndexPath:indexPath];
      }
      return;
    }
    view = view.superview;
  }
}

@end
