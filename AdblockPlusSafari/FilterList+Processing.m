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

#import "FilterList+Processing.h"

#import "AdblockPlus.h"

#include <yajl/yajl_parse.h>
#include <yajl/yajl_gen.h>

// Update filter list every 5 days
const NSTimeInterval DefaultFilterListsUpdateInterval = 3600*24*5;

@interface AdblockPlusProcessingContext : NSObject

@property NSUInteger mapLevel;
@property NSUInteger arrayLevel;
@property BOOL versionKeyFound;
@property BOOL expiresKeyFound;
@property BOOL rulesKeyFound;
@property NSString *version;
@property NSString *expires;
@property AdblockPlusFilterListType filterListType;

@end

@implementation AdblockPlusProcessingContext
@end

static int processNull(void *ctx)
{
  return YES;
}

static int processBoolean(void *ctx, int boolean)
{
  return YES;
}

static int processNumber(void *ctx, const char *s, size_t l)
{
  return YES;
}

static int processString(void *ctx, const unsigned char *string, size_t stringLength)
{
  AdblockPlusProcessingContext *context = (__bridge AdblockPlusProcessingContext *)ctx;

  if (context.mapLevel == 1 && context.filterListType == AdblockPlusFilterListTypeVersion2) {
    const char *terminatedString = strndup((const char *)string, stringLength);
    NSString *value = [NSString stringWithCString:terminatedString encoding:NSASCIIStringEncoding];
    if (context.versionKeyFound && !context.version) {
      context.version = value;
    }
    if (context.expiresKeyFound && !context.expires) {
      context.expires = value;
    }
      free((char *)terminatedString);
  }

  return YES;
}

static int processMapKey(void *ctx, const unsigned char *string, size_t stringLength)
{
  AdblockPlusProcessingContext *context = (__bridge AdblockPlusProcessingContext *)ctx;

  if (context.mapLevel == 1 && context.filterListType == AdblockPlusFilterListTypeVersion2) {
    if (strncmp((const char *)string, "version", stringLength) == 0) {
      context.versionKeyFound = YES;
    }
    if (strncmp((const char *)string, "expires", stringLength) == 0) {
      context.expiresKeyFound = YES;
    }
    if (strncmp((const char *)string, "rules", stringLength) == 0) {
      context.rulesKeyFound = YES;
    }
  }

  return YES;
}

static int processStartMap(void *ctx)
{
  AdblockPlusProcessingContext *context = (__bridge AdblockPlusProcessingContext *)ctx;
  context.mapLevel += 1;

  if (context.mapLevel == 1 && context.arrayLevel == 0) {
    context.filterListType = AdblockPlusFilterListTypeVersion2;
  }

  return YES;
}

static int processEndMap(void *ctx)
{
  AdblockPlusProcessingContext *context = (__bridge AdblockPlusProcessingContext *)ctx;
  context.mapLevel -= 1;
  return YES;
}

static int processStartArray(void *ctx)
{
  AdblockPlusProcessingContext *context = (__bridge AdblockPlusProcessingContext *)ctx;
  context.arrayLevel += 1;

  if (context.mapLevel == 0 && context.arrayLevel == 1) {
    context.filterListType = AdblockPlusFilterListTypeVersion1;
  }

  return YES;
}

static int processEndArray(void *ctx)
{
  AdblockPlusProcessingContext *context = (__bridge AdblockPlusProcessingContext *)ctx;
  context.arrayLevel -= 1;
  return YES;
}

static yajl_callbacks callbacks = {
  processNull,
  processBoolean,
  NULL,
  NULL,
  processNumber,
  processString,
  processStartMap,
  processMapKey,
  processEndMap,
  processStartArray,
  processEndArray
};

@implementation FilterList (Processing)

+ (BOOL)parseExpiresString:(NSString *)expires
                        to:(NSTimeInterval *)output
{
  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d+) days"
                                                                         options:NSRegularExpressionCaseInsensitive
                                                                           error:&error];
  if (error != nil) {
    return NO;
  }
  NSArray *matches = [regex matchesInString:expires
                                    options:0
                                      range:NSMakeRange(0, [expires length])];
  NSAssert([matches count] <= 1, @"There should be at most one match");
  NSTextCheckingResult *firstMatch = matches.firstObject;
  if (firstMatch == nil) {
    return NO;
  }

  *output = [[expires substringWithRange:[firstMatch range]] doubleValue] * 3600 * 24;
  return YES;
}

// Get parser error
+ (NSError *)createParserError:(yajl_handle) hand
{
  NSUInteger errorBufferLength = 512;
  uint8_t errorBuffer[errorBufferLength];
  unsigned char *error_string = yajl_get_error(hand, 1, errorBuffer, errorBufferLength);
  NSString *errorString = [[NSString alloc] initWithCString:(const char *)error_string encoding:NSASCIIStringEncoding];
  return [NSError errorWithDomain:AdblockPlusErrorDomain
                             code:0
                         userInfo:@{NSLocalizedDescriptionKey: errorString}];
}

- (BOOL)parseFilterListFromURL:(NSURL *__nonnull)input
                         error:(NSError *__nullable *__nonnull)error
{
  NSInputStream *inputStream = [NSInputStream inputStreamWithURL:input];

  yajl_handle hand = NULL;
  AdblockPlusProcessingContext *context = [[AdblockPlusProcessingContext alloc] init];
  void *contentPointer = (void *)CFBridgingRetain(context);

  @try {
    [inputStream open];

    hand = yajl_alloc(&callbacks, NULL, contentPointer);
    yajl_config(hand, yajl_allow_comments, 0);
    yajl_config(hand, yajl_dont_validate_strings, 1);

    // Read json file
    const NSUInteger inputBufferLength = 256;
    uint8_t inputBuffer[inputBufferLength];
    NSInteger read;

    while ((read = [inputStream read:inputBuffer maxLength:inputBufferLength])) {

      yajl_status status = yajl_parse(hand, inputBuffer, read);
      if (status != yajl_status_ok) {
        *error = [[self class] createParserError:hand];
        return NO;
      }
    }

    // Close parser
    yajl_status status = yajl_complete_parse(hand);
    if (status != yajl_status_ok) {
      *error = [[self class] createParserError:hand];
      return NO;
    }
  }
  @catch (NSException *exception) {
    *error = [NSError errorWithDomain:AdblockPlusErrorDomain
                                 code:0
                             userInfo:@{NSLocalizedDescriptionKey: [exception reason]}];
    return NO;
  }
  @finally {
    CFBridgingRelease(contentPointer);
    [inputStream close];
    yajl_free(hand);
  }

  if (context.filterListType == AdblockPlusFilterListTypeVersion1) {
    // Use default values for filter list of version 1
    self.version = nil;
    self.expires = DefaultFilterListsUpdateInterval;
    return YES;
  }

  // Check if filter list of version 2 contains mandatory rules key
  if (!context.rulesKeyFound) {
    return NO;
  }

  NSTimeInterval expires;
  if (!context.expiresKeyFound || ![[self class] parseExpiresString:context.expires to:&expires]) {
    expires = DefaultFilterListsUpdateInterval;
  }

  self.version = context.version;
  self.expires = expires;
  return YES;
}

@end
