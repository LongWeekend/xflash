//
//  SettingsViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/17/09.
//  Copyright 2009 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "Appirater.h"

// Settings
extern NSString * const SET_MODE_QUIZ;
extern NSString * const SET_MODE_BROWSE;
extern NSString * const SET_J_TO_E;
extern NSString * const SET_E_TO_J;
extern NSString * const SET_READING_KANA;
extern NSString * const SET_READING_ROMAJI;
extern NSString * const SET_READING_BOTH;

// Different setting types
extern NSString * const APP_MODE;
extern NSString * const APP_HEADWORD;
extern NSString * const APP_READING;
extern NSString * const APP_THEME;
extern NSString * const APP_USER;

@interface SettingsViewController : UITableViewController
{
  NSMutableArray *sectionArray;
  NSDictionary *settingsDict;
  BOOL settingsChanged;
  BOOL headwordChanged;
  BOOL themeChanged;
  Appirater *appirater;
}

- (void) launchAppirater;
- (void) reloadTableData;
- (void) iterateSetting: (NSString*) setting;

@property BOOL settingsChanged;
@property BOOL headwordChanged;
@property BOOL themeChanged;
@property (retain, nonatomic) NSDictionary *settingsDict;
@property (retain, nonatomic) NSMutableArray *sectionArray;
@property (retain, nonatomic) Appirater *appirater;
@end
