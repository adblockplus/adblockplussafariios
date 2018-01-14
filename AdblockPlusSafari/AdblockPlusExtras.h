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

#import "AdblockPlusShared.h"

@class ABPManager;

@interface AdblockPlusExtras : AdblockPlusShared

/// Allow access to the ABP Manager.
@property (nonatomic, weak, nullable) ABPManager *abpManager;

/// Reloading state of the content blocker.
@property (nonatomic) BOOL reloading;

/// Updating state for filter lists.
@property (nonatomic, readonly) BOOL updating;

/// Date of the last successful update of filter lists.
@property (nonatomic, readonly) NSDate *__nullable lastUpdate;

/// When set to YES, an error dialog will be displayed when there is a filter list update failure.
@property (nonatomic) BOOL needsDisplayErrorDialog;

- (nonnull instancetype)initWithABPManager:(ABPManager *__nullable)abpManager;
- (void)updateActiveFilterLists:(BOOL)userTriggered;
- (BOOL)whitelistWebsite:(NSString *__nonnull)website;

@end
