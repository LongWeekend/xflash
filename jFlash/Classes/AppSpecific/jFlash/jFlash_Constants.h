//
//  jFlash_Constants.h
//  jFlash
//
//  Created by Mark Makdad on 10/11/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

// Talk to MMA about these - do NOT edit them
extern NSString * const LWE_CURRENT_VERSION;
extern NSString * const LWE_CURRENT_CARD_DATABASE;
extern NSString * const LWE_CURRENT_USER_DATABASE;

#if defined(LWE_JFLASH)
extern NSString * const LWE_JF_VERSION_1_0;
extern NSString * const LWE_JF_VERSION_1_1;
extern NSString * const LWE_JF_VERSION_1_2;
extern NSString * const LWE_JF_VERSION_1_3;
extern NSString * const LWE_JF_VERSION_1_4;
extern NSString * const LWE_JF_10_USER_DATABASE;
extern NSString * const LWE_JF_10_TO_11_SQL_FILENAME;
extern NSString * const LWE_JF_12_TO_13_SQL_FILENAME;
extern NSString * const LWE_JF_13_TO_14_SQL_FILENAME;
#else if defined(LWE_CFLASH)
extern NSString * const LWE_CF_VERSION_1_0;
#endif 

// PLugins
extern NSString * const LWE_DOWNLOADED_PLUGIN_PLIST;
extern NSString * const LWE_PLUGIN_SERVER_LIST;
extern NSString * const LWE_AVAILABLE_PLUGIN_PLIST;

extern NSString *const CARD_DB_KEY;       //! Dictionary key to refer to main card database
extern NSString *const FTS_DB_KEY;        //! Dictionary key to refer to FTS database filename
extern NSString *const EXAMPLE_DB_KEY;    //! Dictionary key to refer to example database filename

extern NSString *const LWE_APP_SPLASH_IMAGE; // App splash image - different between the flashes

