//
//  AdblockPlus+Extension.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 16/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "AdblockPlus+Extension.h"

@implementation AdblockPlus (Extension)

- (NSURL *)currentFilterlistURL
{
  NSString *filename;

  if (!self.enabled) {
    filename = @"empty";
  } else if (self.acceptableAdsEnabled) {
    filename = @"easylist_with_acceptable_ads";
  } else {
    filename = @"easylist";
  }

  for (NSString *filterlistName in self.filterlists) {
    NSDictionary *filterlist = self.filterlists[filterlistName];
    if ([filename isEqualToString:filterlist[@"filename"]]) {
      if (![filterlist[@"downloaded"] boolValue]) {
        break;
      }

      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSURL *url = [fileManager containerURLForSecurityApplicationGroupIdentifier:self.group];
      url = [url URLByAppendingPathComponent:filename isDirectory:NO];

      if (![fileManager fileExistsAtPath:url.absoluteString]) {
        break;
      }

      return url;
    }
  }

  return [[NSBundle mainBundle] URLForResource:filename withExtension:@"json"];
}

@end
