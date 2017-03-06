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
#import "AdblockPlus+Parsing.h"
#import "NSString+AdblockPlus.h"
#import "FilterList+Processing.h"
#import "NSDictionary+FilterList.h"

@import SafariServices;

@interface AdblockPlusSafariTests : XCTestCase<NSFileManagerDelegate>

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

- (void)performMergeFilterList:(NSString *)filterList
{
  NSURL *input = [[NSBundle bundleForClass:[self class]] URLForResource:filterList withExtension:@"json"];
  NSString *fileName = input.lastPathComponent;
  NSURL *output = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:fileName isDirectory:NO];

  id websites = @[@"adblockplus.org", @"acceptableads.org"];

  NSError *error;
  if (![AdblockPlus mergeFilterListsFromURL:input
                    withWhitelistedWebsites:websites
                                      toURL:output
                                      error:&error]) {
    XCTAssert(false, @"Merging has failed: %@", [error localizedDescription]);
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
    id rules = [NSJSONSerialization JSONObjectWithStream:inputStream options:NSJSONReadingMutableContainers error:&error];
    XCTAssert(error == nil && rules != nil, @"JSON is not valid: %@", error);
    XCTAssert([rules isKindOfClass:[NSArray class]], @"Rules is not type of array.");
  }
  @catch (NSException *exception) {
    XCTAssert(false, @"Reading failed %@", exception.reason);
  }
  @finally {
    [inputStream close];
  }
}

- (void)testEmptyFilterListMergeWithWhitelistedWebsites
{
  [self performMergeFilterList:@"empty"];
}

- (void)testEasylistFilterListMergeWithWhitelistedWebsites
{
  [self performMergeFilterList:@"easylist_content_blocker"];
}

