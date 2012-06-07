//
//  UpgradeAdViewController.m
//  xFlash
//
//  Created by Mark Makdad on 6/6/12.
//  Copyright (c) 2012 Long Weekend LLC. All rights reserved.
//

#import "UpgradeAdViewController.h"
#import "LWENetworkUtils.h"

@interface UpgradeAdViewController ()
@end

@implementation UpgradeAdViewController

#pragma mark - IBAction Methods

// Default action for when the "Go to the App Store" or equivalent button is pressed
- (IBAction)appStoreBtnPressed:(id)sender
{
  LWENetworkUtils *tmpNet = [[LWENetworkUtils alloc] init];
  [tmpNet followLinkshareURL:@"http://click.linksynergy.com/fs-bin/stat?id=qGx1VSppku4&offerid=146261&type=3&subid=0&tmpid=1826&RD_PARM1=http%253A%252F%252Fitunes.apple.com%252Fus%252Fapp%252Fid380853144%253Fmt%253D8%2526uo%253D4%2526partnerId%253D30&u1=JFLASH_APP_WELCOME_MESSAGE"];
  [tmpNet release];
}

// When we want this VC to disappear
- (IBAction)dismissBtnPressed:(id)sender
{
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
