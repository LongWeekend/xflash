//
//  Constants.m
//  jFlash
//
//  Created by シャロット ロス on 2/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//
#import "Constants.h"

// Constants to determine what app version we are building
#define APP_TARGET_JFLASH 0
#define APP_TARGET_CFLASH 1

NSString * const LWETableBackgroundImage = @"/table-background.jpg";

// Settings (also defined in header Constants.h)
NSString * const SET_MODE_QUIZ       = @"QUIZ";
NSString * const SET_MODE_BROWSE     = @"BROWSE";
NSString * const SET_J_TO_E          = @"JPN";
NSString * const SET_E_TO_J          = @"ENG";

// IF YOU CHANGE THESE VALUES, DEMONS WILL FLY OUT OF YOUR CD-ROM DRIVE AND EAT YOUR SOUL.  INSTANTLY.
// It will COMPLETELY mess up the ability of our users to upgrade versions.
NSString * const APP_MODE                 = @"mode";
NSString * const APP_THEME                = @"theme";
NSString * const APP_ALGORITHM            = @"algorithm";
NSString * const APP_USER                 = @"user_id";
NSString * const APP_HEADWORD             = @"headword";
NSString * const APP_PLUGIN               = @"plugin";
NSString * const APP_REMINDER             = @"reminder";
NSString * const APP_MAX_STUDYING         = @"maxStudying";
NSString * const APP_FREQUENCY_MULTIPLIER = @"frequency_multiplier";
NSString * const APP_DIFFICULTY           = @"app_difficulty";
NSString * const APP_DATA_VERSION         = @"data_version";
NSString * const APP_SETTINGS_VERSION     = @"settings_version";
NSString * const APP_HIDE_BURIED_CARDS    = @"app_hide_buried_cards";
NSString * const APP_HEADWORD_TYPE        = @"headword_type";
NSString * const SET_HEADWORD_TYPE_TRAD   = @"TRAD";
NSString * const SET_HEADWORD_TYPE_SIMP   = @"SIMP";


NSString * const LWEShouldSwitchTab           = @"LWEShouldSwitchTab";
NSString * const LWEShouldShowModal				    = @"LWEShouldShowModal";
NSString * const LWEShouldShowDownloadModal	  = @"LWEShouldShowDownloadModal";
NSString * const LWEShouldShowPopover         = @"LWEShouldShowPopover";


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

      // These constants are general to the flashes
      NSString * const LWE_CURRENT_VERSION       = @"1.5";
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
      NSString * const LWE_JF_VERSION_1_5           = @"1.5";
      NSString * const LWE_JF_VERSION_1_6           = @"1.6";

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

      NSString * const APP_PINYIN_COLOR             = @"pinyin_color";
      NSString * const SET_PINYIN_COLOR_ON          = @"ON";
      NSString * const SET_PINYIN_COLOR_OFF         = @"OFF";

      // Each flash has its own Tiwtter key
      NSString * const LWE_TWITTER_CONSUMER_KEY = @"2xLbYtl787ShwJBFIC1QaA";
      NSString * const LWE_TWITTER_PRIVATE_KEY  = @"AKst54TeQWdQssmKL9PZrDTmm0DyIO48iEnaZIbFmc";


      // These constants are general to the flashes
      NSString * const LWE_CURRENT_VERSION          = @"1.0";
      NSString * const LWE_CURRENT_CARD_DATABASE    = @"cFlash-CARD-1.0.db";
      NSString * const LWE_CURRENT_USER_DATABASE    = @"cFlash.db";

      // These constants are CF specific
      NSString * const LWE_CF_VERSION_1_0           = @"1.0";

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

//------------------------------------------------------------
// Everything after here can easily be changed across versions
//------------------------------------------------------------
NSString * const SENTENCES_HTML_HEADER = @""
"<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>"
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' /><style>"
"body{ background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:left; line-height:21px; font-size:16px; font-weight:bold; font-family:Helvetica,sanserif; color:#fff; text-shadow:darkslategray 0px 1px 0px; } "
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
".button{ font-size:14px; margin:2px 0px 2px 0px; padding: 2px 4px 3px 4px; display: inline; background: #777; border: none; color: #fff; font-weight: bold; border-radius: 3px; -moz-border-radius: 3px; -webkit-border-radius: 3px; text-shadow: 1px 1px #666; background: rgba(0,0,0,0.3);} "
".showWordsDiv { float: right; margin: 0px 5px 9px 9px; }"
"#container{width:315px; display:table-cell; vertical-align:middle;text-align:left;} "
"ol{color:white; text-shadow:#000 0px 1px 0px; text-align:left; width:265px; margin:0px; margin-left:19px; padding-left:10px;} "
"li{color:white; text-shadow:#000 0px 1px 0px; margin:0px; margin-bottom:17px; line-height:17px;} "
".lowlight {display:inline-block; margin-top:3px;color:#181818;text-shadow:none;font-weight:normal;} "
".readingLabel {font-size:14px;font-weight:bold; margin:3px 0px 0px 4px;} "
".headwordLabel {font-size:19px; margin:0px 0px 9px 4px;color:yellow;text-shadow:black 0px 1px 0px;} "
".ExpandedSentencesTable { width:250px; border-collapse:collapse; margin: 10px 0px 5px 0px;  } "
".AddToSetAnchor { float:right; } "
".ExpandedSentencesTable td { border-bottom:1px solid #CCC; border-collapse:collapse; border-top:1px solid #CCC } "
".HeadwordRow { height: 45px; } "
".HeadwordCell { vertical-align:middle; border-right:none; font-size:15px; width:100px; } "
".ContentCell { vertical-align:middle; border-left:none; font-size:14px; width:100px; } "
" a {text-decoration: none; } "
"##THEMECSS##</style></head>"
"<body><div id='container'>";
