//
//  Appearence.h
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 02/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *__nonnull DefaultFontFamily;

@interface UILabel (FontFamily)

@property (nonatomic, strong) NSString *__nonnull fontFamilyName;

@end

@interface UITextField (FontFamily)

@property (nonatomic, strong) NSString *__nonnull fontFamilyName;

@end

@interface Appearence : NSObject

+ (void)applyAppearence;

+ (UIFont *__nonnull)defaultLightFontOfSize:(CGFloat)size;

+ (UIFont *__nonnull)defaultFontOfSize:(CGFloat)size;

+ (UIFont *__nonnull)defaultBoldFontOfSize:(CGFloat)size;

@end
