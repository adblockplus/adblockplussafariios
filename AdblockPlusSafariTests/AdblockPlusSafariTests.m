//
//  AdblockPlusSafariTests.m
//  AdblockPlusSafariTests
//
//  Created by Jan Dědeček on 13/10/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

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
  NSString *filename = input.lastPathComponent;
  NSURL *output = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:filename isDirectory:NO];

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


@end
