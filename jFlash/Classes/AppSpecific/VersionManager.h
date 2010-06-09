//
//  VersionMigrater.h
//  jFlash
//
//  Created by Mark Makdad on 6/6/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LWEDownloader.h"
#import "ModalTaskViewController.h"

/** State machine for the migrater */
typedef enum _migraterStates
{
  kMigraterReady,                   //! Ready to go
  kMigraterCancelled,               //! Migrater cancelled
  kMigraterOpenDatabase,            //! Open old version database
  kMigraterAttachPlugins,           //! Attach any plugins
  kMigraterDownloadPlugins,         //! Download plugins
  kMigraterDownloadPaused,          //! Download is paused
  kMigraterDownloadFail,            //! Failed to download
  kMigraterUpdateSQL,               //! Updating SQL
  kMigraterUpdateSQLFail,           //! Failed to update SQL
  kMigraterUnknownFail,             //! God help us lest we get here
  kMigraterSuccess                  //! User has upgraded successfully
} migraterStates;

@interface VersionManager : NSObject <ModalTaskViewDelegate>
{
  LWEDownloader *dlHandler;
  float _progress;
  NSString *taskMessage;
  NSString *statusMessage;
  NSInteger _migraterState;
  NSAutoreleasePool *_backgroundThreadPool;
  BOOL _cancelRequest;
}

+ (BOOL) databaseIsUpdatable;
- (void) _downloadFTSPlugin;
- (void) _updateUserDatabase;
- (void) _loadPlugins;
- (void) _openDatabase:(NSString*)filename;
- (float) progress;
- (void) setProgress:(float)progress;

@property (nonatomic, retain) LWEDownloader *dlHandler;
@property (nonatomic, retain) NSString *taskMessage;
@property (nonatomic, retain) NSString *statusMessage;


@end