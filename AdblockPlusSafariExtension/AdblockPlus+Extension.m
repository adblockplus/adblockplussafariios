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

#import "AdblockPlus+Extension.h"

@implementation AdblockPlus (Extension)

- (NSURL *)currentFilterlistURL
{
  NSString *filename;

  if (!self.enabled) {
    filename = @"empty";
  } else if (self.acceptableAdsEnabled) {
    filename = @"easylist+exceptionrules_content_blocker";
  } else {
    filename = @"easylist_content_blocker";
  }

  for (NSString *filterlistName in self.filterLists) {
    NSDictionary *filterlist = self.filterLists[filterlistName];
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
