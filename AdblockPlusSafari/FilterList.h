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
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Foundation/Foundation.h>

@interface FilterList : NSObject

@property (nonatomic, strong, nonnull) NSString *url;
@property (nonatomic, strong, nonnull) NSString *fileName;
@property (nonatomic, strong, nullable) NSString *version;

@property (nonatomic) BOOL userTriggered;
@property (nonatomic) BOOL downloaded;
@property (nonatomic) BOOL updating;
@property (nonatomic) BOOL lastUpdateFailed;
// Task identifier of associated download task
@property (nonatomic) NSUInteger taskIdentifier;
// Group identifier refer to associated download group.
// Only download tasks, which were triggered by user,
// are allowed to display download failure dialogs.
// updatingGroupIdentifier represent the most recent download tasks.
@property (nonatomic) NSUInteger updatingGroupIdentifier;

@property (nonatomic, strong, nullable) NSDate *lastUpdate;
@property (nonatomic) NSTimeInterval expires;
@property (nonatomic) NSUInteger downloadCount;

- (instancetype __nullable)initWithDictionary:(NSDictionary *__nullable)dictionary;

- (NSDictionary *__nonnull)dictionary;

@end
