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

#import "WhitelistedWebsitesController.h"

#import "WhitelistedSiteCell.h"
#import "NSString+AdblockPlus.h"

const NSInteger TextFieldTag = 121212;

@interface WhitelistedWebsitesController () <UITextFieldDelegate, WhitelistingDelegate>

@property (nonatomic, strong) NSAttributedString *attributedPlaceholder;

@end

@implementation WhitelistedWebsitesController

- (void)awakeFromNib
{
    [super awakeFromNib];

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AddingCell"];
    UITextField *textField = (UITextField *)[cell viewWithTag:TextFieldTag];
    NSString *placeholder = textField.placeholder;
    if (placeholder) {
        UIColor *color = [UIColor colorWithWhite:1.0 * 0xA1 / 0xFF alpha:1.0];
        self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{ NSForegroundColorAttributeName : color }];
    }
}

- (void)dealloc
{
    self.adblockPlus = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(whitelistedWebsites))]) {
        [self.tableView reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else {
        return MAX(1, self.adblockPlus.whitelistedWebsites.count);
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"ADD WEBSITE TO WHITELIST", @"Whitelisted Websites Controller");
    } else {
        return NSLocalizedString(@"YOUR WHITELIST", @"Whitelisted Websites Controller");
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"AddingCell" forIndexPath:indexPath];
        UITextField *textField = (UITextField *)[cell viewWithTag:TextFieldTag];
        textField.attributedPlaceholder = self.attributedPlaceholder;
    } else if (self.adblockPlus.whitelistedWebsites.count == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NoWebsiteCell" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"WebsiteCell" forIndexPath:indexPath];
        cell.textLabel.text = self.adblockPlus.whitelistedWebsites[indexPath.row];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didTouchedDeleteButtonAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *websites = [self.adblockPlus.whitelistedWebsites mutableCopy];
    [websites removeObjectAtIndex:indexPath.row];
    self.adblockPlus.whitelistedWebsites = websites;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.attributedPlaceholder = nil;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    textField.attributedPlaceholder = self.attributedPlaceholder;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSString *website = textField.text;
    textField.text = nil;
    [self whitelistWebsite:website];
    return NO;
}

#pragma makr - Action

- (IBAction)onAddWebsiteTouched:(UIButton *)sender
{
    id view = sender.superview;
    while (view != nil) {
        if ([view isKindOfClass:[UITableViewCell class]]) {
            UITextField *textField = (UITextField *)[view viewWithTag:TextFieldTag];
            NSString *website = textField.text;
            textField.text = nil;
            [textField resignFirstResponder];
            [self whitelistWebsite:website];
            return;
        }
        view = [view superview];
    }
}

#pragma mark - Properties

@dynamic whitelistedWebsite;

- (NSString *)whitelistedWebsite
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITextField *textField = (UITextField *)[cell viewWithTag:TextFieldTag];
    return textField.text;
}

- (void)setWhitelistedWebsite:(NSString *)whitelistedWebsite
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITextField *textField = (UITextField *)[cell viewWithTag:TextFieldTag];
    textField.text = whitelistedWebsite;
}

- (void)setAdblockPlus:(AdblockPlusExtras *)adblockPlus
{
    NSArray<NSString *> *keyPaths = @[ NSStringFromSelector(@selector(whitelistedWebsites)) ];

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

#pragma mark - Private

- (void)whitelistWebsite:(NSString *)website
{
    [self.adblockPlus whitelistWebsite:website.whitelistedHostname];
}

@end
