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

#import "SwitchCell.h"

@interface SwitchCell ()

@property (nonatomic, strong) UISwitch *cellSwitch;

@end

@implementation SwitchCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  self.cellSwitch = [[UISwitch alloc] init];
  [self.cellSwitch addTarget:self action:@selector(onSwitchDidChanged:) forControlEvents:UIControlEventValueChanged];
  [self.cellSwitch sizeToFit];
  self.accessoryView = self.cellSwitch;
}

- (void)onSwitchDidChanged:(UISwitch *)sender
{
  UIView *view = self.superview;
  while (view != nil) {
    if ([view isKindOfClass:[UITableView class]]) {
      UITableView *tableView = (UITableView *)view;
      if ([tableView.delegate conformsToProtocol:@protocol(SwitchCellTableViewDelegate)]) {
        NSIndexPath *indexPath = [tableView indexPathForCell:self];
        if (indexPath) {
          [(id<SwitchCellTableViewDelegate>)tableView.delegate tableView:tableView didChangedSwitchAtIndexPath:indexPath];
        }
      }
      return;
    }
    view = view.superview;
  }
}

- (BOOL)isOn
{
  return self.cellSwitch.isOn;
}

- (void)setOn:(BOOL)on
{
  self.cellSwitch.on = on;
}

@end
