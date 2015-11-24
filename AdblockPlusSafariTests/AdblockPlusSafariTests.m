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

#import <XCTest/XCTest.h>

#import "AdblockPlusExtras.h"
#import "AdblockPlus+Extension.h"
#import "AdblockPlus+Parsing.h"

@interface AdblockPlusSafariTests : XCTestCase

@end

@implementation AdblockPlusSafariTests

- (void)setUp
{
  [super setUp];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)performMergeFilterlists:(NSString *)filterlists
{
  NSURL *input = [[NSBundle bundleForClass:[self class]] URLForResource:filterlists withExtension:@"json"];
  NSString *fileName = input.lastPathComponent;
  NSURL *output = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:fileName isDirectory:NO];

  id websites = @[@"adblockplus.org", @"acceptableads.org"];

  NSError *error;
  if (![AdblockPlus mergeFilterListsFromURL:input
                    withWhitelistedWebsites:websites
                                      toURL:output
                                      error:&error]) {
    XCTAssert(false, @"Marging has failed: %@", [error localizedDescription]);
    return;
  }

  if (![[NSFileManager defaultManager] fileExistsAtPath:output.path]) {
    XCTAssert(false, @"File doesn't exist!");
    return;
  }

  NSInputStream *inputStream = [NSInputStream inputStreamWithURL:output];
  @try {
    [inputStream open];
    NSError *error;
    [NSJSONSerialization JSONObjectWithStream:inputStream options:NSJSONReadingMutableContainers error:&error];
    XCTAssert(error == nil, @"JSON is not valid: %@", error);
  }
  @catch (NSException *exception) {
    XCTAssert(false, @"Reading failed %@", exception.reason);
  }
  @finally {
    [inputStream close];
  }
}

- (void)testEmptyFilterListsMergeWithWhitelistedWebsites
{
  [self performMergeFilterlists:@"empty"];
}

- (void)testEasylistFilterListsMergeWithWhitelistedWebsites
{
  [self performMergeFilterlists:@"easylist_content_blocker"];}

- (void)testEasylistPlusExceptionsFilterListsMergeWithWhitelistedWebsites
{
  [self performMergeFilterlists:@"easylist+exceptionrules_content_blocker"];
}

- (void)testHostnameEscaping
{
  NSDictionary<NSString *, NSString *> *input =
  @{@"a.b.c.d": @"a\\.b\\.c\\.d",
    @"[|(){^$*+?.<>[]": @"\\[\\|\\(\\)\\{\\^\\$\\*\\+\\?\\.\\<\\>\\[\\]"
    };

  for (NSString *key in input) {
    id result = [AdblockPlus escapeHostname:key];
    XCTAssert([input[key] isEqualToString:result], @"Hostname is not escaped!");
  }
}


@end
