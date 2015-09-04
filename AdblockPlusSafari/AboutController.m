//
//  AboutController.m
//  AdblockPlusSafari
//
//  Created by Jan Dědeček on 03/09/15.
//  Copyright © 2015 Eyeo GmbH. All rights reserved.
//

#import "AboutController.h"

@interface AboutController ()

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;

@end

@implementation AboutController

- (void)viewDidLoad
{
  [super viewDidLoad];
    // Do any additional setup after loading the view.

  self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  self.versionLabel.text = [NSString stringWithFormat:@"v%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

@end
