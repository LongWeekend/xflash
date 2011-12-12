//
//  CurrentState.h
//  jFlash
//
//  Created by Mark Makdad on 7/12/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tag.h"

extern NSString * const LWEActiveTagDidChange;

@interface CurrentState : NSObject

+ (CurrentState *) sharedCurrentState;

//! Initialize the NSUserDefaults on first load
- (void) initializeSettings;

//! Keeps the same tag active, but resets it.  Useful for changing the user
- (void) resetActiveTag;

//! returns YES if this is the first time we have launched this app, ever
@property BOOL isFirstLoad;

//! returns YES if there is more current database than the user's current version
@property BOOL isUpdatable;

//! Changing this value causes lots of things to happen program-wide -- the app re-loads using the new tag
@property (retain) Tag *activeTag;

//! A reference to the starred tag set -- this never changes (but its contents may!)
@property (retain) Tag *starredTag;

@end
