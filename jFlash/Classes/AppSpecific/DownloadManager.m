//
//  DownloadManager.m
//  jFlash
//
//  Created by Mark Makdad on 12/9/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "DownloadManager.h"
#import "jFlashAppDelegate.h"

@interface DownloadManager ()
@end

@implementation DownloadManager

@synthesize modalTaskViewController, pluginMgr;
@synthesize tabIconTimer, tabIconImages, tabIconIndex;

#pragma mark - Class Plumbing

- (void) dealloc
{
  [tabIconTimer release];
  [tabIconImages release];
  [modalTaskViewController release];
  [pluginMgr release];

  [super dealloc];
}

#pragma mark - LWEPackageDownloaderDelegate Methods

- (void) unpackageFinished:(LWEPackage*)package
{
  NSError *error = nil;
  Plugin *plugin = [package.userInfo objectForKey:@"plugin"];
  [self.pluginMgr installPlugin:plugin error:&error];
  if (self.modalTaskViewController.parentViewController)
  {
    [self.modalTaskViewController dismissModalViewControllerAnimated:YES];
  }
  self.modalTaskViewController = nil;
  
  [self stopTabAnimation];
}

- (void) unpackageCancelled:(LWEPackage *)package
{
  self.modalTaskViewController = nil;
}

- (void) unpackageFailed:(LWEPackage*)package withError:(NSError*)error
{
  // Don't alert the user if they cancelled/it timed out due to backgrounding
  if (error.code != ASIRequestTimedOutErrorType && error.code != ASIRequestCancelledErrorType)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Problem Installing Update",@"PluginError.AlertMsgTitle") message:error.localizedDescription];
  }
  
  if (self.modalTaskViewController.parentViewController)
  {
    [self.modalTaskViewController dismissModalViewControllerAnimated:YES];
  }
  self.modalTaskViewController = nil;
  
  [self stopTabAnimation];
}

#pragma mark - Total Hack

- (void) startTabAnimation
{
  self.tabIconTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(tabIconTimerDidFire:) userInfo:nil repeats:YES];
  self.tabIconImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"00-turning-gear.png"],[UIImage imageNamed:@"01-turning-gear.png"], [UIImage imageNamed:@"02-turning-gear.png"], nil];
  self.tabIconIndex = 0;
}

- (void) stopTabAnimation
{
  LWE_STOP_TIMER(self.tabIconTimer);
  
  // Return the icon back to the way it was.
  jFlashAppDelegate *appDelegate = (jFlashAppDelegate *)[[UIApplication sharedApplication] delegate];
  UIViewController *vc = [appDelegate.tabBarController.viewControllers objectAtIndex:SETTINGS_VIEW_CONTROLLER_TAB_INDEX];
  vc.tabBarItem.image = [UIImage imageNamed:@"20-gear2.png"];
}

- (void) tabIconTimerDidFire:(NSTimer *)timer
{
  jFlashAppDelegate *appDelegate = (jFlashAppDelegate *)[[UIApplication sharedApplication] delegate];
  UIViewController *vc = [appDelegate.tabBarController.viewControllers objectAtIndex:SETTINGS_VIEW_CONTROLLER_TAB_INDEX];
  vc.tabBarItem.image = [self.tabIconImages objectAtIndex:self.tabIconIndex];
  //  [appDelegate.tabBarController.tabBar setNeedsDisplay];
  
  self.tabIconIndex++;
  if (self.tabIconIndex == [self.tabIconImages count])
  {
    self.tabIconIndex = 0;
  }
}

- (BOOL) pluginIsDownloading
{
  return (self.modalTaskViewController != nil);
}


@end
