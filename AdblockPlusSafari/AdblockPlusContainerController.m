//
//  AdblockPlusContainerController.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 03/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "AdblockPlusContainerController.h"

#import "Appearence.h"

@interface AdblockPlusContainerController ()

@property (nonatomic, weak) IBOutlet UILabel *adblockBrowserLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *adblockBrowserBannerConstraint;

@end

@implementation AdblockPlusContainerController

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Test if adblock browser is installed 
  NSURL *adblockBrowserTestUrl = [NSURL URLWithString:@"adblockbrowser://example.com"];
  if ([[UIApplication sharedApplication] canOpenURL:adblockBrowserTestUrl]) {
    self.adblockBrowserBannerConstraint.constant = 0;
  }

  // This is the simpliest way to print Browser word using custom bold font.
  CGFloat fontSize = self.adblockBrowserLabel.font.pointSize;
  UIFont *lightFont = [Appearence defaultLightFontOfSize:fontSize];
  UIFont *boldFont = [Appearence defaultBoldFontOfSize:fontSize];

  NSString *text = NSLocalizedString(@"To get a better ad blocking experience use Adblock\u00a0Browser for iOS", @"");

  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: lightFont}];

  NSRange range = [text rangeOfString:@"Browser" options:NSCaseInsensitiveSearch];

  if (range.location != NSNotFound) {
    [attributedText addAttribute:NSFontAttributeName value:boldFont range:range];
  }

  self.adblockBrowserLabel.fontFamilyName = DefaultFontFamily;
  self.adblockBrowserLabel.attributedText = attributedText;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.destinationViewController respondsToSelector:@selector(setAdblockPlus:)]) {
    [(id)segue.destinationViewController setAdblockPlus:self.adblockPlus];
  }
}

#pragma mark - Action

- (IBAction)onAppStoreButtonTouched:(id)sender
{
  NSString *appStoreId = [[NSBundle mainBundle] infoDictionary][@"AdblockBrowserAppStoreId"];
  NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", appStoreId];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

@end
