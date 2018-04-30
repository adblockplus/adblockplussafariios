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

#import "CustomFilterListsController.h"

#import "SwitchCell.h"
#import "FilterList.h"
#import "NSDictionary+FilterList.h"
#import "AdblockPlusSafari-Swift.h"

static NSString *customFilterListKey = @"customFilterListKey";
static NSString *customFilterListFileName = @"custom.json";
static NSString *customFilterListUrl = @"https://easylist-downloads.adblockplus.org/easylist_content_blocker.json";

@interface AdblockPlus (CustomFilterListsController)

@property (nonatomic, readonly) BOOL customFilterListEnabled;

@end

@implementation AdblockPlus (CustomFilterListsController)

- (BOOL)customFilterListEnabled
{
    return !!self.filterLists[CustomFilterListName];
}

@end

@interface CustomFilterListsController () <SwitchCellTableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSString *customFilterListUrl;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation CustomFilterListsController
{
    /// Performs content blocker operations.
    SafariContentBlocker * safariCB;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        safariCB = [[SafariContentBlocker alloc]
             initWithReloadingSetter:^(BOOL value) { self.adblockPlus.reloading = value; }
             performingActivityTestSetter:^(BOOL value) { self.adblockPlus.performingActivityTest = value; }
         ];
    }
    return self;
}

