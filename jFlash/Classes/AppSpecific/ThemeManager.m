//
//  jFlash
//
//  Created by Mark Makdad on 5/31/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "ThemeManager.h"
#import "SynthesizeSingleton.h"

// Theme configuration names
NSString * const SET_THEME_FIRE      = @"FIRE";
NSString * const SET_THEME_WATER     = @"WATER";
NSString * const SET_THEME_FOREST    = @"FOREST";
NSString * const SET_THEME_TAME      = @"TAME";
NSString * const DEFAULT_THEME       = @"FIRE";

//! Manages themes and returns values depending on current user theme
@implementation ThemeManager

@synthesize themes;

SYNTHESIZE_SINGLETON_FOR_CLASS(ThemeManager);

//! Initialize theme manager (defines all themes as well)
- (id) init
{
  if ((self = [super init]))
  {
    // Defines the Fire Red theme tint values & CSS
    NSDictionary *fire = [NSDictionary dictionaryWithObjectsAndKeys:
                          SET_THEME_FIRE,@"key",
                          @"Fire",@"name",
                          @"red",@"filename",
                          [NSNumber numberWithFloat:0.753],@"R",
                          [NSNumber numberWithFloat:0.105],@"G",
                          [NSNumber numberWithFloat:0.000],@"B",
                          @"cd4833",@"WEB_SELECTED",
                          @"dfn, button { background-color:orange; border-color:yellow; }",@"CSS",
                          nil];
    
    // Defines the Blue Water theme tint values & CSS
    NSDictionary *water = [NSDictionary dictionaryWithObjectsAndKeys:
                           SET_THEME_WATER,@"key",
                           @"Water",@"name",
                           @"blue",@"filename",
                           [NSNumber numberWithFloat:0.075],@"R",
                           [NSNumber numberWithFloat:0.337],@"G",
                           [NSNumber numberWithFloat:0.655],@"B",
                           @"4278b9",@"WEB_SELECTED",
                           @"dfn { background-color:lightsteelblue; border-color:white; }",@"CSS",
                           nil];
    
    
//    // Defines the Forest Green theme tint values & CSS
//    NSDictionary *forest = [NSDictionary dictionaryWithObjectsAndKeys:
//                            SET_THEME_FOREST,@"key",
//                            @"Forest",@"name",
//                            @"green",@"filename",
//                            [NSNumber numberWithFloat:74.0f/255.0f],@"R",
//                            [NSNumber numberWithFloat:170/255.0f],@"G",
//                            [NSNumber numberWithFloat:15/255.0f],@"B",
//                            @"6BBA70",@"WEB_SELECTED",
//                            @"dfn{ background-color:white; border-color:gray; }",@"CSS",
//                            nil];

    // Defines the (Joseph) Tame theme tint values & CSS
    NSDictionary *tame = [NSDictionary dictionaryWithObjectsAndKeys:
                          SET_THEME_TAME,@"key",
                          @"Tame",@"name",
                          @"tame",@"filename",
                          [NSNumber numberWithFloat:0.427],@"R",
                          [NSNumber numberWithFloat:0.518],@"G",
                          [NSNumber numberWithFloat:0.635],@"B",
                          @"cbd6eb",@"WEB_SELECTED",
                          @"dfn { background-color:silver; border-color:darkslategray; }",@"CSS",
                          nil];


    // Compiles theme dictionaries into a single dictionary keyed on the theme name
    [self setThemes:[NSDictionary dictionaryWithObjectsAndKeys:fire,SET_THEME_FIRE,water,SET_THEME_WATER,tame,SET_THEME_TAME,nil]];
  }
  return self;  
}

//! Returns the current theme - private method
- (NSDictionary*) _currentTheme
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if ([settings objectForKey:APP_THEME] != nil)
  {
    // We have theme no problem
    return [[self themes] objectForKey:[settings objectForKey:APP_THEME]];
  }
  else
  {
    // No default set, first load?
    return [[self themes] objectForKey:DEFAULT_THEME];
  }

}


/**
 * Returns the current theme's tint color as a UIColor
 */
- (UIColor*) currentThemeTintColor
{
  // Calling currentThemeTintColor:(float)customAlpha
  return [self currentThemeTintColor:0.8f];
}

/**
 * Returns the current theme's tint color as a UIColor
 */
- (UIColor*) currentThemeTintColor:(float)customAlpha
{
  NSDictionary* tm = [self _currentTheme];
  return [UIColor colorWithRed:[[tm objectForKey:@"R"] floatValue] green:[[tm objectForKey:@"G"] floatValue] blue:[[tm objectForKey:@"B"] floatValue] alpha:customAlpha];
}  


/**
 * Returns the current theme's name
 */
- (NSString*) currentThemeName
{
  NSDictionary *tm = [self _currentTheme];
  return [tm objectForKey:@"name"];
}


/**
 * Returns the current theme's file extension name (for dynamic loading)
 */
- (NSString*) currentThemeFileName
{
  NSDictionary *tm = [self _currentTheme];
  return [tm objectForKey:@"filename"];
}


/**
 * Returns the current theme's CSS for card meaning
 */
- (NSString*) currentThemeCSS
{
  NSDictionary *tm = [self _currentTheme];
  return [tm objectForKey:@"CSS"];
}


/**
 * Returns the current theme's HTML color for selected text in UIWebKit
 */
- (NSString*) currentThemeWebSelectionColor
{
  NSDictionary* tm = [self _currentTheme];
  return [tm objectForKey:@"WEB_SELECTED"];
}


/**
 * Depending on element type, returns stylized code (this is one stage of a two stage refactor)
 */
- (NSString*) elementWithCurrentTheme:(NSString*)element
{
  // TODO: iPad customization!
  return [NSString stringWithFormat:@"/%@theme-cookie-cutters/%@",[self currentThemeFileName],element];
}


//! Provide list of names for all available themes
- (NSArray*) themeNameList
{
  return [self _themeListWithKey:@"name"];
}


//! Provide dictionary-safe key reference names for all available themes
- (NSArray*) themeKeysList
{
  return [self _themeListWithKey:@"key"];
}


//! Generalized enumerator that generates array of "key" by each theme
- (NSArray*) _themeListWithKey:(NSString*)key
{
  NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
  NSDictionary *tmpDict;
  NSEnumerator *themeEnumerator = [[self themes] objectEnumerator];
  while ((tmpDict = [themeEnumerator nextObject]))
  {
    [tmpArray addObject:[tmpDict objectForKey:key]];
  }
  NSArray *returnVal = [NSArray arrayWithArray:tmpArray];
  [tmpArray release];
  return returnVal;
}
         
    
//! Dealloc to get rid of themes dictionary
- (void) dealloc
{
  [super dealloc];
  [self setThemes:nil];
}
@end
