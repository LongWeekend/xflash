//
//  Constants.m
//  jFlash
//
//  Created by シャロット ロス on 2/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//
#import "Constants.h"

NSString * const LWETableBackgroundImage = @"/table-background.jpg";

/*
 WARNING: Do not change any of the values of these strings.  It will break
 backwards compatibility.  The only way you would ever be allowed to do so
 is if you wrote a migration that migrated the user's setting(s) that you 
 changed.

 Note: JFlash and CFlash-specific constants are in their respective sections.
 */
NSString * const APP_MODE            = @"mode";
NSString * const SET_MODE_QUIZ       = @"QUIZ";
NSString * const SET_MODE_BROWSE     = @"BROWSE";

NSString * const APP_HEADWORD        = @"headword";
NSString * const SET_J_TO_E          = @"JPN";
NSString * const SET_E_TO_J          = @"ENG";

NSString * const APP_HEADWORD_TYPE        = @"headword_type";
NSString * const SET_HEADWORD_TYPE_TRAD   = @"TRAD";
NSString * const SET_HEADWORD_TYPE_SIMP   = @"SIMP";

NSString * const APP_TEXT_SIZE            = @"text_size";
NSString * const SET_TEXT_NORMAL          = @"normal";
NSString * const SET_TEXT_LARGE           = @"large";
NSString * const SET_TEXT_HUGE            = @"huge";

// These setting types do not have discrete set values, their setting values are
// determined in code.
NSString * const APP_THEME                = @"theme";
NSString * const APP_ALGORITHM            = @"algorithm";
NSString * const APP_USER                 = @"user_id";
NSString * const APP_PLUGIN               = @"plugin";
NSString * const APP_REMINDER             = @"reminder";
NSString * const APP_MAX_STUDYING         = @"maxStudying";
NSString * const APP_FREQUENCY_MULTIPLIER = @"frequency_multiplier";
NSString * const APP_DIFFICULTY           = @"app_difficulty";
NSString * const APP_DATA_VERSION         = @"data_version";
NSString * const APP_SETTINGS_VERSION     = @"settings_version";
NSString * const APP_HIDE_BURIED_CARDS    = @"app_hide_buried_cards";

NSString * const LWEShouldSwitchTab           = @"LWEShouldSwitchTab";
NSString * const LWEShouldShowModal				    = @"LWEShouldShowModal";
NSString * const LWEShouldShowDownloadModal	  = @"LWEShouldShowDownloadModal";


//Rendy did add this - For the plugin manager feature
NSString * const PLUGIN_LAST_UPDATE		  = @"last_update";

// Tag for "favorites" - zero, because it wasn't taken!
const NSInteger STARRED_TAG_ID = 0;

// The email address of our bad data reports
NSString * const LWE_BAD_DATA_EMAIL       = @"fix-card@longweekendmobile.com";
NSString * const LWE_SUPPORT_EMAIL        = @"support@longweekendmobile.com";

#if defined(LWE_JFLASH)
      NSString * const LWE_FLURRY_API_KEY           = @"1ZHZ39TNG7GC3VT5PSW4";
      NSString * const LWE_APP_SPLASH_IMAGE = @"Default.jpg";

      // This setting is JFlash-specific
      NSString * const APP_READING              = @"reading";
      NSString * const SET_READING_KANA    = @"KANA";
      NSString * const SET_READING_ROMAJI  = @"ROMAJI";
      NSString * const SET_READING_BOTH    = @"BOTH";

      // Each flash has its own Tiwtter key
      NSString * const LWE_TWITTER_CONSUMER_KEY = @"BGDlaaZWdjPo3oPudnIUNA";
      NSString * const LWE_TWITTER_PRIVATE_KEY  = @"1rsNXW8Oqomevvdzk4MvQ62sowLqYNKUQNQ9GgWhU";
      NSString * const LWE_TWITTER_HASH_TAG     = @"#jflash";

      // Tapjoy
      NSString * const LWE_TAPJOY_APP_ID         = @"6f0f78d1-f4bf-437b-befc-977b317f7b04";

      // These constants are general to the flashes
      NSString * const LWE_CURRENT_VERSION       = @"1.7";
      NSString * const LWE_CURRENT_CARD_DATABASE = @"jFlash-CARD-1.1.db";
      NSString * const LWE_CURRENT_USER_DATABASE = @"jFlash.db";

      // These constants are JF specific
      NSString * const LWE_JF_10_USER_DATABASE       = @"jFlash.db";
      NSString * const LWE_JF_10_TO_11_SQL_FILENAME  = @"jflash_10_to_11.sql";
      NSString * const LWE_JF_12_TO_13_SQL_FILENAME  = @"jflash_12_to_13.sql";
      NSString * const LWE_JF_13_TO_14_SQL_FILENAME  = @"jflash_13_to_14.sql";
      NSString * const LWE_JF_15_TO_16_SQL_FILENAME  = @"jflash_15_to_16.sql";
      NSString * const LWE_JF_16_TO_161_SQL_FILENAME = @"jflash_16_to_161.sql";
      NSString * const LWE_JF_161_TO_162_SQL_FILENAME = @"jflash_161_to_162.sql";
      NSString * const LWE_JF_162_TO_17_SQL_FILENAME = @"jflash_162_to_17.sql";
      NSString * const LWE_JF_VERSION_1_0           = @"1.0";
      NSString * const LWE_JF_VERSION_1_1           = @"1.1"; 
      NSString * const LWE_JF_VERSION_1_2           = @"1.2";
      NSString * const LWE_JF_VERSION_1_3           = @"1.3";
      NSString * const LWE_JF_VERSION_1_4           = @"1.4";
      NSString * const LWE_JF_VERSION_1_5           = @"1.5";
      NSString * const LWE_JF_VERSION_1_6           = @"1.6";
      NSString * const LWE_JF_VERSION_1_6_1         = @"1.6.1";
      NSString * const LWE_JF_VERSION_1_6_2         = @"1.6.2";
      NSString * const LWE_JF_VERSION_1_7           = @"1.7";

      // This pertains to the plugin manager
      NSString * const LWE_AVAILABLE_PLUGIN_PLIST   = @"jFlash-available.plist";
      NSString * const LWE_PREINSTALLED_PLUGIN_PLIST= @"jFlash-installed.plist";

      // This is here for legacy migration only, as of JFLash 1.6.
      NSString * const LWE_DOWNLOADED_PLUGIN_PLIST  = @"downloadedPlugin.plist";

