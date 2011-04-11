//
//  JRWebViewController+LWE.m
//  jFlash
//
//  Created by Ross on 4/11/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "JRWebViewController+LWE.h"
#import "LWEUniversalAppHelpers.h"

@implementation JRWebViewController (LWE)

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  
  if ([LWEUniversalAppHelpers isAnIPad])
  {
    self.contentSizeForViewInPopover = CGSizeMake(320, 416);
  }
  
  self.title = [NSString stringWithFormat:@"%@", (sessionData.currentProvider) ? sessionData.currentProvider.friendlyName : @"Loading"];
}

@end
