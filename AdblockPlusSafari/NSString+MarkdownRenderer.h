//
//  NSString+MarkdownRenderer.h
//  AdblockPlusSafari
//
//  Created by Pavel Zdeněk on 2.O.15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIFont;

@interface NSString (MarkdownRenderer)

/**
@param token a single character representing a span marker. Can be anything but Markdown
 compatible is `*` for bold and `_` for italic
@param font the font to substitute in the span
@return self as attributed string with font changes applied to the found spans
 */
- (NSAttributedString*)markdownSpanMarkerChar:(NSString*)markerChar
                                renderAsFont:(UIFont*)font;

@end
