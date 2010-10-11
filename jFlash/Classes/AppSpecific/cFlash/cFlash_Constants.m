//
//  cFlash_Constants.m
//  jFlash
//
//  Created by Mark Makdad on 10/11/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

// This tells the whole application that we want target CFLASH, not JFLASH.
#define APP_TARGET 1

NSString * const CFLASH_VERSION_1_0 = @"1.0";

NSString * const CFLASH_CURRENT_VERSION       = @"1.0";
NSString * const CFLASH_CURRENT_CARD_DATABASE = @"cFlash-CARD-1.0.db";
NSString * const CFLASH_CURRENT_USER_DATABASE = @"cFlash.db";


// Plugin keys - DO NOT change
NSString *const CARD_DB_KEY = @"CARD_DB";
NSString *const FTS_DB_KEY = @"FTS_DB";
NSString *const EXAMPLE_DB_KEY = @"EX_DB";

// App splash image - different between the flashes
NSString * const APP_SPLASH_IMAGE = @"Default.png";
