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

#import "AdblockPlus+Parsing.h"

// yajl is sax-like json parser. Content blocker extension has limited amount of memory,
// so that it is not possible to load whole filter list at once.
#include <yajl/yajl_parse.h>
#include <yajl/yajl_gen.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct
{
  NSUInteger arrayLevel;
  yajl_gen g;

} AdblockPlusContext;

static int reformat_null(void *ctx)
{
  AdblockPlusContext *context = (AdblockPlusContext *)ctx;
  return yajl_gen_null(context->g) == yajl_gen_status_ok;
}

static int reformat_boolean(void *ctx, int boolean)
{
  AdblockPlusContext *context = (AdblockPlusContext *)ctx;
  return yajl_gen_bool(context->g, boolean) == yajl_gen_status_ok;
}

static int reformat_number(void *ctx, const char *s, size_t l)
{
  AdblockPlusContext *context = (AdblockPlusContext *)ctx;
  return yajl_gen_number(context->g, s, l) == yajl_gen_status_ok;
}

static int reformat_string(void *ctx, const unsigned char *stringValue, size_t stringLength)
{
  AdblockPlusContext *context = (AdblockPlusContext *)ctx;
  return yajl_gen_string(context->g, stringValue, stringLength) == yajl_gen_status_ok;
}

static int reformat_map_key(void *ctx, const unsigned char *stringValue, size_t stringLength)
{
  AdblockPlusContext *context = (AdblockPlusContext *)ctx;
  return yajl_gen_string(context->g, stringValue, stringLength) == yajl_gen_status_ok;
}

static int reformat_start_map(void *ctx)
{
  AdblockPlusContext *context = (AdblockPlusContext *)ctx;
  return yajl_gen_map_open(context->g) == yajl_gen_status_ok;
}

static int reformat_end_map(void *ctx)
{
  AdblockPlusContext *context = (AdblockPlusContext *)ctx;
  return yajl_gen_map_close(context->g) == yajl_gen_status_ok;
}

static int reformat_start_array(void *ctx)
{
  AdblockPlusContext *context = (AdblockPlusContext *)ctx;
  context->arrayLevel += 1;
  return yajl_gen_array_open(context->g) == yajl_gen_status_ok;
}

static int reformat_end_array(void *ctx)
{
  AdblockPlusContext *context = (AdblockPlusContext *)ctx;
  context->arrayLevel -= 1;
  if (context->arrayLevel == 0) {
    return YES;
  } else {
    return yajl_gen_array_close(context->g) == yajl_gen_status_ok;
  }
}

static yajl_callbacks callbacks = {
  reformat_null,
  reformat_boolean,
  NULL,
  NULL,
  reformat_number,
  reformat_string,
  reformat_start_map,
  reformat_map_key,
  reformat_end_map,
  reformat_start_array,
  reformat_end_array
};

static BOOL writeDictionary(NSDictionary<NSString *, id> *__nonnull dictionary, yajl_gen g);

static BOOL writeString(NSString *__nonnull string, yajl_gen g)
{
  const char *str = [string cStringUsingEncoding:NSUTF8StringEncoding];
  return yajl_gen_string(g, (const unsigned char *)str, strlen(str)) == yajl_gen_status_ok;
}

static BOOL writeArray(NSArray<id> *array, yajl_gen g)
{
  if (yajl_gen_array_open(g) != yajl_gen_status_ok) {
    return NO;
  }

  for (id value in array) {

    BOOL result;
    if ([value isKindOfClass:[NSDictionary class]]) {
      result = writeDictionary(value, g);
    } else if ([value isKindOfClass:[NSString class]]) {
      result = writeString(value, g);
    } else if ([value isKindOfClass:[NSArray class]]) {
      result = writeArray(value, g);
    } else {
      result = yajl_gen_null(g) == yajl_gen_status_ok;
    }

    if (!result) {
      return NO;
    }
  }

  return yajl_gen_array_close(g) == yajl_gen_status_ok;
}

