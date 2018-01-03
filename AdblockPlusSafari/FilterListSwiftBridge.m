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

#import "FilterListSwiftBridge.h"

/// This is a bridge class for use with Swift. It allows a filter list to be
/// tested for parsing with YAJL. The reason for doing it this way is to
/// maintain a clear separation between Swift and Objective-C with regard to
/// filter list model objects. It also prevents the need for rewriting YAJL
/// operations into Swift.
@implementation FilterListSwiftBridge

/// Create a new instance using an Objective-C based filter list model object.
- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.filterList = [[FilterList alloc] initWithDictionary:dictionary];
    }
    return self;
}

/// Check the parsability of a filter list.
- (BOOL)parseFilterListFromURL:(nonnull NSURL *)url
                     withError:(NSError *__nullable *__nullable)error
{
    return [self.filterList parseFilterListFromURL:url
                                             error:error];
}

@end
