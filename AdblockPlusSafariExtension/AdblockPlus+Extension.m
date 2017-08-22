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
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/&gt.
 */

#import "AdblockPlus+Extension.h"
#import "AdblockPlus+Parsing.h"
#import "NSDictionary+FilterList.h"

static NSString *emptyFilterListName = @"empty.json";

@implementation AdblockPlus (Extension)

- (NSURL *__nullable)activeFilterListsURL
{
  NSString *fileName;

  if (self.enabled) {
    NSString *filterListName = self.activeFilterListName;
    NSDictionary *filterList = self.filterLists[filterListName];
    fileName = filterList.fileName;

    if (filterList.downloaded && fileName) {
      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSURL *url = [fileManager containerURLForSecurityApplicationGroupIdentifier:self.group];
      url = [url URLByAppendingPathComponent:fileName isDirectory:NO];

      if ([fileManager fileExistsAtPath:url.path]) {
        return url;
      }
    }
  }

  if (!fileName) {
    fileName = emptyFilterListName;
  }

  return [[NSBundle mainBundle] URLForResource:[fileName stringByDeletingPathExtension] withExtension:@"json"];
}

- (NSURL *)activeFilterListURLWithWhitelistedWebsites
{
  NSURL *original = self.activeFilterListsURL;
  NSString *fileName = original.lastPathComponent;

  if (fileName == nil || [fileName isEqual:emptyFilterListName])  {
    return original;
  }

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSURL *copy = [fileManager containerURLForSecurityApplicationGroupIdentifier:self.group];
  copy = [copy URLByAppendingPathComponent:[NSString stringWithFormat:@"ww-%@", fileName] isDirectory:NO];

  NSError *error;
  if (![[self class] mergeFilterListsFromURL:original
                     withWhitelistedWebsites:self.whitelistedWebsites
                                       toURL:copy
                                       error:&error]) {
    return original;
  }

  return copy;
}

@end
