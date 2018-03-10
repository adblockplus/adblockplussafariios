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

#import "AdblockPlusController.h"

#import "NSDictionary+FilterList.h"

typedef NS_ENUM(NSInteger, AdblockPlusControllerSection) {
    AdblockPlusControllerSectionDefault = 0,
    AdblockPlusControllerSectionExceptions = 1,
    AdblockPlusControllerSectionMore = 2,
    AdblockPlusControllerSectionCount = 3
};

@interface AdblockPlusControllerBase ()

@property (nonatomic, strong) UISwitch *blockingEnablingSwitch;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation AdblockPlusControllerBase

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // There is an issue with swipe back navigation gesture,
    // when cell is not deselected after end of gesture.
    // Related issue: https://issues.adblockplus.org/ticket/3310
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath != nil) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

/// Explicit main thread dispatching has been added to reloading state changes
/// so that UI APIs are correctly accessed when reloading changes on a
/// background thread.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(enabled))]) {
        self.blockingEnablingSwitch.on = self.adblockPlus.enabled;
        NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];
        [sections addIndex:AdblockPlusControllerSectionDefault];
        [sections addIndex:AdblockPlusControllerSectionExceptions];
        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(reloading))]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                                                             inSection:0]];
            [self updateAccessoryViewOfCell:cell];
        });
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(updating))]) {
        if (self.adblockPlus.updating) {
            [self.activityIndicatorView startAnimating];
        } else {
            [self.activityIndicatorView stopAnimating];
        }
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(filterLists))]) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:AdblockPlusControllerSectionDefault];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setAdblockPlus:(AdblockPlusExtras *)adblockPlus
{
    NSArray<NSString *> *keyPaths = @[ NSStringFromSelector(@selector(enabled)),
                                       NSStringFromSelector(@selector(reloading)),
                                       NSStringFromSelector(@selector(updating)),
                                       NSStringFromSelector(@selector(filterLists)) ];
    for (NSString *keyPath in keyPaths) {
        [_adblockPlus removeObserver:self
                          forKeyPath:keyPath];
    }
    _adblockPlus = adblockPlus;
    for (NSString *keyPath in keyPaths) {
        [_adblockPlus addObserver:self
                       forKeyPath:keyPath
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = [super numberOfSectionsInTableView:tableView];
    NSAssert(count == AdblockPlusControllerSectionCount,
             @"Number of controller's sections doesn't correspond with section enum");
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    if ([cell.reuseIdentifier isEqualToString:@"AdblockPlus"]) {
        cell.accessoryView = self.blockingEnablingSwitch;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [self updateAccessoryViewOfCell:cell];
    } else if ([cell.reuseIdentifier isEqualToString:@"UpdateFilterLists"]) {
        cell.accessoryView = self.activityIndicatorView;
    } else if ([cell.reuseIdentifier isEqualToString:@"AcceptableAds"]
               || [cell.reuseIdentifier isEqualToString:@"WhitelistedWebsites"]) {
        BOOL enabled = self.adblockPlus.enabled;
        cell.userInteractionEnabled = enabled;
        cell.selectionStyle = enabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
        cell.textLabel.enabled = enabled;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDate *lastUpdate = [self.adblockPlus.filterLists[self.adblockPlus.activeFilterListName] lastUpdate];
    if (section == AdblockPlusControllerSectionDefault && lastUpdate != nil) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale currentLocale];
        dateFormatter.dateStyle = NSDateFormatterFullStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        NSString *footerFormat = [super tableView:tableView titleForFooterInSection:section];
        return [NSString stringWithFormat:footerFormat, [dateFormatter stringFromDate:lastUpdate]];
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if ([cell.reuseIdentifier isEqualToString:@"AcceptableAds"]) {
        [self.parentViewController performSegueWithIdentifier:@"AcceptableAdsSegue" sender:nil];
    } else if ([cell.reuseIdentifier isEqualToString:@"About"]) {
        [self.parentViewController performSegueWithIdentifier:@"AboutSegue" sender:nil];
    } else if ([cell.reuseIdentifier isEqualToString:@"WhitelistedWebsites"]) {
        [self.parentViewController performSegueWithIdentifier:@"WhitelistedWebsitesSegue" sender:nil];
    } else if ([cell.reuseIdentifier isEqualToString:@"UpdateFilterLists"]) {
        [self.adblockPlus updateActiveFilterLists:NO];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Private

- (void)onSwitchHasChanged:(UISwitch *)s
{
    self.adblockPlus.enabled = s.on;
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

@implementation AdblockPlusController : AdblockPlusControllerBase
#ifdef CONFIGURABLE_CUSTOM_FILTER_LIST_ENABLED

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == AdblockPlusControllerSectionDefault) {
        return [super tableView:tableView numberOfRowsInSection:section] + 1;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == AdblockPlusControllerSectionDefault && indexPath.row > 0) {
        if (indexPath.row == 1) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ConfigureFilterLists"];
            cell.textLabel.text = NSLocalizedString(@"Configure Filter Lists",
                                                    @"Title of menu option to configure filter lists.");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            BOOL enabled = self.adblockPlus.enabled;
            cell.userInteractionEnabled = enabled;
            cell.selectionStyle = enabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.textLabel.enabled = enabled;
            return cell;
        }

        NSInteger row = indexPath.row - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:AdblockPlusControllerSectionDefault];
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if ([cell.reuseIdentifier isEqualToString:@"ConfigureFilterLists"]) {
        [self.parentViewController performSegueWithIdentifier:@"ConfigureFilterListsSegue" sender:nil];
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

#endif
@end
