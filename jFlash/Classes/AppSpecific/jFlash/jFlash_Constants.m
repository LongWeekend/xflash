//
//  jFlash_Constants.m
//  jFlash
//
//  Created by Mark Makdad on 10/11/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#if defined(LWE_JFLASH)

  // These constants are general to the flashes
  NSString * const LWE_CURRENT_VERSION       = @"1.4";
  NSString * const LWE_CURRENT_CARD_DATABASE = @"jFlash-CARD-1.1.db";
  NSString * const LWE_CURRENT_USER_DATABASE = @"jFlash.db";

  // These constants are JF specific
  NSString * const LWE_JF_10_USER_DATABASE      = @"jFlash.db";
  NSString * const LWE_JF_10_TO_11_SQL_FILENAME = @"jflash_10_to_11.sql";
  NSString * const LWE_JF_12_TO_13_SQL_FILENAME = @"jflash_12_to_13.sql";
  NSString * const LWE_JF_13_TO_14_SQL_FILENAME = @"jflash_13_to_14.sql";
  NSString * const LWE_JF_VERSION_1_0           = @"1.0";
  NSString * const LWE_JF_VERSION_1_1           = @"1.1";
  NSString * const LWE_JF_VERSION_1_2           = @"1.2";
  NSString * const LWE_JF_VERSION_1_3           = @"1.3";
  NSString * const LWE_JF_VERSION_1_4           = @"1.4";

  // This pertains to the plugin manager
  NSString * const LWE_DOWNLOADED_PLUGIN_PLIST	= @"downloadedPlugin.plist";
  NSString * const LWE_PLUGIN_SERVER_LIST       = @"https://d3580k8bnen6up.cloudfront.net/jFlash-availablePlugins.plist"
  NSString * const LWE_AVAILABLE_PLUGIN_PLIST   = @"availablePluginForDownload.plist"

#else if defined(LWE_CFLASH)

  // These constants are general to the flashes
  NSString * const LWE_CURRENT_VERSION       = @"1.0";
  NSString * const LWE_CURRENT_CARD_DATABASE = @"cFlash-CARD-1.0.db";
  NSString * const LWE_CURRENT_USER_DATABASE = @"cFlash.db";

  // These constants are CF specific
  NSString * const LWE_CF_VERSION_1_0 = @"1.0";

  // This pertains to the plugin manager
  NSString * const LWE_DOWNLOADED_PLUGIN_PLIST	= @"cFlash_downloadedPlugin.plist";
  NSString * const LWE_PLUGIN_SERVER_LIST       = @"https://d3580k8bnen6up.cloudfront.net/cFlash-availablePlugins.plist";
  NSString * const LWE_AVAILABLE_PLUGIN_PLIST   = @"cFlash_availablePluginForDownload.plist";


#endif


// Plugin keys - DO NOT change
NSString *const CARD_DB_KEY = @"CARD_DB";
NSString *const FTS_DB_KEY = @"FTS_DB";
NSString *const EXAMPLE_DB_KEY = @"EX_DB";

// App splash image - different between the flashes
NSString * const LWE_APP_SPLASH_IMAGE = @"Default.jpg";
