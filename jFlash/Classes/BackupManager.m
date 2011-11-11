//
//  BackupManager.m
//  jFlash
//
//  Created by Ross on 3/24/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "BackupManager.h"
#import "LWEJanrainLoginManager.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

#define API_BACKUP_DATA_URL @"http://lweflash.appspot.com/api/uploadBackup";

@implementation BackupManager
@synthesize delegate;

//! Init the BackupManager with a Delegate
- (BackupManager*) initWithDelegate:(id)aDelegate
{
  if ((self = [super init]))
  {
    self.delegate = aDelegate;
  }
  return self;
}

//! Helper method that returns the flashType string name used by the API
- (NSString*) stringForFlashType
{
  // TODO: change this to use the Bundle Identifier
#if APP_TARGET == APP_TARGET_JFLASH
  return @"japaneseflash";
#else
  return @"chineseflash";
#endif
}

#pragma mark Restore

//! Delegate on success
- (void)didRestoreUserData
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(didRestoreUserData)])
  {
    [delegate didRestoreUserData];
  }
}

//! Delegate on failure
- (void)didFailToRestoreUserDateWithError:(NSError *)error
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(didFailToRestoreUserDateWithError:)])
  {
    [delegate didFailToRestoreUserDateWithError:error];
  }
}

//! Private method to really install the data.
- (void) _installDataFromResponse:(ASIHTTPRequest *)request
{
  NSData *data = [request responseData];
  if (data)
  {
    [self createUserSetsForData:data];
    [TagPeer recacheCountsForUserTags];
    [self didRestoreUserData];
  }
  else
  {
    NSError *error = [NSError errorWithDomain:LWEBackupManagerErrorDomain code:kDataNotFound userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not find backup data on web sevice.",@"") forKey:NSLocalizedDescriptionKey]];
    [self didFailToRestoreUserDateWithError:error];
  }
}

/*!
 @method     restoreUserData
 @abstract   downloads and installs the data file from the web service. Alerts for success or failure.
 */
- (void) _restoreUserDataFromWebService 
{
  // Stop listening for a login
  [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEJanrainLoginManagerUserDidAuthenticate object:nil];
  
  //  download the userdate file
  NSString *dataURL = [NSString stringWithFormat:@"http://lweflash.appspot.com/api/getBackup?flashType=%@",[self stringForFlashType]];
  
  //This url will return the value of the 'ASIHTTPRequestTestCookie' cookie
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:dataURL]];
  [request setDelegate:self];
  [request setUserInfo:[NSDictionary dictionaryWithObject:@"restore" forKey:@"requestType"]];
  [request startAsynchronous];
}

/*!
 @method     restoreUserData
 @abstract   Checks login status and either calls the private install or listens for it
 */
- (void) restoreUserData
{
  if ([[LWEJanrainLoginManager sharedLWEJanrainLoginManager] isAuthenticated] == YES)
  {
    [self _restoreUserDataFromWebService];
  }
  else
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_restoreUserDataFromWebService) name:LWEJanrainLoginManagerUserDidAuthenticate object:nil];
    [[LWEJanrainLoginManager sharedLWEJanrainLoginManager] login]; // need to be logged in for this
  }
}

//! Gets or creates a tag for the given name. Uses an existing Id to handle the magic set
- (NSInteger) _getTagIdForName:(NSString *)tagName andId:(NSNumber *)key andGroup:(NSNumber *)group
{
  // Quick return on 0
  if ([key isEqual:[NSNumber numberWithInt:0]])
  {
    return 0;
  }
  
  // see if the tag already exists
  Tag *tag = [TagPeer retrieveTagByName:tagName];
  if (tag.tagId == -1) // no tag, create one
  {
    tag = [TagPeer createTag:tagName withOwner:[group intValue]];
  }

  return tag.tagId;
}

//! Takes a NSData created by serializedDataForUserSets and populates the data tables
- (void) createUserSetsForData:(NSData*)data
{
  NSDictionary *idsDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  NSEnumerator *enumerator = [idsDict keyEnumerator];
  NSNumber *key = nil;
  NSMutableArray *currentCardIds = [NSMutableArray array];
  
  while ((key = [enumerator nextObject])) 
  {
    NSArray *cardIdsAndTagName = [idsDict objectForKey:key];
    NSEnumerator *objEnumerator = [cardIdsAndTagName objectEnumerator];
    
    // the first oject is the tag name
    NSString *tagName = [objEnumerator nextObject];
    
    // the second object is the group id
    NSNumber *groupId = [objEnumerator nextObject]; 
    
    NSInteger tagId = [self _getTagIdForName:tagName andId:key andGroup:groupId];
    
    // the rest are card ids, so add them to the tag we just made
    NSArray *cards = [CardPeer retrieveCardIdsForTagId:tagId];
    for (Card *card in cards)
    {
      [currentCardIds addObject:[NSNumber numberWithInt:card.cardId]];
    }
    
    NSNumber *newCardId = nil;
    
    // We just need a card & tag object to pass to subscribe:, so use one and change its ID
    Card *card = [[Card alloc] init];
    Tag *tag = [[Tag alloc] init];
    while ((newCardId = [objEnumerator nextObject])) 
    {
      // add the card to the tag if it isn't already there
      if ([currentCardIds containsObject:newCardId] == NO)
      {
        card.cardId = [newCardId intValue];
        tag.tagId = tagId;
        [TagPeer subscribeCard:card toTag:tag];
      }
    }
    [card release];
    [tag release];
    [currentCardIds removeAllObjects];
  }
}

