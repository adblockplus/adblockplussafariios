//
//  WhitelistedWebsitesController.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 12/10/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "WhitelistedWebsitesController.h"

@interface NSString (AdblockPlus)

@end

@implementation NSString (AdblockPlus)

- (NSString *__nullable)stringByRemovingHostDisallowedCharacters
{
  [NSCharacterSet alphanumericCharacterSet];

  return [[self componentsSeparatedByCharactersInSet:[[NSCharacterSet URLHostAllowedCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

- (NSString *__nullable)whitelistedHostname
{
  NSString *possibleURL = self;
  if (![possibleURL hasPrefix:@"http://"] || ![possibleURL hasPrefix:@"https://"]) {
    possibleURL = [@"http://" stringByAppendingString:possibleURL];
  }

  NSString *host = [[NSURL URLWithString:possibleURL] host];
  if (host.length == 0) {
    host = self;
  }

  host = [host stringByRemovingHostDisallowedCharacters];

  if ([host hasPrefix:@"www."]) {
    host = [host substringFromIndex:@"www.".length];
  }

  return host;
}

@end


const NSInteger TextFieldTag = 121212;

@interface WhitelistedWebsitesController ()<UITextFieldDelegate>

@end

@implementation WhitelistedWebsitesController

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
    NSString *placeholder = textField.placeholder;
    if (placeholder) {
      UIColor *color = [UIColor colorWithWhite:1.0 * 0xA1 / 0xFF alpha:1.0];
      textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: color}];
    }
  } else if (self.adblockPlus.whitelistedWebsites.count == 0) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"NoWebsiteCell" forIndexPath:indexPath];
  } else {
    cell = [tableView dequeueReusableCellWithIdentifier:@"WebsiteCell" forIndexPath:indexPath];
    cell.textLabel.text = self.adblockPlus.whitelistedWebsites[indexPath.row];

    UIButton *buttom = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttom addTarget:self action:@selector(onTrashButtomTouched:) forControlEvents:UIControlEventTouchUpInside];
    [buttom setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
    buttom.imageEdgeInsets = UIEdgeInsetsMake(0, 30, 0, 0);
    buttom.bounds = CGRectMake(0, 0, 50, 44);

    cell.accessoryView = buttom;
  }
  return cell;
}

#pragma mark - UITextFieldDelegate

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
      [self whitelistWebsite:website];
      return;
    }
    view = [view superview];
  }
}

- (void)onTrashButtomTouched:(UIButton *)sender
{
  id view = sender.superview;
  while (view != nil) {
    if ([view isKindOfClass:[UITableViewCell class]]) {
      NSIndexPath *indexPath = [self.tableView indexPathForCell:view];

      NSMutableArray *websites = [self.adblockPlus.whitelistedWebsites mutableCopy];
      [websites removeObjectAtIndex:indexPath.row];
      self.adblockPlus.whitelistedWebsites = websites;

      if (websites.count > 0) {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
      } else {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
  } else {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

@end
