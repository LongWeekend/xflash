//
//  PluginTest.m
//  jFlash
//
//  Created by Mark Makdad on 12/2/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "PluginTest.h"
#import "Plugin.h"

@implementation PluginTest

@synthesize plugin;


- (void) testInitFromHash
{
  STAssertEqualsObjects(@"Mark's Cards",self.plugin.name);
  STAssertEqualsObjects(@"FTS-DB",self.plugin.pluginId);
  STAssertEqualsObjects(@"database",self.plugin.pluginType);
  STAssertEqualsObjects(@"1.0",self.plugin.version);
  STAssertEqualsObjects(@"cFlash-FTS-1.0.db",self.plugin.filePath);
}

- (void) testFullPaths
{
  NSString *expectedPath = nil;
  
  // Documents
  expectedPath = [LWEFile createDocumentPathWithFilename:self.plugin.filePath];
  STAssertEqualsObjects(expectedPath, self.plugin.fullPath);
  
  // Library
  self.plugin.fileLocation = LWEPluginLocationLibrary;
  expectedPath = [LWEFile createLibraryPathWithFilename:self.plugin.filePath];
  STAssertEqualsObjects(expectedPath, self.plugin.fullPath);
  
  // Bundle
  self.plugin.fileLocation = LWEPluginLocationBundle;
  expectedPath = [LWEFile createBundlePathWithFilename:self.plugin.filePath];
  STAssertEqualsObjects(expectedPath, self.plugin.fullPath);
  
  // Unknown value defaults to bundle
  self.plugin.fileLocation = 6543;
  expectedPath = [LWEFile createBundlePathWithFilename:self.plugin.filePath];
  STAssertEqualsObjects(expectedPath, self.plugin.fullPath);
  
}

#pragma mark - Setup/Teardown

- (void) setUp
{
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Mark's FTS Cards",@"name",
                        @"FTS-DB",@"pluginId",
                        @"database",@"pluginType",
                        @"1.0",@"version",
                        [NSNumber numberWithInt:LWEPluginLocationDocuments],@"fileLocation",
                        @"cFlash-FTS-1.0.db",@"filePath",nil];
  
  // Init the plugin
  self.plugin = [Plugin pluginWithDictionary:dict];
}

- (void) tearDown
{
  self.plugin = nil;
}

@end
