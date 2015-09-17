//
//  AdblockPlusExtras.h
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 16/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "AdblockPlus.h"

@interface AdblockPlusExtras : AdblockPlus

// Reloading content blocker
@property (nonatomic) BOOL reloading;

// Updating filterlists
@property (nonatomic, readonly) BOOL updating;

// Date of the last successful update of filterlists
@property (nonatomic, readonly) NSDate *__nullable lastUpdate;

- (void)setEnabled:(BOOL)enabled reload:(BOOL)reload;

- (void)setAcceptableAdsEnabled:(BOOL)enabled reload:(BOOL)reload;

- (void)reloadContentBlockerWithCompletion:(void(^__nullable)(NSError * __nullable error))completion;

- (void)checkActivatedFlag;

- (void)updateFilterlists;

@end
