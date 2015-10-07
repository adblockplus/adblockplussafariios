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

@interface AdblockPlusExtras : AdblockPlus

// Reloading content blocker
@property (nonatomic) BOOL reloading;

// Updating filter lists
@property (nonatomic, readonly) BOOL updating;

// Date of the last successful update of filter lists
@property (nonatomic, readonly) NSDate *__nullable lastUpdate;

- (void)setEnabled:(BOOL)enabled reload:(BOOL)reload;

- (void)setAcceptableAdsEnabled:(BOOL)enabled reload:(BOOL)reload;

- (void)reloadContentBlockerWithCompletion:(void(^__nullable)(NSError * __nullable error))completion;

- (void)checkActivatedFlag;

- (void)updateFilterlists:(BOOL)userTriggered;

- (void)displayErrorDialogIfNeeded;

@end
