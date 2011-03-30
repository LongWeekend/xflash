//
//  LWEJanrainLoginManager.m
//  jFlash
//
//  Created by Ross on 3/25/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "LWEJanrainLoginManager.h"
#import "SynthesizeSingleton.h"

@implementation LWEJanrainLoginManager
@synthesize jrEngage, userIdentifier, profile;

#pragma mark -
#pragma mark Constructors

SYNTHESIZE_SINGLETON_FOR_CLASS(LWEJanrainLoginManager);

- (id) init
{
  if ((self == [super init]))
  {
    static NSString *appId = @"mhbbfdgbbdndhjlcnkfd"; // <-- This is your app ID
    static NSString *tokenURL = @"http://lweflash.appspot.com/api/authorize";
    self.jrEngage = [JREngage jrEngageWithAppId:appId andTokenUrl:tokenURL delegate:self]; // TODO: add the appengine url
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
  }
  return self;
}

#pragma mark -
#pragma mark Memory

- (void) dealloc
{
  self.profile = nil;
  self.userIdentifier = nil;
  self.jrEngage = nil;
  [super dealloc];
}

#pragma mark -
#pragma mark Authentication

//! Determines if we already know who the user is
- (BOOL) isAuthenticated
{
  if (self.userIdentifier != nil)
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
    [self.jrEngage showAuthenticationDialog];
  }
}

//! Shows the auth dialogue regardless of auth status
- (void) loginForMoreProviders
{
  [self.jrEngage showAuthenticationDialog];
}

//! Removes the profile, userIdentifier, and tells jr to signout for all providers
- (void) logout
{
  self.profile = nil;
  self.userIdentifier = nil;
  [self.jrEngage signoutUserForAllProviders];
}

#pragma mark Engage Authentication Delegate Callbacks

- (void)jrAuthenticationDidSucceedForUser:(NSDictionary *)auth_info forProvider:(NSString *)provider
{
  NSDictionary *aProfile = [auth_info objectForKey:@"profile"];
  self.profile = aProfile;
  self.userIdentifier = [self.profile objectForKey:@"identifier"];
  
  // Tell anyone who might care
  NSNotification *aNotification = [NSNotification notificationWithName:LWEJanrainLoginManagerUserDidAuthenticate object:self.userIdentifier];
  [[NSNotificationCenter defaultCenter] postNotification:aNotification];
}

- (void)jrAuthenticationDidReachTokenUrl:(NSString*)tokenUrl withResponse:(NSURLResponse*)response andPayload:(NSData*)tokenUrlPayload forProvider:(NSString*)provider
{ 
  // TODO: handle the response from our server. Likely just a session or whatev
  if ([response respondsToSelector:@selector(allHeaderFields)])
  {
    NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[(NSHTTPURLResponse*)response allHeaderFields] forURL:[response URL]];
    for (NSHTTPCookie* cookie in cookies)
    {
      [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }
  }
  LWE_LOG(@"Provider: %@", provider);
}

#pragma mark -
#pragma mark Sharing

- (void) share:(NSString*)action andUrl:(NSString*)url
{
  [self login];
  
  JRActivityObject *activity = [[[JRActivityObject alloc] initWithAction:action andUrl:url] autorelease];
  [self.jrEngage showSocialPublishingDialogWithActivity:activity];
}

/*!
    @method     
    @abstract   Share method.
    @discussion userContent is editable by user before sharing. Action is the "grayed out text"
*/
- (void) share:(NSString*)action andUrl:(NSString*)url userContentOrNil:(NSString*)userContent
{
  [self login];
  
  JRActivityObject *activity = [[[JRActivityObject alloc] initWithAction:action andUrl:url] autorelease];
  activity.title = userContent;
  activity.description = userContent;
  [self.jrEngage showSocialPublishingDialogWithActivity:activity];
}

@end

NSString * const LWEJanrainLoginManagerUserDidAuthenticate = @"LWEJanrainLoginManagerUserDidAuthenticate";