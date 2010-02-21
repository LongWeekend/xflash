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
  Tag *activeSet;
  BOOL isFirstLoad;
  FMDatabase *dao;
}

@property BOOL isFirstLoad;
@property (nonatomic,retain) Tag *activeSet;
@property (nonatomic, retain) FMDatabase *dao;

+ (ApplicationSettings *)sharedApplicationSettings;

+ (UIColor*) getThemeTintColor;
+ (NSString*) getThemeName;
- (BOOL) openedDatabase;
- (BOOL) databaseFileExists;
- (void) initializeSettings;

@end
