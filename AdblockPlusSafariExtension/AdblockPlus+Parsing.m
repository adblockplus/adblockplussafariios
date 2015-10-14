//
//  AdblockPlus+Parsing.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 14/10/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "AdblockPlus+Parsing.h"

#include <yajl/yajl_parse.h>
#include <yajl/yajl_gen.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct
{
  NSUInteger array_level;
  yajl_gen g;

} adblock_plus_context;

static int reformat_null(void *ctx)
{
  adblock_plus_context *context = (adblock_plus_context *)ctx;
  return yajl_gen_status_ok == yajl_gen_null(context->g);
}

static int reformat_boolean(void *ctx, int boolean)
{
  adblock_plus_context *context = (adblock_plus_context *)ctx;
  return yajl_gen_status_ok == yajl_gen_bool(context->g, boolean);
}

static int reformat_number(void *ctx, const char *s, size_t l)
{
  adblock_plus_context *context = (adblock_plus_context *)ctx;
  return yajl_gen_status_ok == yajl_gen_number(context->g, s, l);
}

static int reformat_string(void *ctx, const unsigned char * stringVal, size_t stringLen)
{
  adblock_plus_context *context = (adblock_plus_context *)ctx;
  return yajl_gen_status_ok == yajl_gen_string(context->g, stringVal, stringLen);
}

static int reformat_map_key(void *ctx, const unsigned char * stringVal, size_t stringLen)
{
  adblock_plus_context *context = (adblock_plus_context *)ctx;
  return yajl_gen_status_ok == yajl_gen_string(context->g, stringVal, stringLen);
}

static int reformat_start_map(void *ctx)
{
  adblock_plus_context *context = (adblock_plus_context *)ctx;
  return yajl_gen_status_ok == yajl_gen_map_open(context->g);
}

static int reformat_end_map(void *ctx)
{
  adblock_plus_context *context = (adblock_plus_context *)ctx;
  return yajl_gen_status_ok == yajl_gen_map_close(context->g);
}

static int reformat_start_array(void *ctx)
{
  adblock_plus_context *context = (adblock_plus_context *)ctx;
  context->array_level += 1;
  return yajl_gen_status_ok == yajl_gen_array_open(context->g);
}

static int reformat_end_array(void *ctx)
{
  adblock_plus_context *context = (adblock_plus_context *)ctx;
  context->array_level -= 1;
  if (context->array_level == 0) {
    return YES;
  } else {
    return yajl_gen_status_ok == yajl_gen_array_close(context->g);
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

static BOOL writeString(NSString *__nonnull string, yajl_gen g)
{
  const char *str = [string cStringUsingEncoding:NSUTF8StringEncoding];
  return yajl_gen_status_ok == yajl_gen_string(g, str, strlen(str));
}


static BOOL writeDictionary(NSDictionary<NSString *, id> *__nonnull dictionary, yajl_gen g)
{
  if (yajl_gen_status_ok != yajl_gen_map_open(g)) {
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
    } else {
      result = yajl_gen_status_ok == yajl_gen_null(g);
    }

    if (!result) {
      return NO;
    }
  }

  return yajl_gen_status_ok == yajl_gen_map_close(g);
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
  adblock_plus_context context = { 0, NULL };

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

    BOOL(^writeBuffer)(yajl_gen g) = ^BOOL(yajl_gen g) {
      NSUInteger outputBufferLength;
      const uint8_t *outputBuffer;
      yajl_gen_get_buf(g, &outputBuffer, &outputBufferLength);
      if (outputBufferLength > 0) {
        NSInteger written = [outputStream write:outputBuffer maxLength:outputBufferLength];
        if (written == -1) {
          NSLog(@"%lu %@", (unsigned long)outputStream.streamStatus, outputStream.streamError);
          return NO;
        }
      }
      yajl_gen_clear(g);
      return true;
    };

    NSError *(^getParseError)(yajl_handle hand) = ^NSError *(yajl_handle hand) {
      NSUInteger errorBufferLength = 256;
      uint8_t errorBuffer[errorBufferLength];
      unsigned char *error_string = yajl_get_error(hand, 1, errorBuffer, errorBufferLength);
      NSString *errorString = [[NSString alloc] initWithCString:error_string encoding:NSASCIIStringEncoding];
      return [NSError errorWithDomain:AdblockPlusErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: errorString}];
    };

    // Read json file

    const NSUInteger inputBufferLength = 256;
    uint8_t inputBuffer[inputBufferLength];
    NSInteger read;

    while ((read = [inputStream read:inputBuffer maxLength:inputBufferLength]) != 0) {

      yajl_status stat = yajl_parse(hand, inputBuffer, read);
      if (stat != yajl_status_ok) {
        *error = getParseError(hand);
        return NO;
      }

      if (!writeBuffer(g)) {
        return NO;
      }
    }

    yajl_status stat = yajl_complete_parse(hand);
    if (stat != yajl_status_ok) {
      *error = getParseError(hand);
      return NO;
    }

    // Write white whitelisted websites

    for (__strong NSString *website in whitelistedWebsites) {
      website = [website stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
      NSDictionary *dictionary =
      @{@"trigger":
          @{
            @"url-filter": website,
            },
        @"action":
          @{
            @"type": @"ignore-previous-rules"
            }};

      if (!writeDictionary(dictionary, g)) {
        *error = getParseError(hand);
        return NO;
      }

      if (!writeBuffer(g)) {
        return NO;
      }
    }

    if (yajl_gen_status_ok != yajl_gen_array_close(g)) {
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
