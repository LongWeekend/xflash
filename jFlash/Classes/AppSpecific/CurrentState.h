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
#import "LWEPackageDownloader.h"

extern NSString * const LWEActiveTagDidChange;

@interface CurrentState : NSObject <LWEPackageDownloaderDelegate>

+ (CurrentState *) sharedCurrentState;

// Plugin related
+ (Plugin *) availablePluginForKey:(NSString *)key;
+ (BOOL) pluginKeyIsLoaded:(NSString *)key;
+ (BOOL)isTimeForCheckingUpdate;
- (void)checkNewPluginsAsynchronous:(BOOL)asynch notifyOnNetworkFail:(BOOL)notifyOnNetworkFail;


- (void) initializeSettings;
- (void) registerDatabaseCopied;
- (void) resetActiveTag;

//! returns YES if this is the first time we have launched this app, ever
@property BOOL isFirstLoad;

//! returns YES if there is more current database than the user's current version
@property BOOL isUpdatable;

//! Holds PluginManager instance
@property (retain) PluginManager *pluginMgr;

//! Changing this value causes lots of things to happen program-wide -- the app re-loads using the new tag
@property (retain) Tag *activeTag;

@property (retain) Tag *starredTag;

@property (retain, nonatomic) UIViewController *modalTaskViewController;

@end
