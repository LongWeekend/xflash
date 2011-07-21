//
//  AppDelegate.m
//  jFlash
//
//  Created by Rendy Pranata on 21/07/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "jFlashAppDelegate.h"

@implementation AppDelegate

static jFlashAppDelegate *appDelegate_ = nil;

+ (jFlashAppDelegate *)delegate
{
  if (!appDelegate_)
  {
    id delegateObject = [[UIApplication sharedApplication] delegate];
    NSAssert(delegateObject != nil, @"UIApplication failed to find the AppDelegate");
    NSAssert([delegateObject isKindOfClass:[jFlashAppDelegate class]], 
             @"The delegate object retreived from the UIApplication has different class type.\nIt's not a jFlashAppDelegate type, but: %@", [jFlashAppDelegate class]);
    
    jFlashAppDelegate *appDelegate = (jFlashAppDelegate *)delegateObject; 
    appDelegate_ = [[appDelegate retain] autorelease];
  }
  return appDelegate_;
}



@end