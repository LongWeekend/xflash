//
//  JRUserLandingController+LWE.m
//  jFlash
//
//  Created by Ross on 4/11/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "JRUserLandingController+LWE.h"
#import "LWEUniversalAppHelpers.h"

@implementation JRUserLandingController (LWE)

- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];

  if([LWEUniversalAppHelpers isAnIPad])
  {
    self.contentSizeForViewInPopover = CGSizeMake(320, 416);
  }
  
  NSIndexPath     *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	UITableViewCell *cell =      (UITableViewCell*)[myTableView cellForRowAtIndexPath:indexPath];
	UITextField     *textField = [self getTextField:cell];
  
  /* Only make the cell's text field the first responder (and show the keyboard) in certain situations */
	if ([sessionData weShouldBeFirstResponder] && !textField.text)
		[textField becomeFirstResponder];
  
	[infoBar fadeIn];	
}


@end
