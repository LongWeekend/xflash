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
  kMigraterPrepareSQL,              //! Prepare DB by adding an index
  kMigraterUpdateSQL,               //! Updating SQL
  kMigraterUpdateSQLFail,           //! Failed to update SQL
  kMigraterFinalizeSQL,             //! Commit statement
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
  BOOL _cancelRequest;
}

+ (BOOL) databaseIsUpdatable;
- (float) progress;
- (void) setProgress:(float)progress;
- (void) _downloadFTSPlugin;

@property (nonatomic, retain) LWEDownloader *dlHandler;
@property (nonatomic, retain) NSString *taskMessage;
@property (nonatomic, retain) NSString *statusMessage;


@end
