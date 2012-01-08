//
//  UpdateManager.h
//  jFlash
//
//  Created by Mark Makdad on 10/13/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UpdateManager : NSObject

/**
 * This method migrates the NSUserDefaults to the most
 * recent version of the application.  This is a static
 * method, and the application should pass in the settings
 * that it wishes to migrate.
 * 
 * \return YES if settings/app was migrated
 * \param settings an NSUserDefaults object
 */
+ (BOOL) performMigrations:(NSUserDefaults*)settings;

/**
 * Determine's if the user's database is lagging behind the current version
 */
+ (BOOL) databaseIsUpdatable:(NSUserDefaults*)settings;

/**
 * Prompts a UIAlertView to show with a message pertaining to this update
 */
+ (void) showUpgradeAlertView:(NSUserDefaults *)settings delegate:(id<UIAlertViewDelegate>)alertDelegate;

@end
