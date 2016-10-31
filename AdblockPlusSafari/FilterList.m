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

#import "FilterList.h"

#import <objc/runtime.h>

@implementation FilterList

+ (NSArray *)allProperties
{
  static NSMutableArray *properties;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    unsigned int count = 0;
    objc_property_t *list = class_copyPropertyList([self class], &count);
    properties = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i++) {
      [properties addObject:[NSString stringWithFormat:@"%s", property_getName(list[i])]];
    }
  });

  return properties;
}

+ (NSArray *)boolProperties
{
  static NSMutableArray *properties;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    unsigned int count = 0;
    objc_property_t *list = class_copyPropertyList([self class], &count);
    properties = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i++) {
      const char *pattern = "TB,";
      const char *attributes = property_getAttributes(list[i]);
      if (strncmp(pattern, attributes, strlen(pattern)) == 0) {
        [properties addObject:[NSString stringWithFormat:@"%s", property_getName(list[i])]];
      }
    }
  });

  return properties;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
{
  if (!dictionary) {
    return nil;
  }

  if (self = [super init]) {
    for (NSString *key in [FilterList allProperties]) {
      [self setValue:[dictionary valueForKey:key] forKey:key];
    }
  }

  return self;
}

- (NSDictionary *)dictionary
{
  NSAssert(self.fileName, @"Filename must be set!");
  NSAssert(self.url, @"Url must be set!");

  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

  for (NSString *key in [FilterList allProperties]) {
    id value = [self valueForKey:key];
    [dictionary setValue:value forKey:key];
  }

  return dictionary;
}

- (id)valueForKey:(NSString *)key
{
  id value = [super valueForKey:key];

  if ([[[self class] boolProperties] containsObject:key]) {
    return [value boolValue] ? value : nil;
  }

  return value;
}

- (void)setNilValueForKey:(NSString *)key
{
  if ([[[self class] boolProperties] containsObject:key]) {
    [self setValue:@NO forKey:key];
    return;
  }

  if ([@[@"taskIdentifier", @"expires", @"updatingGroupIdentifier"] containsObject:key]) {
    [self setValue:@0 forKey:key];
    return;
  }

  [super setNilValueForKey:key];
}

@end
