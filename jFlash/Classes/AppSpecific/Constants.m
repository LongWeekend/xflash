//
//  Constants.m
//  jFlash
//
//  Created by シャロット ロス on 2/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//
#import "Constants.h"

// Version numbers & migration constants - DO NOT CHANGE unless you know what you're doing
NSString * const JFLASH_CURRENT_VERSION       = @"1.1";
NSString * const JFLASH_CURRENT_CARD_DATABASE = @"jFlash-CARD-1.1.db";
NSString * const JFLASH_CURRENT_USER_DATABASE = @"jFlash.db";

NSString * const JFLASH_VERSION_1_0           = @"1.0";
NSString * const JFLASH_VERSION_1_1           = @"1.1";
NSString * const JFLASH_10_USER_DATABASE      = @"jFlash.db";
NSString * const JFLASH_10_TO_11_SQL_FILENAME = @"jflash_10_to_11.sql";

NSString * const JFLASH_11_CARD_DATABASE      = @"jFlash-CARD-1.1.db";
NSString * const JFLASH_11_USER_DATABASE      = @"jFlash.db";

// Plugin keys - DO NOT change
NSString *const CARD_DB_KEY = @"CARD_DB";
NSString *const FTS_DB_KEY = @"FTS_DB";
NSString *const EXAMPLE_DB_KEY = @"EX_DB";

// Settings (also defined in header Constants.h)
NSString * const SET_MODE_QUIZ       = @"QUIZ";
NSString * const SET_MODE_BROWSE     = @"BROWSE";
NSString * const SET_J_TO_E          = @"JPN";
NSString * const SET_E_TO_J          = @"ENG";

NSString * const SET_READING_KANA    = @"KANA";
NSString * const SET_READING_ROMAJI  = @"ROMAJI";
NSString * const SET_READING_BOTH    = @"BOTH";

// IF YOU CHANGE THESE VALUES, DEMONS WILL FLY OUT OF YOUR CD-ROM DRIVE AND EAT YOUR SOUL.  INSTANTLY.
// It will COMPLETELY mess up the ability of our users to upgrade versions.
NSString * const APP_MODE                 = @"mode";
NSString * const APP_HEADWORD             = @"headword";
NSString * const APP_READING              = @"reading";
NSString * const APP_THEME                = @"theme";
NSString * const APP_USER                 = @"user_id";
NSString * const APP_PLUGIN               = @"plugin";
NSString * const APP_MAX_STUDYING         = @"maxStudying";
NSString * const APP_FREQUENCY_MULTIPLIER = @"frequency_multiplier";
NSString * const APP_DIFFICULTY           = @"app_difficulty";
NSString * const APP_DATA_VERSION         = @"data_version";
NSString * const APP_SETTINGS_VERSION     = @"settings_version";

//------------------------------------------------------------
// Everything after here can easily be changed across versions
//------------------------------------------------------------

// Study View Controllers
NSString * const HTML_FOOTER = @"</div></body></html>";

NSString * const HTML_HEADER = @""
"<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>"
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' /><style>"
"body{background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:center; line-height:21px; font-size:16px; font-family:Helvetica,sanserif;} "
"dfn{ position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
"#container{width:300px; display:table-cell; vertical-align:middle;text-align:center;} "
"ol{text-align:left; width:235px; margin:0px; margin-left:24px; padding-left:10px;} "
"li{margin:0px; margin-bottom:7px; line-height:17px;} "
"span.jpn{font-size:28px;padding-left:16px; line-height:32px;} "
"##THEMECSS##</style></head>"
"<body><div id='container'>";

NSString * const SENTENCES_HTML_HEADER = @""
"<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>"
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' /><style>"
"body{background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:center; line-height:21px; font-size:16px; font-family:Helvetica,sanserif;} "
"dfn{ position:relative; top:-1px; font-family:verdana; font-size:10px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
"#container{width:310px; display:table-cell; vertical-align:middle;text-align:center;} "
"ol{text-align:left; width:235px; margin:0px; margin-left:24px; padding-left:10px; color:black;} "
"li{margin:0px; margin-bottom:12px; line-height:20px;} "
"##THEMECSS##</style></head>"
"<body><div id='container'>";
