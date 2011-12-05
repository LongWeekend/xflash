//
//  SettingsViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/17/09.
//  Copyright 2009 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const APP_ABOUT;
extern NSString * const APP_TWITTER;
extern NSString * const APP_FACEBOOK;
extern NSString * const APP_NEW_UPDATE;
extern NSString * const LWECardSettingsChanged;
extern NSString * const LWEUserSettingsChanged;

@protocol LWESettingsDataSource <NSObject>
@required
- (NSArray*) settingsArray;
- (NSDictionary*) settingsHash;
- (CGFloat) sizeForAcknowledgementsRow;
@end

@class SettingsViewController;

@protocol LWESettingsDelegate <NSObject>
- (void) settingWillChange:(NSString*)key;
- (BOOL) shouldSendCardChangeNotification;
- (BOOL) shouldSendChangeNotification;
- (void) settingsViewControllerWillDisappear:(SettingsViewController*)vc;
@end

@interface SettingsViewController : UITableViewController <UIWebViewDelegate>
- (void) updateBadgeValue;
- (void) iterateSetting: (NSString*) setting;

//! This data source is not quite a model in the traditional sense; it is retained - 100% used by this VC
@property (retain) id<LWESettingsDataSource> dataSource;
@property (assign) id<LWESettingsDelegate> delegate;
@property (retain, nonatomic) NSArray *sectionArray;
@end