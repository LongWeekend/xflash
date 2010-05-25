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
