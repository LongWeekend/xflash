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

@class SettingsViewController;

@protocol LWESettingsDelegate <NSObject>
- (void) settingWillChange:(NSString*)key;
- (BOOL) shouldSendCardChangeNotification;
- (BOOL) shouldSendChangeNotification;
- (void) settingsViewControllerWillDisappear:(SettingsViewController*)vc;
@end

@interface SettingsViewController : UITableViewController <UITableViewDelegate, UIWebViewDelegate>

- (void) iterateSetting: (NSString*) setting;

// TODO: apparently data sources aren't generally retained, but in this case it seems to make sense.  Justify this.
@property (retain) id<LWESettingsDataSource> dataSource;
@property (assign) id<LWESettingsDelegate> delegate;
@property (retain, nonatomic) NSArray *sectionArray;
@end
