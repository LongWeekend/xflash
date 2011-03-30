//
//  BackupManager.h
//  jFlash
//
//  Created by Ross on 3/24/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BackupManager : NSObject {

}

//! Downloads the restore file and adds it
+ (void) restoreUserData;
//! Returns an NSData containing the serialized associative array
+ (NSData*) serializedDataForUserSets;
//! Installs the sets for a serialized associative array of sets
+ (void) createUserSetsForData:(NSData*)data;
//! Backs up the user's data to the api
+ (void) backupUserData;
//! Helper method that returns the flashType string name used by the API
+ (NSString*) stringForFlashType;

@end
