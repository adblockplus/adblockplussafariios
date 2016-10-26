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

#import "AcceptableAdsController.h"

@interface AcceptableAdsController ()<UITableViewDataSource>

@property(nonatomic, nullable, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UISwitch *acceptableAdsEnablingSwitch;

@end

@implementation AcceptableAdsController

- (instancetype)initWithCoder:(NSCoder *)coder
{
  if (self = [super initWithCoder:coder]) {
    _acceptableAdsEnablingSwitch = [[UISwitch alloc] init];
    [_acceptableAdsEnablingSwitch sizeToFit];
    [_acceptableAdsEnablingSwitch addTarget:self action:@selector(onSwitchHasChanged:) forControlEvents:UIControlEventValueChanged];
  }
  return self;
}

- (void)dealloc
{
  self.adblockPlus = nil;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.tableView.tableHeaderView = [[UIView alloc] initWithFrame: CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 1)];
  self.tableView.contentInset = UIEdgeInsetsMake(-1, 0, 0, 0);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(acceptableAdsEnabled))]) {
    self.acceptableAdsEnablingSwitch.on = self.adblockPlus.acceptableAdsEnabled;
  } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(reloading))]) {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [self updateAccessoryViewOfCell: cell];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setAdblockPlus:(AdblockPlusExtras *)adblockPlus
{
  NSArray<NSString *> *keyPaths = @[NSStringFromSelector(@selector(acceptableAdsEnabled)),
                                   NSStringFromSelector(@selector(reloading))];

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

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AcceptableAds" forIndexPath: indexPath];

  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.accessoryView = self.acceptableAdsEnablingSwitch;
  [self updateAccessoryViewOfCell: cell];

  return cell;
}

#pragma mark - Private

- (void)onSwitchHasChanged:(UISwitch *)s
{
  self.adblockPlus.acceptableAdsEnabled = s.on;
}

- (void)updateAccessoryViewOfCell:(UITableViewCell *)cell
{
  if (!self.adblockPlus.reloading) {
    cell.accessoryView = self.acceptableAdsEnablingSwitch;
  } else {
    UIActivityIndicatorView *view =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [view startAnimating];
    cell.accessoryView = view;
  }
}

@end
