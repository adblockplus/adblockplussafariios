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

#import "AdblockPlusExtras.h"

@import SafariServices;
#import "AdblockPlusSafari-Swift.h"

static NSString *AdblockPlusNeedsDisplayErrorDialog = @"AdblockPlusNeedsDisplayErrorDialog";

/// This class contains legacy setters and getters. The majority of the functionality
/// has been refactored into Swift in FilterListsUpdater.
@implementation AdblockPlusExtras
{
    /// Performs content blocker operations.
    SafariContentBlocker * safariCB;
}

/// Init that passes in a reference to the ABP Manager, held weakly, to avoid
/// circular referencing.
- (instancetype)initWithABPManager:(ABPManager *)abpManager
{
    if (self = [super init]) {
        self.abpManager = abpManager;
        safariCB = [[SafariContentBlocker alloc]
            initWithReloadingSetter:^(BOOL value) { self.reloading = value; }
            performingActivityTestSetter:^(BOOL value) { self.performingActivityTest = value; }
        ];
    }
    return self;
}

#pragma mark - Properties

@dynamic lastUpdate;
@dynamic updating;

- (NSDate *)lastUpdate
{
    return [[self.filterLists allValues] valueForKeyPath:@"@min.lastUpdate"];
}

- (BOOL)updating
{
    return [[[self.filterLists allValues] valueForKeyPath:@"@sum.updating"] integerValue] > 0;
}

- (BOOL)anyLastUpdateFailed
{
    for (NSString *filterListName in self.filterLists) {
        NSDictionary *filterList = self.filterLists[filterListName];
        NSInteger groupID = [self.abpManager.filterListsUpdater updatingGroupIdentifier];
        if ([filterList[@"updatingGroupIdentifier"] integerValue] == groupID
            && [filterList[@"lastUpdateFailed"] boolValue]
            && [filterList[@"userTriggered"] boolValue]) {
            return YES;
        }
    }
    return NO;
}

/// Here, the meaning of lastUpdate is not equal to the last update value for individual filter
/// lists. This will be refactored to have a clearer meaning when converted to Swift.
///
/// This is the first point of contact when filter lists are saved from the Swift side.
/// The lists get synchronized when super.filterLists is set.
- (void)setFilterLists:(NSDictionary<NSString *, NSDictionary<NSString *, NSObject *> *> *)filterLists
{
    NSAssert([NSThread isMainThread], @"This method should be called from main thread only!");
    BOOL wasUpdating = self.updating;
    BOOL hasAnyLastUpdateFailed = self.anyLastUpdateFailed;
    [self willChangeValueForKey:@"lastUpdate"];
    [self willChangeValueForKey:@"updating"];
    super.filterLists = filterLists;
    [self didChangeValueForKey:@"updating"];
    [self didChangeValueForKey:@"lastUpdate"];
    BOOL updating = self.updating;
    BOOL anyLastUpdateFailed = self.anyLastUpdateFailed;
    if (self.installedVersion < self.downloadedVersion && wasUpdating && !updating) {
        // Force content blocker to load newer version of filter list
        [safariCB reloadContentBlockerWithCompletion:nil];
    }
    if (hasAnyLastUpdateFailed != anyLastUpdateFailed) {
        self.needsDisplayErrorDialog = anyLastUpdateFailed;
    }
}

- (void)setWhitelistedWebsites:(NSArray<NSString *> *)whitelistedWebsites
{
    super.whitelistedWebsites = whitelistedWebsites;
    [safariCB reloadContentBlockerWithCompletion:nil];
}

- (void)setNeedsDisplayErrorDialog:(BOOL)needsDisplayErrorDialog
{
    _needsDisplayErrorDialog = needsDisplayErrorDialog;
    [self.adblockPlusDetails setBool:needsDisplayErrorDialog forKey:AdblockPlusNeedsDisplayErrorDialog];
    [self.adblockPlusDetails synchronize];
}

#pragma mark - Enable/Disable switch

- (void)setEnabled:(BOOL)enabled
{
    super.enabled = enabled;
    [safariCB reloadContentBlockerWithCompletion:nil];
}

#pragma mark - Updating

/// Calls the Swift implementation. Only the active filter list is requested to be updated. Here,
/// the active filter list is obtained from the Objective-C side.
- (void)updateActiveFilterLists:(BOOL)userTriggered
{
    [[[ABPManager sharedInstance] filterListsUpdater]
                  updateFilterListsWithNames:@[self.activeFilterListName]
                               userTriggered:userTriggered
                                  completion:nil];
}

#pragma mark - Unit Testing -

/// Only used for unit testing. The replacement implementation is on the Swift side.
- (BOOL)whitelistWebsite:(NSString *__nonnull)website
{
    return [[ABPManager sharedInstance] whiteListWithWebsite:website];
}

@end
