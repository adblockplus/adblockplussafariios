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
    filename = @"empty.json";
  } else if (self.acceptableAdsEnabled) {
    filename = @"easylist+exceptionrules_content_blocker.json";
  } else {
    filename = @"easylist_content_blocker.json";
  }

  for (NSString *filterListName in self.filterLists) {
    NSDictionary *filterList = self.filterLists[filterListName];
    if ([filename isEqualToString:filterList[@"filename"]]) {
      if (![filterList[@"downloaded"] boolValue]) {
        break;
      }

      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSURL *url = [fileManager containerURLForSecurityApplicationGroupIdentifier:self.group];
      url = [url URLByAppendingPathComponent:filename isDirectory:NO];

      if (![fileManager fileExistsAtPath:url.path]) {
        break;
      }

      return url;
    }
  }

  return [[NSBundle mainBundle] URLForResource:[filename stringByDeletingPathExtension] withExtension:@"json"];
}

@end
