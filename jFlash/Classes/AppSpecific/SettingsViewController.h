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
extern NSString * const APP_NEW_UPDATE;
extern NSString * const LWECardSettingsChanged;
extern NSString * const LWESettingsChanged;

@protocol LWESettingsDataSource <NSObject>
- (NSArray*) settingsArray;
- (NSDictionary*) settingsHash;
@end

@interface SettingsViewController : UITableViewController <UITableViewDelegate, UIWebViewDelegate>

- (void) iterateSetting: (NSString*) setting;

@property (retain) id<LWESettingsDataSource> dataSource;
@property BOOL settingsChanged;
@property BOOL directionChanged;
@property BOOL themeChanged;
@property BOOL readingChanged;
@property (retain, nonatomic) NSArray *sectionArray;
@property (retain, nonatomic) Appirater *appirater;
@end
