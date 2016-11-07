//
//  AdblockPlus+ActivityChecking.h
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 03/11/16.
//  Copyright © 2016 Eyeo GmbH. All rights reserved.
//

#import "AdblockPlus.h"

@protocol ContentBlockerManagerProtocol <NSObject>

- (void)reloadWithIdentifier:(NSString *__nonnull)identifier
           completionHandler:(void (^__nullable)(NSError *__nullable error))completionHandler;

@end

@interface AdblockPlus (ActivityChecking)

@property (nonatomic) NSDate *__nullable lastActivity;

- (void)checkActivatedFlag;

- (void)performActivityTestWith:(id<ContentBlockerManagerProtocol> __nonnull)manager;

- (BOOL)shouldRespondToActivityTest:(NSError *__nullable *__nonnull)error;

@end
