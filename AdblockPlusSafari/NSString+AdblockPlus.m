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

#import "NSString+AdblockPlus.h"



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
