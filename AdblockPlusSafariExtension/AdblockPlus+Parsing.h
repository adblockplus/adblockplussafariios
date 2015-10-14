//
//  AdblockPlus+Parsing.h
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 14/10/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "AdblockPlus.h"

@interface AdblockPlus (Parsing)

+ (BOOL)mergeFilterListsFromURL:(NSURL *__nonnull)input
        withWhitelistedWebsites:(NSArray<NSString *> *__nonnull)whitelistedWebsites
                          toURL:(NSURL *__nonnull)output
                          error:(NSError *__nullable *__nonnull)error;

@end
