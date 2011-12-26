//
//  JFlashPluginMigrationTest.m
//  jFlash
//
//  Created by Mark Makdad on 12/11/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "JFlashPluginMigrationTest.h"
#import "Plugin.h"

/**
 * THIS CLASS TESTS THE 1.5=>1.6 JFLASH MIGRATION
 * OF PLUGINS FROM DOCS DIR PLIST+SETTINGS TO SETTINGS ONLY.
 */
@implementation JFlashPluginMigrationTest

- (void) testParseLegacyPlugin
{
  NSDictionary *legacyPluginHash = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"FTS-DB",@"plugin_key",
                                    @"1.1",@"plugin_version",
                                    @"my awesome plugin",@"plugin_name",
                                    @"some details about my awesome plugin",@"plugin_details",
                                    @"<html> some html here </html>",@"plugin_html_content",
                                    @"localfilename.db",@"plugin_target_path",
                                    @"THIS VALUE SHOULD NOT MAKE US CRASH",@"some_unknown_key_we_dont_use_now",
                                    @"http://yourmom.com/backdoor.php",@"plugin_target_url",
                                    @"localfilename.db",@"plugin_file_name",
                                    nil];
  Plugin *newPlugin = [Plugin pluginWithLegacyDictionary:legacyPluginHash];
  
  STAssertEqualObjects([legacyPluginHash objectForKey:@"plugin_key"], newPlugin.pluginId, @"Should be equal");
  STAssertEqualObjects([legacyPluginHash objectForKey:@"plugin_name"], newPlugin.name, @"Should be equal");
  STAssertEqualObjects([legacyPluginHash objectForKey:@"plugin_details"], newPlugin.details, @"Should be equal");
  STAssertEqualObjects([legacyPluginHash objectForKey:@"plugin_html_content"], newPlugin.htmlString, @"Should be equal");
  STAssertEqualObjects([legacyPluginHash objectForKey:@"plugin_version"], newPlugin.version, @"Should be equal");
  STAssertEqualObjects([legacyPluginHash objectForKey:@"plugin_target_url"], newPlugin.targetURL, @"Should be equal");
  STAssertEqualObjects([legacyPluginHash objectForKey:@"plugin_target_path"], newPlugin.filePath, @"Should be equal");
  
  // Default to "Documents" for file location (this is a new feature)
  STAssertEquals(kLWEFileLocationDocuments, newPlugin.fileLocation, @"Should be equal");
  
  // Default to "database" type, this is a new feature
  STAssertEqualObjects(@"database", newPlugin.pluginType, @"Should be equal");
}

@end
