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

- (void) testInitFromHash
{
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Mark's FTS Cards",@"name",
                        @"FTS-DB",@"pluginId",
                        @"database",@"pluginType",
                        @"1.0",@"version",
                        [NSNumber numberWithInt:0],@"fileLocation",
                        @"cFlash-FTS-1.0.db",@"filePath",nil];

  // Init the plugin
  Plugin *newPlugin = [Plugin pluginWithDictionary:dict];
  
  STAssertEqualsObjects(@"Mark's Cards",newPlugin.name);
  STAssertEqualsObjects(@"FTS-DB",newPlugin.pluginId);
  STAssertEqualsObjects(@"database",newPlugin.pluginType);
  STAssertEqualsObjects(@"1.0",newPlugin.version);
  STAssertEqualsObjects(@"cFlash-FTS-1.0.db",newPlugin.filePath);
}

@end
