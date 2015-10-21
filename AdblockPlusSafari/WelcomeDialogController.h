//
//  WelcomeDialogController.h
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 21/10/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AdblockPlusExtras.h"

@interface WelcomeDialogController : UIViewController

+ (BOOL)shouldShowWelcomeDialogController:(AdblockPlusExtras *__nonnull)adblockPlus;

@property (nonatomic, strong) AdblockPlusExtras *__nullable adblockPlus;

@end
