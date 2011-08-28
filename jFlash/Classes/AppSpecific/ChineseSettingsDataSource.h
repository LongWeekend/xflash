//
//  ChineseSettingsDataSource.h
//  jFlash
//
//  Created by Mark Makdad on 8/21/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsViewController.h"

@interface ChineseSettingsDataSource : NSObject <LWESettingsDataSource, LWESettingsDelegate>

@property (retain) NSDictionary *settingsHash;

@property BOOL settingsChanged;
@property BOOL directionChanged;
@property BOOL themeChanged;

@end
