//
//  Created by Mark Makdad on 5/31/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const SET_THEME_FIRE;
extern NSString * const SET_THEME_WATER;
extern NSString * const SET_THEME_TAME;
extern NSString * const DEFAULT_THEME;

@interface ThemeManager : NSObject

+ (ThemeManager*) sharedThemeManager;
- (UIColor*) currentThemeTintColor;
- (UIColor*) currentThemeTintColor:(float)customAlpha;
- (NSString*) currentThemeFileName;
- (NSString*) currentThemeName;
- (NSString*) currentThemeCSS;
- (NSString*) currentThemeWebSelectionColor;
- (NSString*) elementWithCurrentTheme:(NSString*)element;
- (NSDictionary*) _currentTheme;
- (NSArray*) _themeListWithKey:(NSString*)key;

//! Provide list of names of all available themes
- (NSArray*) themeNameList;

//! Provide dictionary-safe key reference names for all available themes
- (NSArray*) themeKeysList;

//! Holds themes dictionary
@property (nonatomic, retain) NSDictionary *themes;

@end
