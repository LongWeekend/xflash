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
  STAssertEqualObjects(@"Mark's Cards",self.plugin.name);
  STAssertEqualObjects(@"FTS-DB",self.plugin.pluginId);
  STAssertEqualObjects(@"database",self.plugin.pluginType);
  STAssertEqualObjects(@"1.0",self.plugin.version);
  STAssertEqualObjects(@"cFlash-FTS-1.0.db",self.plugin.filePath);
}

- (void) testFullPaths
{
  NSString *expectedPath = nil;
  
  // Documents
  expectedPath = [LWEFile createDocumentPathWithFilename:self.plugin.filePath];
  STAssertEqualObjects(expectedPath, self.plugin.fullPath);
  
  // Library
  self.plugin.fileLocation = LWEPluginLocationLibrary;
  expectedPath = [LWEFile createLibraryPathWithFilename:self.plugin.filePath];
  STAssertEqualObjects(expectedPath, self.plugin.fullPath);
  
  // Bundle
  self.plugin.fileLocation = LWEPluginLocationBundle;
  expectedPath = [LWEFile createBundlePathWithFilename:self.plugin.filePath];
  STAssertEqualObjects(expectedPath, self.plugin.fullPath);
  
  // Unknown value defaults to bundle
  self.plugin.fileLocation = 6543;
  expectedPath = [LWEFile createBundlePathWithFilename:self.plugin.filePath];
  STAssertEqualObjects(expectedPath, self.plugin.fullPath);
}

- (void) testVersionDetection
{
  NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Mark's FTS Cards 1.1",@"name",
                        @"FTS-DB",@"pluginId",
                        @"database",@"pluginType",
                        @"1.1",@"version",
                        [NSNumber numberWithInt:LWEPluginLocationDocuments],@"fileLocation",
                        @"cFlash-FTS-1.1.db",@"filePath",nil];
  
  NSDictionary *evenNewerDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Mark's FTS Cards 1.1",@"name",
                        @"FTS-DB",@"pluginId",
                        @"database",@"pluginType",
                        @"1.2.1",@"version",
                        [NSNumber numberWithInt:LWEPluginLocationDocuments],@"fileLocation",
                        @"cFlash-FTS-1.2.1.db",@"filePath",nil];

  Plugin *newPlugin = [Plugin pluginWithDictionary:newDict];
  Plugin *evenNewerPlugin = [Plugin pluginWithDictionary:evenNewerDict];
  
  STAssertEqual(YES,[newPlugin isNewVersionOfPlugin:self.plugin]);
  STAssertEqual(YES,[evenNewerPlugin isNewVersionOfPlugin:self.plugin]);
  STAssertEqual(YES,[evenNewerPlugin isNewVersionOfPlugin:newPlugin]);
  STAssertEqual(NO,[self.plugin isNewVersionOfPlugin:newPlugin]);
  STAssertEqual(NO,[self.plugin isNewVersionOfPlugin:evenNewerPlugin]);
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
