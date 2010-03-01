//
//  ApplicationSettings.h
//  jFlash
//
//  Created by Mark Makdad on 7/12/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "Tag.h"

@interface ApplicationSettings : NSObject
{
  Tag *activeTag;
  Tag *_activeTag;
  BOOL isFirstLoad;
  BOOL databaseOpenFinished;
  FMDatabase *dao;
}

@property BOOL isFirstLoad;
@property BOOL databaseOpenFinished;
@property (nonatomic, retain) FMDatabase *dao;

+ (ApplicationSettings *)sharedApplicationSettings;

+ (UIColor*) getThemeTintColor;
+ (NSString*) getThemeName;
- (BOOL) openedDatabase;
- (BOOL) databaseFileExists;
- (void) initializeSettings;
- (void) loadActiveTag;
- (BOOL) splashIsOn;
// getter for active tag.  Loads the NSUserDefault tag from the db if not loaded yet.
- (Tag *) activeTag;
// setter for active tag.  Sets the NSUserDefault for the tag id.
- (void) setActiveTag: (Tag*) tag;

@end