static BOOL writeDictionary(NSDictionary<NSString *, id> *__nonnull dictionary, yajl_gen g)
{
  if (yajl_gen_map_open(g) != yajl_gen_status_ok) {
    return NO;
  }

  for (NSString *key in dictionary) {
    id value = dictionary[key];

    if (!writeString(key, g)) {
      return NO;
    }

    BOOL result;
    if ([value isKindOfClass:[NSDictionary class]]) {
      result = writeDictionary(value, g);
    } else if ([value isKindOfClass:[NSString class]]) {
      result = writeString(value, g);
    } else if ([value isKindOfClass:[NSArray class]]) {
      result = writeArray(value, g);
    } else {
      result = yajl_gen_null(g) == yajl_gen_status_ok;
    }

    if (!result) {
      return NO;
    }
  }

  return yajl_gen_map_close(g) == yajl_gen_status_ok;
}



@implementation AdblockPlus (Parsing)

+ (BOOL)mergeFilterListsFromURL:(NSURL *__nonnull)input
        withWhitelistedWebsites:(NSArray<NSString *> *__nonnull)whitelistedWebsites
                          toURL:(NSURL *__nonnull)output
                          error:(NSError *__nullable *__nonnull)error
{

  NSInputStream *inputStream = [NSInputStream inputStreamWithURL:input];
  NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:output append:NO];
  yajl_gen g = NULL;
  yajl_handle hand = NULL;
  AdblockPlusContext context = { 0, NULL };

  @try {
    [inputStream open];
    [outputStream open];
    g = yajl_gen_alloc(NULL);
    yajl_gen_config(g, yajl_gen_beautify, 0);
    yajl_gen_config(g, yajl_gen_validate_utf8, 0);
    hand = yajl_alloc(&callbacks, NULL, (void *)&context);
    yajl_config(hand, yajl_allow_comments, 0);
    yajl_config(hand, yajl_dont_validate_strings, 1);
    context.g = g;

    // Write buffer to output stream
    BOOL(^writeBuffer)(yajl_gen g) = ^BOOL(yajl_gen g) {
      NSUInteger outputBufferLength;
      const uint8_t *outputBuffer;
      yajl_gen_get_buf(g, &outputBuffer, &outputBufferLength);
      if (outputBufferLength > 0) {
        NSInteger written = [outputStream write:outputBuffer maxLength:outputBufferLength];
        if (written == -1) {
          *error = outputStream.streamError;
          return NO;
        }
      }
      yajl_gen_clear(g);
      return true;
    };

    // Get parser error
    NSError *(^getParseError)(yajl_handle hand) = ^NSError *(yajl_handle hand) {
      NSUInteger errorBufferLength = 256;
      uint8_t errorBuffer[errorBufferLength];
      unsigned char *error_string = yajl_get_error(hand, 1, errorBuffer, errorBufferLength);
      NSString *errorString = [[NSString alloc] initWithCString:(const char *)error_string encoding:NSASCIIStringEncoding];
      return [NSError errorWithDomain:AdblockPlusErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: errorString}];
    };

    // Read json file
    const NSUInteger inputBufferLength = 256;
    uint8_t inputBuffer[inputBufferLength];
    NSInteger read;

    while ((read = [inputStream read:inputBuffer maxLength:inputBufferLength])) {

      yajl_status status = yajl_parse(hand, inputBuffer, read);
      if (status != yajl_status_ok) {
        *error = getParseError(hand);
        return NO;
      }

      if (!writeBuffer(g)) {
        return NO;
      }
    }

    // Close parser
    yajl_status status = yajl_complete_parse(hand);
    if (status != yajl_status_ok) {
      *error = getParseError(hand);
      return NO;
    }

    // Write whitelisted websites
    for (__strong NSString *website in whitelistedWebsites) {

      NSDictionary *whitelistingRule =
      @{@"trigger": @{ @"url-filter": @".*", @"if-domain": @[website]},
        @"action": @{ @"type": @"ignore-previous-rules" }
        };

      if (!writeDictionary(whitelistingRule, g)) {
        *error = getParseError(hand);
        return NO;
      }

      if (!writeBuffer(g)) {
        return NO;
      }
    }

    if (yajl_gen_array_close(g) != yajl_gen_status_ok) {
      *error = getParseError(hand);
      return NO;
    }

    if (!writeBuffer(g)) {
      return NO;
    }
  }
  @catch (NSException *exception) {
    *error = [NSError errorWithDomain:AdblockPlusErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [exception reason]}];
    return NO;
  }
  @finally {
    [inputStream close];
    [outputStream close];
    yajl_gen_free(g);
    yajl_free(hand);
  }

  return true;
}

@end