- (void)dealloc
{
    self.adblockPlus = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(updating))]) {
        if (self.adblockPlus.updating) {
            [self.activityIndicatorView startAnimating];
        } else {
            [self.activityIndicatorView stopAnimating];
        }
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(filterLists))]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]
                      withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)setAdblockPlus:(AdblockPlusExtras *)adblockPlus
{
    NSArray<NSString *> *keyPaths = @[ NSStringFromSelector(@selector(filterLists)),
                                       NSStringFromSelector(@selector(updating)) ];

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

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *defaultTitle = [super tableView:tableView titleForFooterInSection:section];

    if (section == 0) {
        NSDate *lastUpdate = [self.adblockPlus.filterLists[self.adblockPlus.activeFilterListName] lastUpdate];
        if (lastUpdate) {
            return [NSString stringWithFormat:defaultTitle, [self.dateFormatter stringFromDate:lastUpdate]];
        }
        return nil;
    }
    if (section == 1) {
        FilterList *filterList = [[FilterList alloc] initWithDictionary:self.adblockPlus.filterLists[CustomFilterListName]];
        return [self footerTitleForFilterList:filterList].string;
    }
    return defaultTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    if (indexPath.section == 0 && indexPath.row == 0 && [cell isKindOfClass:[SwitchCell class]]) {
        [(SwitchCell *)cell setOn:self.adblockPlus.defaultFilterListEnabled];
    } else if ([cell.reuseIdentifier isEqualToString:@"EnableCustomFilterList"] && [cell isKindOfClass:[SwitchCell class]]) {
        [(SwitchCell *)cell setOn:self.adblockPlus.customFilterListEnabled];
    } else if ([cell.reuseIdentifier isEqualToString:@"CustomFilterListUrl"]) {
        if (self.adblockPlus.customFilterListEnabled) {
            cell.backgroundColor = [UIColor whiteColor];
            cell.userInteractionEnabled = YES;
        } else {
            cell.backgroundColor = [UIColor colorWithWhite:244.0 / 256.0 alpha:1.0];
            cell.userInteractionEnabled = NO;
        }

        UIView *view = [cell viewWithTag:10001];
        if ([view isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)view;
            textField.text = self.customFilterListUrl;
        }
    } else if ([cell.reuseIdentifier isEqualToString:@"UpdateFilterLists"]) {
        cell.accessoryView = self.activityIndicatorView;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didChangedSwitchAtIndexPath:(NSIndexPath *)indexPath;
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if ([cell.reuseIdentifier isEqualToString:@"EnableDefaultFilterList"]) {
        self.adblockPlus.defaultFilterListEnabled = !self.adblockPlus.defaultFilterListEnabled;
        [safariCB reloadContentBlockerWithCompletion:nil];
    } else if ([cell.reuseIdentifier isEqualToString:@"EnableCustomFilterList"]) {
        NSMutableDictionary<NSString *, id> *filterLists = nil;

        if (self.adblockPlus.customFilterListEnabled) {
            if (self.adblockPlus.filterLists[CustomFilterListName]) {
                filterLists = [self.adblockPlus.filterLists mutableCopy];
                [filterLists removeObjectForKey:CustomFilterListName];
            }
        } else {
            [self createOrUpdateFilterListFromText:self.customFilterListUrl];
        }

        if (filterLists) {
            self.adblockPlus.filterLists = filterLists;
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]] && section == 1) {
        UITableViewHeaderFooterView *headerFooterView = (UITableViewHeaderFooterView *)view;
        FilterList *filterList = [[FilterList alloc] initWithDictionary:self.adblockPlus.filterLists[CustomFilterListName]];
        headerFooterView.textLabel.attributedText = [self footerTitleForFilterList:filterList];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if ([cell.reuseIdentifier isEqualToString:@"UpdateFilterLists"]) {
        [self.adblockPlus updateActiveFilterLists:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UITextField

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    self.customFilterListUrl = textField.text;
    [self createOrUpdateFilterListFromText:textField.text];
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Private

- (NSURL *)createFilterListURLFromText:(NSString *)input
{
    // Trim input
    NSString *url = [input stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([url length] == 0) {
        return nil;
    }

    // Prepend scheme if needed
    if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
        url = [@"http://" stringByAppendingString:url];
    }

    return [NSURL URLWithString:url];
}

- (void)createOrUpdateFilterListFromText:(NSString *)text
{
    NSURL *url = [self createFilterListURLFromText:text];
    if (!url) {
        return;
    }

    FilterList *customFilterList = [[FilterList alloc] initWithDictionary:@{}];
    customFilterList.fileName = customFilterListFileName;
    customFilterList.url = url.absoluteString;
    NSMutableDictionary<NSString *, id> *filterLists = [self.adblockPlus.filterLists mutableCopy];
    filterLists[CustomFilterListName] = customFilterList.dictionary;
    self.adblockPlus.filterLists = filterLists;
    [[[ABPManager sharedInstance] filterListsUpdater]
                  updateFilterListsWithNames:@[CustomFilterListName]
                               userTriggered:NO completion:nil];
}

- (NSDateFormatter *)dateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale currentLocale];
    dateFormatter.dateStyle = NSDateFormatterFullStyle;
    #ifdef DEBUG
    dateFormatter.timeStyle = NSDateFormatterLongStyle;
    #else
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    #endif

    return dateFormatter;
}

- (NSString *)customFilterListUrl
{
    NSString *url = [NSUserDefaults.standardUserDefaults stringForKey:customFilterListKey];
    if ([url length] == 0) {
        return customFilterListUrl;
    }
    return url;
}

- (void)setCustomFilterListUrl:(NSString *)customFilterListUrl
{
    if ([customFilterListUrl length] > 0) {
        [NSUserDefaults.standardUserDefaults setObject:customFilterListUrl forKey:customFilterListKey];
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:customFilterListKey];
    }
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSAttributedString *)footerTitleForFilterList:(FilterList *)filterList
{
    if (filterList) {
        if (!filterList.lastUpdateFailed) {
            if (!filterList.updating) {
                if (filterList.lastUpdate) {
                    NSString *title = [NSString stringWithFormat:@"Last filter list update: %@", [[self dateFormatter] stringFromDate:filterList.lastUpdate]];
                    return [[NSAttributedString alloc] initWithString:title attributes:@{}];
                }
                return nil;
            }

            NSString *validURLmessage = NSLocalizedString(@"Valid URL, downloading...",
                                                          @"Message shown while downloading a filterlist from a custom URL");
            UIColor *greenColor = [UIColor colorWithRed:68.0 / 256 green:151.0 / 256 blue:45.0 / 256 alpha:1.0];
            return [[NSAttributedString alloc] initWithString:validURLmessage attributes:@{NSForegroundColorAttributeName: greenColor}];
        }

        NSString *invalidURLmessage = NSLocalizedString(@"Invalid URL",
                                                        @"Message shown if an invalid URL is presented for a filterlist from a custom URL");
        UIColor *redColor = [UIColor colorWithRed:195.0 / 256 green:48.0 / 256 blue:37.0 / 256 alpha:1.0];
        return [[NSAttributedString alloc] initWithString:invalidURLmessage attributes:@{NSForegroundColorAttributeName: redColor}];
    }
    return nil;
}

@end
