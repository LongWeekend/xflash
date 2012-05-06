//
//  BackupManager.h
//  jFlash
//
//  Created by Ross on 3/24/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LWEJanrainLoginManager.h"

//! Error information sent by backup manager
extern NSString *const LWEBackupManagerErrorDomain;
typedef enum {
  kDataNotFound = 1,
} LWEBackupManagerErrorCode;

@class BackupManager;

//! Informational Methods mostly for UX responses to success or failure
@protocol LWEBackupManagerDelegate <NSObject>
@optional
- (void)backupManager:(BackupManager *)manager currentProgress:(CGFloat)progress;
- (void)backupManagerDidBackupUserData:(BackupManager *)manager;
- (void)backupManager:(BackupManager *)manager didFailToBackupUserDataWithError:(NSError *)error;
- (void)backupManagerDidRestoreUserData:(BackupManager *)manager;
- (void)backupManager:(BackupManager *)manager didFailToRestoreUserDataWithError:(NSError *)error;
@end

//! Backup Manager handles storing user sets to server, also restoring them
//! Tightly coupled to jFlash and the jFlash API, orthagonality to come later
@interface BackupManager : NSObject

//! Initialize with a delegate
- (BackupManager*) initWithDelegate:(id)aDelegate;
//! Downloads the restore file and adds it
- (void) restoreUserData;
//! Backs up the user's data to the api
- (void) backupUserData;
//! Helper method that returns the flashType string name used by the API
- (NSString*) stringForFlashType;

@property (retain) LWEJanrainLoginManager *loginManager;
@property (assign) id<LWEBackupManagerDelegate> delegate;

@end