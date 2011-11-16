//
//  JRUserLandingController+LWE.h
//  jFlash
//
//  Created by Ross on 4/11/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "JRUserLandingController.h"

// Put this in here to quell the warning, it's a private method in their library
@interface JRUserLandingController()
- (UITextField*) getTextField:(UITableViewCell*)cell;
@end

@interface JRUserLandingController (LWE)

- (void)viewDidAppear:(BOOL)animated;

@end