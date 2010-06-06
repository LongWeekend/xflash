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
  Tag *activeTag;
  Tag *_activeTag;
  BOOL isFirstLoad;
  PluginManager *pluginMgr;
}

@property BOOL isFirstLoad;
@property (nonatomic, retain) PluginManager *pluginMgr;

+ (CurrentState *)sharedCurrentState;

- (void) initializeSettings;
- (void) _createDefaultSettings;
- (void) loadActiveTag;
- (void) resetActiveTag;
//! getter for active tag.  Loads the NSUserDefault tag from the db if not loaded yet.
- (Tag *) activeTag;
//! setter for active tag.  Sets the NSUserDefault for the tag id.
- (void) setActiveTag: (Tag*) tag;

@end