- (void)testEasylistPlusExceptionsFilterListMergeWithWhitelistedWebsites
{
  [self performMergeFilterList:@"easylist+exceptionrules_content_blocker"];
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

#pragma mark - Whitelisting

- (NSArray<NSString *> *)urls
{
  return
  @[@"https://translate.googleapis.com/translate_a/l?client=te&alpha=true&hl=en&cb=_callbacks_._0iatmzll3",
    @"https://accounts.google.com/o/oauth2/postmessageRelay?parent=http%3A%2F%2Fsimple-adblock.com#rpctoken=416116294&forcesecure=1",
    @"https://apis.google.com/_/scs/apps-static/_/js/k=oz.plusone.en_US.XhIFG_QmQdo.O/m=p1b,p1p/rt=j/sv=1/d=1/ed=1/rs=AGLTcCME3EBo6id2cVvokZvoI_1oIJFGZg/t=zcms/cb=gapi.loaded_1",
    @"http://gidnes.cz/o/fin/sph/dart-sph.png",
    @"http://bbcdn.go.cz.bbelements.com/bb/bb_codesnif.js?v=201506170712",
    @"http://bbcdn.go.cz.bbelements.com/bb/bb_one2n.113.65.77.1.js?v=201505281035",
    @"http://i.idnes.cz/15/063/w230/KRR5c2968_vybuchbustehrad.jpg",
    @"http://www.googletagmanager.com/gtm.js?id=GTM-VFBV"];
}

- (void)testWhitelistedHostname
{
  NSArray<NSString *> *urls = self.urls;

  NSArray<NSString *> *results =
  @[@"translate.googleapis.com",
    @"accounts.google.com",
    @"apis.google.com",
    @"gidnes.cz",
    @"bbcdn.go.cz.bbelements.com",
    @"bbcdn.go.cz.bbelements.com",
    @"i.idnes.cz",
    @"googletagmanager.com"];

  for (int i = 0; i < urls.count; i++) {
    XCTAssert([[urls[i] whitelistedHostname] isEqualToString:results[i]]
              , @"Hostname is not valid");
  }
}

- (void)testWhitelisting
{
  AdblockPlusExtras *adblockPlus = [[AdblockPlusExtras alloc] init];

  NSArray<NSString *> *urls = urls;

  NSArray<NSNumber *> *reuslts = @[@1, @2, @3, @4, @5, @5, @6, @7];

  adblockPlus.whitelistedWebsites = @[];

  for (int i = 0; i < urls.count; i++) {
    [adblockPlus whitelistWebsite:urls[i] index:nil];
    XCTAssert(adblockPlus.whitelistedWebsites.count == reuslts[i].intValue, @"Unexpected number of websites");
  }

  for (NSString *url in urls) {
    XCTAssert([adblockPlus.whitelistedWebsites containsObject:[url whitelistedHostname]], @"Website is not present");
  }
}

#pragma mark - BackgroundNotificationSession

- (void)testBackgroundNotificationSession
{
  AdblockPlusShared *adblockPlus = [[AdblockPlusShared alloc] init];

  NSMutableSet<NSString *> *set = [NSMutableSet set];

  int count = 10;
  for (int i = 0; i < count; i++) {
    NSString *ID = [adblockPlus generateBackgroundNotificationSessionConfigurationIdentifier];
    XCTAssert([adblockPlus isBackgroundNotificationSessionConfigurationIdentifier:ID], @"Identifier was not recognized!");
    [set addObject:ID];
  }

  // Add some tolerance, IDs are randomized, and there is very small change, that there will be at least one match.
  XCTAssert(set.count + 1 >= count, @"Identifier are not unique");
}

- (void)testEasylistFilterListMergeWithWhitelistedWebsitesV2
{
  [self performMergeFilterList:@"easylist_content_blocker_v2"];
}

- (void)testEasylistPlusExceptionsFilterListMergeWithWhitelistedWebsitesV2
{
  [self performMergeFilterList:@"easylist+exceptionrules_content_blocker_v2"];
}

- (void)testExpiresParsing
{
  NSArray *inputs =
  @[
    @[@"4 days easylist", @YES, @4],
    @[@"15 days combined", @YES, @15],
    @[@"1000 hours test", @NO],
    @[@"Expires in 1000", @NO]
    ];

  for (id input in inputs) {
    NSTimeInterval expires;
    BOOL result = [FilterList parseExpiresString:input[0] to:&expires];
    if (result) {
      XCTAssert(expires == ([input[2] doubleValue] * 3600 * 24), @"Unexpected output");
    }
    XCTAssert(result == [input[1] boolValue], @"Unexpected output");
  }
}


- (void)processFilterList:(NSString *)filterListPath
          expectedVersion:(NSString *)expectedVersion
          expectedExpires:(NSTimeInterval)expectedExpires
{
  NSURL *input = [[NSBundle bundleForClass:[self class]] URLForResource:filterListPath withExtension:@"json"];
  FilterList *filterList = [[FilterList alloc] initWithDictionary:@{}];

  NSError *error = nil;
  if (![filterList parseFilterListFromURL:input error:&error]) {
    XCTAssert(false, @"Parsing should be successful");
    return;
  }

  XCTAssert([filterList.version isEqualToString:expectedVersion] || (filterList.version == expectedVersion), @"Version should be equal");
  XCTAssert(filterList.expires == expectedExpires, @"Expires should be filled");
}

- (void)testProcessingOfEasylistPlusExceptionsFilterListsMergeWithWhitelistedWebsites
{
  [self processFilterList:@"easylist+exceptionrules_content_blocker" expectedVersion:nil expectedExpires:DefaultFilterListsUpdateInterval];
}

- (void)testProcessingOfEasylistFilterListsMergeWithWhitelistedWebsitesV2
{
  [self processFilterList:@"easylist_content_blocker_v2" expectedVersion:@"201512011207" expectedExpires:4*3600*24];
}

- (void)testProcessingOfEasylistPlusExceptionsFilterListsMergeWithWhitelistedWebsitesV2
{
  [self processFilterList:@"easylist+exceptionrules_content_blocker_v2" expectedVersion:@"201512011207" expectedExpires:4*3600*24];
}

- (void)performReloadTestWithFilterLists:(NSString *)filterLists acceptableAdsEnabled:(BOOL)acceptableAdsEnabled
{
  NSURL *input = [[NSBundle bundleForClass:[self class]] URLForResource:filterLists withExtension:@"json"];

  AdblockPlusExtras *adblockPlus = [[AdblockPlusExtras alloc] init];
  adblockPlus.enabled = YES;
  adblockPlus.acceptableAdsEnabled = acceptableAdsEnabled;

  NSString *name = adblockPlus.activeFilterListName;

  NSFileManager *fileManager = [[NSFileManager alloc] init];
  fileManager.delegate = self;

  NSURL *output = [fileManager containerURLForSecurityApplicationGroupIdentifier:adblockPlus.group];
  output = [output URLByAppendingPathComponent:adblockPlus.filterLists[name].fileName isDirectory:NO];

  NSError *error;
  if (!output || [fileManager copyItemAtURL:input toURL:output error:&error]) {
    XCTAssert(false, @"File cannot be copied: %@", error);
    return;
  }

  adblockPlus.activated = NO;

  XCTestExpectation *expectation = [self expectationWithDescription:@"Expectations for reloader"];

  // If the content blocker is requested to reload without any delay,
  // then the reloading will always end with this error:
  // 4097 "connection to service named com.apple.SafariServices.ContentBlockerLoader"
  // Delay reloading magically solve this issue.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [adblockPlus reloadWithCompletion:^(NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssert(adblockPlus.activated, @"Adblock Plus is not activated, reloading test could not be properly executed.");
        XCTAssert(!error, @"Filter lists reloading has failed: %@", error);
        [expectation fulfill];
      });
    }];
  });

  [self waitForExpectationsWithTimeout:20 handler:^(NSError * _Nullable error) {
  }];
}

- (void)testEasylistFilterListsReloading
{
  [self performReloadTestWithFilterLists:@"easylist_content_blocker_v2" acceptableAdsEnabled:NO];
}

- (void)testEasylistPlusExceptionsFilterListsReloading
{
  [self performReloadTestWithFilterLists:@"easylist+exceptionrules_content_blocker_v2" acceptableAdsEnabled:YES];
}

#pragma MARK: -

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
  if ([error code] == NSFileWriteFileExistsError) {
    return YES;
  } else {
    return NO;
  }
}

@end
