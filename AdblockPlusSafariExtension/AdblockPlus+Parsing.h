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

#import "AdblockPlus.h"

@interface AdblockPlus (Parsing)

+ (NSString *)escapeHostname:(NSString *)hostname;

/**
 *  Merges filter list from given json file with whitelisted websites and generates new json file.
 */
+ (BOOL)mergeFilterListsFromURL:(NSURL *__nonnull)input
        withWhitelistedWebsites:(NSArray<NSString *> *__nonnull)whitelistedWebsites
                          toURL:(NSURL *__nonnull)output
                          error:(NSError *__nullable *__nonnull)error;

@end
