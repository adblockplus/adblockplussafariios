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

#import <Foundation/Foundation.h>

@interface FilterList : NSObject

@property (nonatomic, strong, nullable) NSString *filename;
@property (nonatomic, strong, nullable) NSString *version;

@property (nonatomic) BOOL userTriggered;
@property (nonatomic) BOOL downloaded;
@property (nonatomic) BOOL updating;
@property (nonatomic) BOOL lastUpdateFailed;
@property (nonatomic) NSUInteger taskIdentifier;

@property (nonatomic, strong, nullable) NSDate *lastUpdate;
@property (nonatomic) NSTimeInterval expires;

- (instancetype __nonnull)initWithDictionary:(NSDictionary *__nonnull)dictionary;

- (NSDictionary *__nonnull)dictionary;

@end
