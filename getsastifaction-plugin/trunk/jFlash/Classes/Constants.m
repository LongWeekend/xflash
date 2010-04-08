//
//  Constants.m
//  jFlash
//
//  Created by シャロット ロス on 2/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

// Settings (also defined in header Constants.h)
NSString * const SET_SPLASH_ON       = @"ON";
NSString * const SET_SPLASH_OFF      = @"OFF";
NSString * const SET_MODE_QUIZ       = @"QUIZ";
NSString * const SET_MODE_BROWSE     = @"BROWSE";
NSString * const SET_J_TO_E          = @"JPN";
NSString * const SET_E_TO_J          = @"ENG";
NSString * const SET_THEME_FIRE      = @"FIRE";
NSString * const SET_THEME_WATER     = @"WATER";
NSString * const SET_READING_KANA    = @"KANA";
NSString * const SET_READING_ROMAJI  = @"ROMAJI";
NSString * const SET_READING_BOTH    = @"BOTH";

NSString * const APP_MODE            = @"mode";
NSString * const APP_HEADWORD        = @"headword";
NSString * const APP_READING         = @"reading";
NSString * const APP_THEME           = @"theme";
NSString * const APP_SPLASH          = @"splash";
NSString * const APP_USER            = @"user_id";


// Study View Controllers
NSString * const HTML_FOOTER = @"</div></body></html>";

NSString * const HTML_HEADER = @""
"<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>"
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' /><style>"
"body{background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:center; line-height:21px; font-size:18px; font-family:Helvetica,sanserif;} "
"dfn{ position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} "
"#container{width:245px; display:table-cell; vertical-align:middle;} "
"ol{text-align:left; width:235px; margin:0px; margin-left:27px; padding-left:10px;} "
"li{margin:0px; margin-bottom:7px; line-height:17px;} "
"span.jpn{font-size:28px;line-height:32px;} "
"##THEMECSS##</style></head>"
"<body><div id='container'>";

NSString * const RED_THEME_CSS = @"dfn{ background-color:orange; border-color:yellow; }";
NSString * const BLUE_THEME_CSS = @"dfn{ background-color:lightsteelblue; border-color:white; }";