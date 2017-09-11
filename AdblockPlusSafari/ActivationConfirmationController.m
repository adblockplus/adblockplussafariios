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


#import "ActivationConfirmationController.h"

#import "DialogPresenterController.h"

@interface ActivationConfirmationController ()

@property (nonatomic, weak) IBOutlet UIView *firstDialogView;
@property (nonatomic, weak) IBOutlet UIView *secondDialogView;

@end

@implementation ActivationConfirmationController

- (void)viewDidLoad
{
  [super viewDidLoad];

  BOOL error = self.adblockPlus.needsDisplayErrorDialog || self.adblockPlus.updating;
  self.firstDialogView.hidden = error;
  self.secondDialogView.hidden = !error;
}

- (IBAction)onFinishButtonTouched:(UIButton *)sender;
{
  if ([self.parentViewController respondsToSelector:@selector(fourthDialogControllerDidFinish:)]) {
    [((id)self.parentViewController) fourthDialogControllerDidFinish:self];
  }
}

@end
