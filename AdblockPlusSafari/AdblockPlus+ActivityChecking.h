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

#import "AdblockPlus.h"

@protocol ContentBlockerManagerProtocol <NSObject>

- (void)reloadWithIdentifier:(NSString *__nonnull)identifier
           completionHandler:(void (^__nullable)(NSError *__nullable error))completionHandler;

@end

@interface AdblockPlus (ActivityChecking)

@property (nonatomic) NSDate *__nullable lastActivity;

- (void)checkActivatedFlag;

- (void)checkActivatedFlag:(NSDate *__nonnull)lastActivity;

- (void)performActivityTestWith:(id<ContentBlockerManagerProtocol> __nonnull)manager;

// This method tests if this execution context is part of activity test.
// In case of success extension should abort its execution with provided error.
// This will reduce time of execution of content blocker
// and therefore host application will be notified about result of testing ASAP.
- (BOOL)shouldRespondToActivityTest:(NSError *__nullable *__nonnull)error;

@end
