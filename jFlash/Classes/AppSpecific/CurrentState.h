//
//  CurrentState.h
//  jFlash
//
//  Created by Mark Makdad on 7/12/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "Tag.h"
#import "PluginManager.h"

@interface CurrentState : NSObject 
{
  //! Private property that contains the active tag
  Tag *_activeTag;
}

//! returns YES if this is the first time we have launched this app, ever
@property BOOL isFirstLoad;

//! returns YES if there is more current database than the user's current version
@property BOOL isUpdatable;

//! Holds PluginManager instance
@property (nonatomic, retain) PluginManager *pluginMgr;

+ (CurrentState *)sharedCurrentState;

- (void) initializeSettings;
- (void) registerDatabaseCopied;
- (void) resetActiveTag;

//! getter for active tag.  Loads the NSUserDefault tag from the db if not loaded yet.
- (Tag *) activeTag;

//! setter for active tag.  Sets the NSUserDefault for the tag id.
- (void) setActiveTag: (Tag*) tag;

@property (retain) Tag *favoritesTag;

@end
