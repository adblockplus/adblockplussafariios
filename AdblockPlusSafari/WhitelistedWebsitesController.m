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

#import "WhitelistedWebsitesController.h"

@interface NSString (AdblockPlus)

@end

@implementation NSString (AdblockPlus)

- (NSString *__nullable)stringByRemovingHostDisallowedCharacters
{
  NSMutableCharacterSet *set = [[NSCharacterSet URLHostAllowedCharacterSet] mutableCopy];
  // Some of those characters are allowed in above set.
  [set removeCharactersInString:@"\\|()[{^$*?<>"];
  [set invert];
  return [[self componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@""];
}

- (NSString *__nullable)whitelistedHostname
{
  // Convert to lower case
  NSString *input = [self lowercaseString];

  // Trim hostname
  NSString *hostname = [input stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

  // Prepend scheme if needed
  if (![hostname hasPrefix:@"http://"] && ![hostname hasPrefix:@"https://"]) {
    hostname = [@"http://" stringByAppendingString:hostname];
  }

  // Try to get host from URL
  hostname = [[NSURL URLWithString:hostname] host];
  if (hostname.length == 0) {
    hostname = self;
  }

  // Remove not allowed characters
  hostname = [hostname stringByRemovingHostDisallowedCharacters];

  // Remove www prefix
  if ([hostname hasPrefix:@"www."]) {
    hostname = [hostname substringFromIndex:@"www.".length];
  }

  return hostname;
}

@end


const NSInteger TextFieldTag = 121212;

@interface WhitelistedWebsitesController ()<UITextFieldDelegate>

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
    self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: color}];
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

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(onTrashButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
    button.imageEdgeInsets = UIEdgeInsetsMake(0, 30, 0, 0);
    button.bounds = CGRectMake(0, 0, 50, 44);

    cell.accessoryView = button;
  }
  return cell;
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

- (void)onTrashButtonTouched:(UIButton *)sender
{
  id view = sender.superview;
  while (view != nil) {
    if ([view isKindOfClass:[UITableViewCell class]]) {
      NSIndexPath *indexPath = [self.tableView indexPathForCell:view];

      NSMutableArray *websites = [self.adblockPlus.whitelistedWebsites mutableCopy];
      [websites removeObjectAtIndex:indexPath.row];
      self.adblockPlus.whitelistedWebsites = websites;

      if (websites.count > 0) {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
      } else {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
      }

      return;
    }
    view = [view superview];
  }
}

#pragma mark - Private

- (void)whitelistWebsite:(NSString *)website
{
  website = website.whitelistedHostname;

  if (website.length == 0) {
    return;
  }

  NSArray<NSString *> *websites = self.adblockPlus.whitelistedWebsites;

  if ([websites containsObject:website]) {
    return;
  }

  websites = [@[website] arrayByAddingObjectsFromArray:websites];
  self.adblockPlus.whitelistedWebsites = websites;

  if (websites.count > 1) {
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]
                          withRowAnimation:UITableViewRowAnimationFade];
  } else {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

@end
