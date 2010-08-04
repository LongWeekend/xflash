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
#import "AlgorithmSettingsViewController.h"

extern NSString * const APP_ABOUT;
extern NSString * const APP_TWITTER;
extern NSString * const APP_FACEBOOK;

@interface SettingsViewController : UIViewController <UITableViewDelegate, UIWebViewDelegate>
{
	UITableView *tblView;
	UIButton *btnNewUpdate;
  NSMutableArray *sectionArray;
  NSDictionary *settingsDict;
  BOOL settingsChanged;
  BOOL headwordChanged;
  BOOL themeChanged;
  BOOL readingChanged;
  Appirater *appirater;
}

- (void) iterateSetting: (NSString*) setting;
- (NSMutableArray*) _settingsTableDataSource;
- (void) _openPluginSettingstVC;

- (IBAction) btnNewUpdate_Clicked:(id) sender;

@property BOOL settingsChanged;
@property BOOL headwordChanged;
@property BOOL themeChanged;
@property BOOL readingChanged;
@property (retain, nonatomic) NSDictionary *settingsDict;
@property (retain, nonatomic) NSMutableArray *sectionArray;
@property (retain, nonatomic) Appirater *appirater;
@property (retain, nonatomic) IBOutlet UITableView *tblView;
@property (retain, nonatomic) IBOutlet UIButton *btnNewUpdate;
@end
