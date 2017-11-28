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

#import "Appearance.h"

NSString *DefaultFontFamily = @"SourceSansPro";

// This method overrides family name of privided font.
static UIFont *__nonnull createFont(NSString *__nonnull familyName, UIFont *__nonnull fromFont)
{
    NSArray<NSString *> *fontTypes =
        @[ @"Regular",
           @"Black",
           @"Bold",
           @"ExtraLight",
           @"Light",
           @"It",
           @"Semibold" ];

    NSString *type = @"Regular";

    for (NSString *fontType in fontTypes) {
        if ([fromFont.fontName hasSuffix:fontType]) {
            type = fontType;
            break;
        }
    }

    NSString *name = [NSString stringWithFormat:@"%@-%@", familyName, type];

    UIFont *font = [UIFont fontWithName:name size:fromFont.pointSize];

    if (font) {
        return font;
    } else {
        NSLog(@"[WARNING] Font family named '%@' has not been found!", familyName);
        return fromFont;
    }
}

static UIFont *__nonnull createFontWithName(NSString *__nonnull name, CGFloat size, UIFont *__nonnull fallbackFont)
{
    UIFont *font = [UIFont fontWithName:name size:size];
    if (font) {
        return font;
    } else {
        NSLog(@"[WARNING] Font named '\(name)' has not been found!");
        return fallbackFont;
    }
}

@implementation UILabel (FontFamily)

- (NSString *__nonnull)fontFamilyName
{
    return self.font.fontName;
}

- (void)setFontFamilyName:(NSString *__nonnull)fontFamilyName
{
    self.font = createFont(fontFamilyName, self.font);
}

@end

@implementation UITextField (FontFamily)

- (NSString *__nonnull)fontFamilyName
{
    return self.font.fontName;
}

- (void)setFontFamilyName:(NSString *__nonnull)fontFamilyName
{
    self.font = createFont(fontFamilyName, self.font);
}

@end

@implementation Appearance

+ (void)applyAppearance
{
    UILabel.appearance.fontFamilyName = DefaultFontFamily;
    UITextField.appearance.fontFamilyName = DefaultFontFamily;

    // Those items (UINavigationBar, UIBarButtonItem) cannot be style with same hack as above.
    // Font sizes and types have to be extracted from app using debugger or by searching in the internet:
    // http://ivomynttinen.com/blog/the-ios-7-design-cheat-sheet/

    NSString *boldFontName = [NSString stringWithFormat:@"%@-Bold", DefaultFontFamily];
    UIFont *boldFont = [UIFont fontWithName:boldFontName size:17];

    if (boldFont) {
        UINavigationBar.appearance.titleTextAttributes = @{ NSFontAttributeName : boldFont };
    }

    NSString *regularFontName = [NSString stringWithFormat:@"%@-Regular", DefaultFontFamily];
    UIFont *regularFont = [UIFont fontWithName:regularFontName size:17];

    if (regularFont) {
        [UIBarButtonItem.appearance setTitleTextAttributes:@{ NSFontAttributeName : regularFont } forState:UIControlStateNormal];
    }
}

+ (UIFont *__nonnull)defaultLightFontOfSize:(CGFloat)size
{
    NSString *name = [NSString stringWithFormat:@"%@-Light", DefaultFontFamily];
    return createFontWithName(name, size, [UIFont systemFontOfSize:size]);
}

+ (UIFont *__nonnull)defaultFontOfSize:(CGFloat)size
{
    NSString *name = [NSString stringWithFormat:@"%@-Regular", DefaultFontFamily];
    return createFontWithName(name, size, [UIFont systemFontOfSize:size]);
}

+ (UIFont *__nonnull)defaultBoldFontOfSize:(CGFloat)size
{
    NSString *name = [NSString stringWithFormat:@"%@-Bold", DefaultFontFamily];
    return createFontWithName(name, size, [UIFont boldSystemFontOfSize:size]);
}

+ (UIFont *__nonnull)defaultSemiboldFontOfSize:(CGFloat)size
{
    NSString *name = [NSString stringWithFormat:@"%@-Semibold", DefaultFontFamily];
    return createFontWithName(name, size, [UIFont boldSystemFontOfSize:size]);
}

@end

/*
 func createFont(name: String, size: CGFloat, fallbackFont: UIFont) -> UIFont
 {
 if let font = UIFont(name: name, size: size) {
 return font
 } else {
 println("[WARNING] Font named '\(name)' has not been found!")
 return fallbackFont
 }
 }*/

/*
 extension UIFont
 {
 class func defaultRegularFontOfSize(size: CGFloat) -> UIFont
 {
 return createFont(DefaultFontFamily + "-Regular", size, UIFont.systemFontOfSize(size))
 }
 
 class func defaultLightFontOfSize(size: CGFloat) -> UIFont
 {
 return createFont(DefaultFontFamily + "-Light", size, UIFont.systemFontOfSize(size))
 }
 
 class func defaultItalicFontOfSize(size: CGFloat) -> UIFont
 {
 return createFont(DefaultFontFamily + "-It", size, UIFont.systemFontOfSize(size))
 }
 
 class func defaultSemiboldFontOfSize(size: CGFloat) -> UIFont
 {
 return createFont(DefaultFontFamily + "-Semibold", size, UIFont.boldSystemFontOfSize(size))
 }
 }*/
