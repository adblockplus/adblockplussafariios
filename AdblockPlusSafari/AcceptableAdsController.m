//
//  AcceptableAdsController.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 01/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

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
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setAdblockPlus:(AdblockPlus *)adblockPlus
{
  NSString *keyPath = NSStringFromSelector(@selector(acceptableAdsEnabled));
  [_adblockPlus removeObserver:self forKeyPath:keyPath];
  _adblockPlus = adblockPlus;
  [_adblockPlus addObserver:self
                 forKeyPath:keyPath
                    options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                    context:nil];
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

  return cell;
}

#pragma mark - Private

- (void)onSwitchHasChanged:(UISwitch *)s
{
  [self.adblockPlus setAcceptableAdsEnabled:s.on reload:YES];
}

@end
