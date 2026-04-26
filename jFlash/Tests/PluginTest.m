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
  XCTAssertEqualObjects(@"Mark's FTS Cards",self.plugin.name,@"");
  XCTAssertEqualObjects(@"FTS-DB",self.plugin.pluginId,@"");
  XCTAssertEqualObjects(@"database",self.plugin.pluginType,@"");
  XCTAssertEqualObjects(@"1.0",self.plugin.version,@"");
  XCTAssertEqualObjects(@"cFlash-FTS-1.0.db",self.plugin.filePath,@"");
}

- (void) testFullPaths
{
  NSString *expectedPath = nil;
  
  // Documents
  expectedPath = [LWEFile createDocumentPathWithFilename:self.plugin.filePath];
  XCTAssertEqualObjects(expectedPath, self.plugin.fullPath, @"Must be equal");
  
  // Library
  self.plugin.fileLocation = LWEPluginLocationLibrary;
  expectedPath = [LWEFile createLibraryPathWithFilename:self.plugin.filePath];
  XCTAssertEqualObjects(expectedPath, self.plugin.fullPath, @"Must be equal");
  
  // Bundle
  self.plugin.fileLocation = LWEPluginLocationBundle;
  expectedPath = [LWEFile createBundlePathWithFilename:self.plugin.filePath];
  XCTAssertEqualObjects(expectedPath, self.plugin.fullPath, @"Must be equal");
  
  // Unknown value defaults to bundle
  self.plugin.fileLocation = 6543;
  expectedPath = [LWEFile createBundlePathWithFilename:self.plugin.filePath];
  XCTAssertEqualObjects(expectedPath, self.plugin.fullPath, @"Must be equal");
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
  
  XCTAssertTrue((YES == [newPlugin isNewVersionOfPlugin:self.plugin]),@"Should be YES");
  XCTAssertEqual(YES,[evenNewerPlugin isNewVersionOfPlugin:self.plugin],@"Should be YES");
  XCTAssertEqual(YES,[evenNewerPlugin isNewVersionOfPlugin:newPlugin],@"Should be YES");
  XCTAssertEqual(NO,[self.plugin isNewVersionOfPlugin:newPlugin],@"Should be YES");
  XCTAssertEqual(NO,[self.plugin isNewVersionOfPlugin:evenNewerPlugin],@"Should be YES");
}

- (void) testLooseKVC
{
  // Doesn't throw an exception even with unknown value
  XCTAssertNoThrow([self.plugin setValue:@"foo" forKey:@"fsd43dsar32"], @"This should pass");
}

- (void)testIsDatabasePlugin
{
  // setUp creates a plugin with pluginType = "database"
  XCTAssertTrue([self.plugin isDatabasePlugin], @"Plugin with type 'database' should report isDatabasePlugin YES");
}

- (void)testIsNotDirectoryPlugin
{
  XCTAssertFalse([self.plugin isDirectoryPlugin], @"Plugin with type 'database' should report isDirectoryPlugin NO");
}

- (void)testDirectoryPluginTypeDetection
{
  NSDictionary *dirDict = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"Audio Pack",        @"name",
                           @"AUDIO-DIR",         @"pluginId",
                           @"directory",         @"pluginType",
                           @"1.0",               @"version",
                           [NSNumber numberWithInt:LWEPluginLocationDocuments], @"fileLocation",
                           @"audio/",            @"filePath", nil];
  Plugin *dirPlugin = [Plugin pluginWithDictionary:dirDict];
  XCTAssertTrue([dirPlugin isDirectoryPlugin], @"Plugin with type 'directory' should report isDirectoryPlugin YES");
  XCTAssertFalse([dirPlugin isDatabasePlugin], @"Directory plugin should not report isDatabasePlugin YES");
}

- (void)testSameVersionIsNotNewer
{
  NSDictionary *sameDict = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"Same Version Plugin", @"name",
                            @"FTS-DB",              @"pluginId",
                            @"database",            @"pluginType",
                            @"1.0",                 @"version",
                            [NSNumber numberWithInt:LWEPluginLocationDocuments], @"fileLocation",
                            @"cFlash-FTS-1.0.db",   @"filePath", nil];
  Plugin *samePlugin = [Plugin pluginWithDictionary:sameDict];
  XCTAssertFalse([samePlugin isNewVersionOfPlugin:self.plugin],
                 @"A plugin with the same version should NOT be considered newer");
}

- (void)testPatchVersionIsNewer
{
  NSDictionary *patchDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"Patch Plugin",        @"name",
                             @"FTS-DB",              @"pluginId",
                             @"database",            @"pluginType",
                             @"1.0.1",               @"version",
                             [NSNumber numberWithInt:LWEPluginLocationDocuments], @"fileLocation",
                             @"cFlash-FTS-1.0.1.db", @"filePath", nil];
  Plugin *patchPlugin = [Plugin pluginWithDictionary:patchDict];
  XCTAssertTrue([patchPlugin isNewVersionOfPlugin:self.plugin],
                @"Version 1.0.1 should be newer than 1.0");
}

- (void)testPluginHasCorrectName
{
  XCTAssertEqualObjects(@"Mark's FTS Cards", self.plugin.name, @"Plugin name must match dictionary");
}

- (void)testPluginHasCorrectPluginId
{
  XCTAssertEqualObjects(@"FTS-DB", self.plugin.pluginId, @"Plugin ID must match dictionary");
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