#pragma mark - Backup

//! Delegate on success
- (void)didBackupUserData
{
  if(self.delegate && [self.delegate respondsToSelector:@selector(didBackupUserData)])
  {
    [self.delegate didBackupUserData];
  }
}

//! Delegate on failure
- (void)didFailToBackupUserDataWithError:(NSError *)error
{
  if(self.delegate && [self.delegate respondsToSelector:@selector(didFailToBackupUserDataWithError:)])
  {
    [self.delegate didFailToBackupUserDataWithError:error];
  }
}

//! Private backup method to be called directly or async
- (void) _backupUserData 
{
  // Stop listening for a login
  [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEJanrainLoginManagerUserDidAuthenticate object:nil];
  
  // Get the data
  NSData *archivedData = [self serializedDataForUserSets];
  NSString *dataURL = API_BACKUP_DATA_URL;
  
  // Perform the request
  ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:dataURL]];
  [request setUserInfo:[NSDictionary dictionaryWithObject:@"backup" forKey:@"requestType"]];
  [request setDelegate:self];
  [request setPostValue:[self stringForFlashType] forKey:@"flashType"];
  [request setData:archivedData forKey:@"backupFile"];
  [request startAsynchronous];
}

//! Backup the user's data to our API, currently set's and set membership only
- (void) backupUserData
{
  if ([[LWEJanrainLoginManager sharedLWEJanrainLoginManager] isAuthenticated] == YES)
  {
    [self _backupUserData];
  }
  else
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backupUserData) name:LWEJanrainLoginManagerUserDidAuthenticate object:nil];
    [[LWEJanrainLoginManager sharedLWEJanrainLoginManager] login]; // need to be logged in for this
  }
}

//! Returns an NSData containing the serialized associative array
- (NSData*) serializedDataForUserSets
{
  NSMutableDictionary* cardDict = [NSMutableDictionary dictionary];
  for (Tag *tag in [TagPeer retrieveUserTagList])
  {
    NSArray *cards = [CardPeer retrieveCardIdsForTagId:tag.tagId];
    NSMutableArray *cardIdsAndTagName = [NSMutableArray array];
    [cardIdsAndTagName addObject:tag.tagName];
    [cardIdsAndTagName addObject:[NSNumber numberWithInt:[tag groupId]]];
    for (Card *card in cards)
    {
      [cardIdsAndTagName addObject:[NSNumber numberWithInt:card.cardId]];
    }
    [cardDict setObject:cardIdsAndTagName forKey:[NSNumber numberWithInt:tag.tagId]];
  }
  
  NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:cardDict]; // serialize the cardDict
  
  return archivedData;
}

#pragma mark - ASIHTTPRequest Response

- (void)requestFinished:(ASIHTTPRequest *)request
{
  NSString *responseType = [[request userInfo] objectForKey:@"requestType"];

  if(responseType == @"backup")
  {
    if ([request responseStatusCode] != 200)
    {
      NSError *error = [NSError errorWithDomain:NetworkRequestErrorDomain
                                           code:[request responseStatusCode] 
                                       userInfo:[NSDictionary dictionaryWithObject:[request responseStatusMessage] forKey:NSLocalizedDescriptionKey]];
      
      [self didFailToBackupUserDataWithError:error];
    }
    else 
    {
      [self didBackupUserData];
    }
  }
  else if (responseType == @"restore")
  {
    if ([request responseStatusCode] != 200)
    {
      NSError *error = [NSError errorWithDomain:NetworkRequestErrorDomain
                                           code:[request responseStatusCode] 
                                       userInfo:[NSDictionary dictionaryWithObject:[request responseStatusMessage] forKey:NSLocalizedDescriptionKey]];
      
      [self didFailToBackupUserDataWithError:error];
    }
    else
    {
      [self _installDataFromResponse: request];
    }
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  NSString *responseType = [[request userInfo] objectForKey:@"requestType"];
  NSError *error = [request error];
  
  if (responseType == @"backup")
  {
    [self didFailToBackupUserDataWithError:error];
  }
  else if (responseType == @"restore")
  {
    [self didFailToRestoreUserDateWithError:error];
  }
}

@end

NSString * const LWEBackupManagerErrorDomain  = @"LWEBackupManagerErrorDomain";