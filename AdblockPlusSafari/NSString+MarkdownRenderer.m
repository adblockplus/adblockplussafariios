/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-2015 Eyeo GmbH
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
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/&gt.
 */

#import "NSString+MarkdownRenderer.h"
@import UIKit;

@implementation NSString (MarkdownRenderer)

static NSRegularExpression* pairingRegex;

- (NSAttributedString*)markdownSpanMarkerChar:(NSString*)markerChar
                                 renderAsFont:(UIFont*)font {
  NSError* err = nil;
  NSString* pattern = [NSString stringWithFormat:@"(\\%@([^%@]*)\\%@)", markerChar, markerChar, markerChar];
  NSRegularExpression* pairingRegex = [[NSRegularExpression alloc] initWithPattern:pattern
                                                                           options:0 error:&err];
  if(err) {
    NSLog(@"Parsing Markdown regex, error %@", [err localizedDescription]);
    return nil;
  }
  NSRange rangeWhole = NSMakeRange(0, self.length);
  NSArray<NSTextCheckingResult*> *results = [pairingRegex matchesInString:self options:0 range:rangeWhole];
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:self];
  NSUInteger rangeShift = 0;
  for(NSTextCheckingResult* resultGroup in results) {
    // range 0 is "the whole match" which means equal to first capture group because our regex is only a group
    NSRange markdownRange = [resultGroup rangeAtIndex:1]; // outer group including markdown modifiers
    markdownRange.location -= rangeShift;
    NSRange plaintextRange = [resultGroup rangeAtIndex:2]; // inner group - the plain text
    // replace the markdowned text with the inner plain text
    [attributedText replaceCharactersInRange:markdownRange withString:[self substringWithRange:plaintextRange]];
    plaintextRange.location -= rangeShift;
    // attribute the replaced text which is now in position of the original markdowned text
    [attributedText addAttribute:NSFontAttributeName
                           value:font
                           range:NSMakeRange(markdownRange.location, plaintextRange.length)];
    // the next match is shifted to left by the removed markdown tokens
    rangeShift += markdownRange.length - plaintextRange.length;
  }
  return attributedText;
}

@end
