//
//  AdblockPlus+Extension.h
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 16/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "AdblockPlus.h"

@interface AdblockPlus (Extension)

- (NSURL *__nullable)currentFilterlistURL;

@end
