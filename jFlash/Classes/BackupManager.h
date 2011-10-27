//
//  BackupManager.h
//  jFlash
//
//  Created by Ross on 3/24/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Error information sent by backup manager
extern NSString *const LWEBackupManagerErrorDomain;
typedef enum {
  kDataNotFound = 1,
} LWEBackupManagerErrorCode;

//! Informational Methods mostly for UX responses to success or failure
@protocol BackupManagerDelegate
@optional
- (void)didBackupUserData;
- (void)didFailToBackupUserDataWithError:(NSError *)error;
- (void)didRestoreUserData;
- (void)didFailToRestoreUserDateWithError:(NSError *)error;

@end

//! Backup Manager handles storing user sets to server, also restoring them
//! Tightly coupled to jFlash and the jFlash API, orthagonality to come later
@interface BackupManager : NSObject

//! Initialize with a delegate
- (BackupManager*) initWithDelegate:(id)aDelegate;
//! Downloads the restore file and adds it
- (void) restoreUserData;
//! Returns an NSData containing the serialized associative array
- (NSData*) serializedDataForUserSets;
//! Installs the sets for a serialized associative array of sets
- (void) createUserSetsForData:(NSData*)data;
//! Backs up the user's data to the api
- (void) backupUserData;
//! Helper method that returns the flashType string name used by the API
- (NSString*) stringForFlashType;

@property (assign) id delegate;

@end