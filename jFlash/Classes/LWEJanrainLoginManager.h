//
//  LWEJanrainLoginManager.h
//  jFlash
//
//  Created by Ross on 3/25/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "JREngage.h"

@interface LWEJanrainLoginManager : NSObject <JREngageDelegate> {}

- (void) login;
- (void) loginForMoreProviders;
- (void) logout;
- (BOOL) isAuthenticated;

//! Sharing Methods
- (void) share:(NSString*)action andUrl:(NSString*)url;
- (void) share:(NSString*)action andUrl:(NSString*)url userContentOrNil:(NSString*)userContent;

@property(nonatomic, retain) JREngage* jrEngage;
@property(nonatomic, retain) NSString* userIdentifier;
@property(nonatomic, retain) NSDictionary* profile;

@end

extern NSString * const LWEJanrainLoginManagerUserDidAuthenticate;
extern NSString * const LWEJanrainLoginManagerUserDidNotAuthenticate;