// Don't use Cloudfront in development
#if defined(LWE_DEBUG)
      NSString * const LWE_PLUGIN_SERVER            = @"https://s3.amazonaws.com";
      NSString * const LWE_PLUGIN_LIST_REL_URL      = @"/japanese-flash/jFlash-available.plist";
#else
      NSString * const LWE_PLUGIN_SERVER            = @"https://d3580k8bnen6up.cloudfront.net";
      NSString * const LWE_PLUGIN_LIST_REL_URL      = @"/jFlash-available.plist";
#endif

#elif defined(LWE_CFLASH)
      NSString * const LWE_FLURRY_API_KEY           = @"CJB5CHQSQ4ZZMRS16ZJ5";
      NSString * const LWE_APP_SPLASH_IMAGE         = @"chinese-flash-splash.png";

      // Tapjoy
      NSString * const LWE_TAPJOY_APP_ID            = @"d05949e8-ab10-4039-b6f6-51ff3504084a";

      // These settings are CFlash only - pinyin coloring & tone changes
      NSString * const APP_PINYIN_COLOR             = @"pinyin_color";
      NSString * const SET_PINYIN_COLOR_ON          = @"ON";
      NSString * const SET_PINYIN_COLOR_OFF         = @"OFF";

      NSString * const APP_PINYIN_CHANGE_TONE       = @"pinyin_tone_change";
      NSString * const SET_PINYIN_CHANGE_TONE_ON    = @"ON";
      NSString * const SET_PINYIN_CHANGE_TONE_OFF   = @"OFF";


      // Each flash has its own Tiwtter key
      NSString * const LWE_TWITTER_CONSUMER_KEY = @"2xLbYtl787ShwJBFIC1QaA";
      NSString * const LWE_TWITTER_PRIVATE_KEY  = @"AKst54TeQWdQssmKL9PZrDTmm0DyIO48iEnaZIbFmc";
      NSString * const LWE_TWITTER_HASH_TAG     = @"#cflash";


      // These constants are general to the flashes
      NSString * const LWE_CURRENT_VERSION          = @"1.1.1";
      NSString * const LWE_CURRENT_CARD_DATABASE    = @"cFlash-CARD-1.0.db";
      NSString * const LWE_CURRENT_USER_DATABASE    = @"cFlash.db";

      // These constants are CF specific
      NSString * const LWE_CF_VERSION_1_0           = @"1.0";
      NSString * const LWE_CF_VERSION_1_1           = @"1.1";
      NSString * const LWE_CF_VERSION_1_1_1         = @"1.1.1";

      // Migration files
      NSString * const LWE_CF_11_TO_111_SQL_FILENAME = @"cflash_11_to_111.sql";

      //CFlash specific plugins
      NSString * const AUDIO_HSK_KEY = @"AUDIO_HSK";
      NSString * const AUDIO_PINYIN_KEY = @"AUDIO_PINYIN";

      // This pertains to the plugin manager
      NSString * const LWE_AVAILABLE_PLUGIN_PLIST   = @"cFlash-available.plist";
      NSString * const LWE_PREINSTALLED_PLUGIN_PLIST   = @"cFlash-installed.plist";
  #if defined(LWE_DEBUG)
      NSString * const LWE_PLUGIN_SERVER            = @"https://s3.amazonaws.com";
      NSString * const LWE_PLUGIN_LIST_REL_URL      = @"/chinese-flash/cFlash-available.plist";
  #else
      NSString * const LWE_PLUGIN_SERVER            = @"https://d3jxezdeu5e50q.cloudfront.net";
      NSString * const LWE_PLUGIN_LIST_REL_URL      = @"/cFlash-available.plist";
  #endif
#endif


// Plugin keys - DO NOT change
NSString * const CARD_DB_KEY = @"CARD_DB";
NSString * const FTS_DB_KEY = @"FTS_DB";
NSString * const EXAMPLE_DB_KEY = @"EX_DB";
