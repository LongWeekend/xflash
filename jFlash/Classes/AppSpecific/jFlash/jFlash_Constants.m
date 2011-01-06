//
//  jFlash_Constants.m
//  jFlash
//
//  Created by Mark Makdad on 10/11/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

// This tells the whole application that we want target **JFLASH**, not **CFLASH**.
#define APP_TARGET 0

// Version numbers & migration constants - DO NOT CHANGE unless you know what you're doing
NSString * const JFLASH_CURRENT_VERSION       = @"1.3";
NSString * const JFLASH_CURRENT_CARD_DATABASE = @"jFlash-CARD-1.1.db";
NSString * const JFLASH_CURRENT_USER_DATABASE = @"jFlash.db";

NSString * const JFLASH_VERSION_1_0           = @"1.0";
NSString * const JFLASH_VERSION_1_1           = @"1.1";
NSString * const JFLASH_VERSION_1_2           = @"1.2";
NSString * const JFLASH_VERSION_1_3           = @"1.3";

NSString * const JFLASH_10_USER_DATABASE      = @"jFlash.db";
NSString * const JFLASH_10_TO_11_SQL_FILENAME = @"jflash_10_to_11.sql";
NSString * const JFLASH_12_TO_13_SQL_FILENAME = @"jflash_12_to_13.sql";

// Plugin keys - DO NOT change
NSString *const CARD_DB_KEY = @"CARD_DB";
NSString *const FTS_DB_KEY = @"FTS_DB";
NSString *const EXAMPLE_DB_KEY = @"EX_DB";

// App splash image - different between the flashes
NSString * const APP_SPLASH_IMAGE = @"Default.png";
