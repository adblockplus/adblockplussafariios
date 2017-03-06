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

#import "ActionViewController.h"
#import "AdblockPlusShared.h"
#import "NSString+AdblockPlus.h"
#import "NSAttributedString+TextRenderer.h"

#import <MobileCoreServices/MobileCoreServices.h>

@import SafariServices;

@interface ActionViewController ()

@property(strong, nonatomic) AdblockPlusShared *adblockPlus;
@property(strong, nonatomic) NSString *website;

@property(strong, nonatomic) IBOutlet UITextField *addressField;
@property(strong, nonatomic) IBOutlet UITextField *descriptionField;

@end

@implementation ActionViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.adblockPlus = [[AdblockPlusShared alloc] init];

  for (NSExtensionItem *item in self.extensionContext.inputItems) {
    for (NSItemProvider *itemProvider in item.attachments) {
      NSString *typeIdentifier = (NSString *)kUTTypePropertyList;
      if ([itemProvider hasItemConformingToTypeIdentifier:typeIdentifier]) {
        __weak typeof(self) wSelf = self;
        [itemProvider loadItemForTypeIdentifier:typeIdentifier options:nil completionHandler:^(NSDictionary *item, NSError *error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *preprocessingResults = (NSDictionary *)item;
            NSDictionary *results = preprocessingResults[NSExtensionJavaScriptPreprocessingResultsKey];
            NSString *baseURI = results[@"baseURI"];
            wSelf.website = baseURI;
            wSelf.addressField.text = [baseURI whitelistedHostname];
            wSelf.descriptionField.text = results[@"title"];
          });
        }];
      }
    }
  }
}

-(void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  [UIView transitionWithView:self.view
                    duration:0.4
                     options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionShowHideTransitionViews
                  animations:^{ self.view.hidden = NO; }
                  completion:nil];
}

#pragma mark - Action

-(IBAction)onCancelButtonTouched:(id)sender
{
  [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"" code:0 userInfo:nil]];
}

-(IBAction)onDoneButtonTouched:(id)sender
{
  if (self.website.length == 0) {
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    return;
  }
  
  NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = @"http";
  components.host = @"localhost";
  components.path = [NSString stringWithFormat:@"/invalidimage-%d.png", (int)time];
  components.query = [@"website=" stringByAppendingString:[self.website whitelistedHostname]];
  
  void(^completeAndExit)() = ^() {

    // Session must be created with new identifier, see Apple documentation:
    // https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html
    // Section - Performing Uploads and Downloads
    // Because only one process can use a background session at a time,
    // you need to create a different background session for the containing app and each of its app extensions.
    // (Each background session should have a unique identifier.)
    NSString *identifier = [self.adblockPlus generateBackgroundNotificationSessionConfigurationIdentifier];

    NSURLSession *session = [self.adblockPlus backgroundNotificationSessionWithIdentifier:identifier delegate:nil];

    // Fake URL, request will definitely fail, hopefully the invalid url will be denied by iOS itself.
    NSURL *url = components.URL;
    
    // Start download request with fake URL
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
    [task resume];

    [session finishTasksAndInvalidate];

    // Let the host application to handle the result of download task
    exit(0);
  };
  
  [self.extensionContext completeRequestReturningItems:nil completionHandler:^(BOOL expired) {
    completeAndExit();
  }];

  
  
  /*[UIView transitionWithView:self.view
                    duration:0.4
                     options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionShowHideTransitionViews
                  animations:^{ self.view.hidden = YES; }
                  completion:^(BOOL finished) {
                    dispatch_async(dispatch_get_main_queue(), completeAndExit);
                  }];*/
}


@end
