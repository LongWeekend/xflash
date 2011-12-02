//
//  PluginManagerTest.m
//  jFlash
//
//  Created by Mark Makdad on 12/2/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "PluginManagerTest.h"
#import <UIKit/UIKit.h>

@implementation PluginManagerTest
@synthesize pluginMgr;

#pragma mark - Tests

- (void) testLoadPlugin
{
  
}

#pragma mark - Setup/Teardown

- (void) setUp
{
  self.pluginMgr = [[[PluginManager alloc] init] autorelease];
}

- (void) tearDown
{
  self.pluginMgr = nil;
}

@end
