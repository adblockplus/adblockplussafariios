//
//  RootController.h
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 03/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AdblockPlus.h"

@interface RootController : UINavigationController

@property (nonatomic, strong) AdblockPlus *__nullable adblockPlus;

@end
