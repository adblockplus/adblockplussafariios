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

#import "AdblockPlusController.h"

@interface AdblockPlusController ()

@property (nonatomic, strong) UISwitch *blockingEnablingSwitch;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation AdblockPlusController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if (self = [super initWithCoder:aDecoder]) {
    _blockingEnablingSwitch = [[UISwitch alloc] init];
    [_blockingEnablingSwitch sizeToFit];
    [_blockingEnablingSwitch addTarget:self action:@selector(onSwitchHasChanged:) forControlEvents:UIControlEventValueChanged];
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  }
  return self;
}

- (void)dealloc
{
  self.adblockPlus = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(enabled))]) {
    self.blockingEnablingSwitch.on = self.adblockPlus.enabled;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
  } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(reloading))]) {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [self updateAccessoryViewOfCell:cell];
  } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(updating))]) {
    if (self.adblockPlus.updating) {
      [self.activityIndicatorView startAnimating];
    } else {
      [self.activityIndicatorView stopAnimating];
    }
  } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(lastUpdate))]) {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setAdblockPlus:(AdblockPlusExtras *)adblockPlus
{
  NSArray<NSString *> *keyPaths = @[NSStringFromSelector(@selector(enabled)),
                                    NSStringFromSelector(@selector(reloading)),
                                    NSStringFromSelector(@selector(updating)),
                                    NSStringFromSelector(@selector(lastUpdate))];

  for (NSString *keyPath in keyPaths) {
    [_adblockPlus removeObserver:self
                      forKeyPath:keyPath];
  }
  _adblockPlus = adblockPlus;
  for (NSString *keyPath in keyPaths) {
    [_adblockPlus addObserver:self
                   forKeyPath:keyPath
                      options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                      context:nil];
  }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.destinationViewController respondsToSelector:@selector(setAdblockPlus:)]) {
    [(id)segue.destinationViewController setAdblockPlus:self.adblockPlus];
  }
}

#pragma mark - UITableViewDataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

  if ([cell.reuseIdentifier isEqualToString:@"AdblockPlus"]) {
    cell.accessoryView = self.blockingEnablingSwitch;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [self updateAccessoryViewOfCell: cell];
  } else  if ([cell.reuseIdentifier isEqualToString:@"UpdateFilterlists"]) {
    cell.accessoryView = self.activityIndicatorView;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  } else if ([cell.reuseIdentifier isEqualToString:@"AcceptableAds"]) {
    BOOL enabled = self.adblockPlus.enabled;
    cell.userInteractionEnabled = enabled;
    cell.selectionStyle = enabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    cell.textLabel.enabled = enabled;
  }

  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
  NSDate *lastUpdate = self.adblockPlus.lastUpdate;
  if (section == 0 && lastUpdate != nil) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale currentLocale];
    dateFormatter.dateStyle = NSDateFormatterFullStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    return [NSString stringWithFormat:@"Last filterlist update: %@", [dateFormatter stringFromDate:lastUpdate]];
  } else {
    return nil;
  }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

  if ([cell.reuseIdentifier isEqualToString:@"AcceptableAds"]) {
    [self.parentViewController performSegueWithIdentifier:@"AcceptableAdsSegue" sender:nil];
  }

  if ([cell.reuseIdentifier isEqualToString:@"About"]) {
    [self.parentViewController performSegueWithIdentifier:@"AboutSegue" sender:nil];
  }

  if ([cell.reuseIdentifier isEqualToString:@"UpdateFilterlists"]) {
    [self.adblockPlus updateFilterlists];
  }
}

#pragma mark - Private

- (void)onSwitchHasChanged:(UISwitch *)s
{
  [self.adblockPlus setEnabled:s.on reload:YES];
}

- (void)updateAccessoryViewOfCell:(UITableViewCell *)cell
{
  if (!self.adblockPlus.reloading) {
    cell.accessoryView = self.blockingEnablingSwitch;
  } else {
    UIActivityIndicatorView *view =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [view startAnimating];
    cell.accessoryView = view;
  }
}

@end
