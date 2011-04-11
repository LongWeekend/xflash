//
//  LWE+JRProvidersController.m
//  jFlash
//
//  Created by Ross on 4/11/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "LWE+JRProvidersController.h"
#import "LWEUniversalAppHelpers.h"
#import "LWEDebug.h"

@implementation JRProvidersController (LWE)

- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	
  if ([LWEUniversalAppHelpers isAnIPad])
  {
    self.contentSizeForViewInPopover = CGSizeMake(320, 416);
  }
  
  if ([[sessionData basicProviders] count] > 0)
  {
    [myActivitySpinner stopAnimating];
    [myActivitySpinner setHidden:YES];
    [myLoadingLabel setHidden:YES];
    
    /* Load the table with the list of providers. */
    [myTableView reloadData];    
  }
  else
  {
    LWE_LOG(@"prov count = %d", [[sessionData basicProviders] count]);
    
    /* If the user calls the library before the session data object is done initializing - 
     because either the requests for the base URL or provider list haven't returned - 
     display the "Loading Providers" label and activity spinner. 
     sessionData = nil when the call to get the base URL hasn't returned
     [sessionData.configuredProviders count] = 0 when the provider list hasn't returned */
    [myActivitySpinner setHidden:NO];
    [myLoadingLabel setHidden:NO];
    
    [myActivitySpinner startAnimating];
    
    /* Now poll every few milliseconds, for about 16 seconds, until the provider list is loaded or we time out. */
    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkSessionDataAndProviders:) userInfo:nil repeats:NO];
  }
  
  [infoBar fadeIn];
}


@end
