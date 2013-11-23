//
//  LWEJanrainLoginManager.m
//  jFlash
//
//  Created by Ross on 3/25/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "LWEJanrainLoginManager.h"

@implementation LWEJanrainLoginManager
@synthesize userIdentifier, profile, delegate;

#pragma mark - Constructors

- (id) init
{
  self = [super init];
  if (self)
  {
    static NSString *appId = @"mhbbfdgbbdndhjlcnkfd"; // <-- This is your app ID
    static NSString *tokenURL = @"http://lweflash.appspot.com/api/authorize";
    // TODO: add the appengine url
    [JREngage setEngageAppId:appId tokenUrl:tokenURL andDelegate:self];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
  }
  return self;
}

#pragma mark - Memory

- (void) dealloc
{
  self.profile = nil;
  self.userIdentifier = nil;
  [super dealloc];
}

#pragma mark - Authentication

//! Determines if we already know who the user is
- (BOOL) isAuthenticated
{
  if (self.userIdentifier)
  {
    return YES;
  }
  return NO;
}

//! Displays the jf auth dialog if not signed in already
- (void) login
{
  if ([self isAuthenticated] == NO)
  {
    [JREngage showAuthenticationDialog];
  }
}

//! Shows the auth dialogue regardless of auth status
- (void) loginForMoreProviders
{
  [JREngage showAuthenticationDialog];
}

//! Removes the profile, userIdentifier, and tells jr to signout for all providers
- (void) logout
{
  self.profile = nil;
  self.userIdentifier = nil;
  [JREngage clearSharingCredentialsForAllProviders];
}

#pragma mark Engage Authentication Delegate Callbacks

- (void)authenticationDidSucceedForUser:(NSDictionary *)authInfo forProvider:(NSString *)provider
{
  NSDictionary *aProfile = [authInfo objectForKey:@"profile"];
  self.profile = aProfile;
  self.userIdentifier = [self.profile objectForKey:@"identifier"];
}

- (void)authenticationDidReachTokenUrl:(NSString *)tokenUrl withResponse:(NSURLResponse *)response andPayload:(NSData *)tokenUrlPayload forProvider:(NSString *)provider
{
  // TODO: handle the response from our server. Likely just a session or whatev
  if ([response respondsToSelector:@selector(allHeaderFields)])
  {
    NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[(NSHTTPURLResponse*)response allHeaderFields] forURL:[response URL]];
    for (NSHTTPCookie* cookie in cookies)
    {
      [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }

    // Delegate callback
    if (self.delegate && [self.delegate respondsToSelector:@selector(loginManagerDidAuthenticate:)])
    {
      [self.delegate loginManagerDidAuthenticate:self];
    }

    // Tell anyone who might care
    NSNotification *aNotification = [NSNotification notificationWithName:LWEJanrainLoginManagerUserDidAuthenticate object:self.userIdentifier];
    [[NSNotificationCenter defaultCenter] postNotification:aNotification];
  }
}

#pragma mark - Failure Delegate

- (void) forwardErrorToDelegate:(NSError *)error
{
  // Just forward messages
  if (self.delegate && [self.delegate respondsToSelector:@selector(loginManager:didFailAuthenticationWithError:)])
  {
    [self.delegate loginManager:self didFailAuthenticationWithError:error];
  }
}

- (void)authenticationDidNotComplete
{
  // TODO: This is INCOMPLETE
  [self forwardErrorToDelegate:nil];

  // Tell anyone who might care
  NSNotification *aNotification = [NSNotification notificationWithName:LWEJanrainLoginManagerUserDidNotAuthenticate object:self.userIdentifier];
  [[NSNotificationCenter defaultCenter] postNotification:aNotification];
}

- (void)authenticationDidFailWithError:(NSError *)error forProvider:(NSString *)provider
{
  [self forwardErrorToDelegate:error];
}

- (void)engageDialogDidFailToShowWithError:(NSError *)error
{
  [self forwardErrorToDelegate:error];
}

#pragma mark - Sharing

- (void) share:(NSString*)action andUrl:(NSString*)url
{
//  [self login];
  
//  JRActivityObject *activity = [[[JRActivityObject alloc] initWithAction:action andUrl:url] autorelease];
//  [self.jrEngage showSocialPublishingDialogWithActivity:activity];
}

/*!
    @method     
    @abstract   Share method.
    @discussion userContent is editable by user before sharing. Action is the "grayed out text"
*/
- (void) share:(NSString*)action andUrl:(NSString*)url userContentOrNil:(NSString*)userContent
{
//  [self login];
  
//  JRActivityObject *activity = [[[JRActivityObject alloc] initWithAction:action andUrl:url] autorelease];
//  activity.title = userContent;
//  activity.description = userContent;
//  [self.jrEngage showSocialPublishingDialogWithActivity:activity];
}

@end

NSString * const LWEJanrainLoginManagerUserDidNotAuthenticate = @"LWEJanrainLoginManagerUserDidNotAuthenticate";
NSString * const LWEJanrainLoginManagerUserDidAuthenticate = @"LWEJanrainLoginManagerUserDidAuthenticate";