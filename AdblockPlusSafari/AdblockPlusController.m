//
//  AdblockPlusController.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 01/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "AdblockPlusController.h"

@interface AdblockPlusController ()

@property (nonatomic, strong) UISwitch *blockingEnablingSwitch;

@end

@implementation AdblockPlusController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if (self = [super initWithCoder:aDecoder]) {
    _blockingEnablingSwitch = [[UISwitch alloc] init];
    [_blockingEnablingSwitch sizeToFit];
    [_blockingEnablingSwitch addTarget:self action:@selector(onSwitchHasChanged:) forControlEvents:UIControlEventValueChanged];
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
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setAdblockPlus:(AdblockPlus *)adblockPlus
{
  NSString *keyPath = NSStringFromSelector(@selector(enabled));
  [_adblockPlus removeObserver:self forKeyPath:keyPath];
  _adblockPlus = adblockPlus;
  [_adblockPlus addObserver:self
                 forKeyPath:keyPath
                    options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                    context:nil];
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
  } else if ([cell.reuseIdentifier isEqualToString:@"AcceptableAds"]) {
    BOOL enabled = self.adblockPlus.enabled;
    cell.userInteractionEnabled = enabled;
    cell.selectionStyle = enabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    cell.textLabel.enabled = enabled;
  }

  return cell;
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
}

#pragma mark - Private

- (void)onSwitchHasChanged:(UISwitch *)s
{
  [self.adblockPlus setEnabled:s.on reload:YES];
}

@end
