//
//  AdblockPlus.h
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 02/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdblockPlus : NSObject

@property (nonatomic) BOOL enabled;

@property (nonatomic) BOOL acceptableAdsEnabled;

@property (nonatomic) BOOL activated;

- (void)setEnabled:(BOOL)enabled reload:(BOOL)reload;

- (void)setAcceptableAdsEnabled:(BOOL)enabled reload:(BOOL)reload;

- (void)reloadContentBlockerWithCompletion:(void(^__nullable)(NSError * __nullable error))completion;

- (void)checkActivatedFlag;

@end
