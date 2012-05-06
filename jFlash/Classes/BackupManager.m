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

@interface BackupManager ()
- (Tag *) _tagForName:(NSString *)tagName andId:(NSNumber *)key andGroupId:(NSNumber *)groupId;
@end

@implementation BackupManager
@synthesize delegate;

//! Init the BackupManager with a Delegate
- (BackupManager*) initWithDelegate:(id<LWEBackupManagerDelegate>)aDelegate
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
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (void) _updateProgress:(CGFloat)progress
{
  // Don't let this be called from the background as it could update the UI on the other side
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(_updateProgress:) withObject:[NSNumber numberWithFloat:progress] waitUntilDone:NO];
    return;
  }
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(backupManager:currentProgress:)])
  {
    [self.delegate backupManager:self currentProgress:progress];
  }
}

#pragma mark - Restore

//! Delegate on success
- (void)didRestoreUserData
{
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(didRestoreUserData) withObject:nil waitUntilDone:NO];
    return;
  }
  
  LWE_DELEGATE_CALL(@selector(backupManagerDidRestoreUserData:), self);
}

//! Delegate on failure
- (void)didFailToRestoreUserDataWithError:(NSError *)error
{
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(didFailToRestoreUserDataWithError:) withObject:error waitUntilDone:NO];
    return;
  }

  if (self.delegate && [self.delegate respondsToSelector:@selector(backupManager:didFailToRestoreUserDataWithError:)])
  {
    [self.delegate backupManager:self didFailToRestoreUserDataWithError:error];
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
    [self didFailToRestoreUserDataWithError:error];
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
  if ([[LWEJanrainLoginManager sharedLWEJanrainLoginManager] isAuthenticated])
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
- (Tag *) _tagForName:(NSString *)tagName andId:(NSNumber *)key andGroupId:(NSNumber *)groupId
{
  // Quick return on 0
  if ([key isEqual:[NSNumber numberWithInt:STARRED_TAG_ID]])
  {
    return [Tag starredWordsTag];
  }
  
  // see if the tag already exists
  Tag *tag = [TagPeer retrieveTagByName:tagName];
  if (tag.tagId == kLWEUninitializedTagId) // no tag, create one
  {
    Group *owningGroup = [GroupPeer retrieveGroupById:[groupId intValue]];
    tag = [TagPeer createTagNamed:tagName inGroup:owningGroup];
  }

  return tag;
}

//! Takes a NSData created by serializedDataForUserSets and populates the data tables
- (void) createUserSetsForData:(NSData*)data
{
  NSDictionary *idsDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  NSInteger totalSets = [idsDict count];
  NSInteger i = 0;
  for (NSNumber *tagIdNum in idsDict)
  {
    // Increment the counter and call back to the progress delegate
    i++;
    [self _updateProgress:((CGFloat)i/(CGFloat)totalSets)];

    LWE_ASSERT_EXC([tagIdNum isKindOfClass:[NSNumber class]], @"Must pass a dict where keys are NSNumbers");
    
    NSArray *cardIdsAndTagName = [idsDict objectForKey:tagIdNum];
    LWE_ASSERT_EXC([cardIdsAndTagName count] > 1, @"Tag info must be an array of at least 2 values");
    
    // the first oject is the tag name, second is the group id
    NSEnumerator *objEnumerator = [cardIdsAndTagName objectEnumerator];
    NSString *tagName = [objEnumerator nextObject];  // index = 0
    NSNumber *groupId = [objEnumerator nextObject];  // index = 1
    
    // the rest are card ids, so add them to the tag we just made
    Tag *userTag = [self _tagForName:tagName andId:tagIdNum andGroupId:groupId];
    NSArray *currentCards = [CardPeer retrieveFaultedCardsForTag:userTag];
    NSNumber *newCardId = nil;
    while ((newCardId = [objEnumerator nextObject])) 
    {
      Card *newCard = [CardPeer blankCardWithId:[newCardId integerValue]];
      if ([currentCards containsObject:newCard] == NO)
      {
        [TagPeer subscribeCard:newCard toTag:userTag];
      }
    }
  }
}

#pragma mark - Backup

//! Delegate on success
- (void)didBackupUserData
{
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(didBackupUserData) withObject:nil waitUntilDone:NO];
    return;
  }

  if(self.delegate && [self.delegate respondsToSelector:@selector(backupManagerDidBackupUserData:)])
  {
    [self.delegate backupManagerDidBackupUserData:self];
  }
}

//! Delegate on failure
- (void)didFailToBackupUserDataWithError:(NSError *)error
{
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(didFailToBackupUserDataWithError:) withObject:error waitUntilDone:NO];
    return;
  }

  if(self.delegate && [self.delegate respondsToSelector:@selector(backupManager:didFailToBackupUserDataWithError:)])
  {
    [self.delegate backupManager:self didFailToBackupUserDataWithError:error];
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
  if ([[LWEJanrainLoginManager sharedLWEJanrainLoginManager] isAuthenticated])
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
  NSMutableDictionary *cardDict = [NSMutableDictionary dictionary];
  for (Tag *tag in [TagPeer retrieveUserTagList])
  {
    // Faulted cards are Card objects but have not been retrieved/hydrated and have IDs only.
    NSArray *cards = [CardPeer retrieveFaultedCardsForTag:tag];
    NSMutableArray *cardIdsAndTagName = [NSMutableArray array];
    [cardIdsAndTagName addObject:tag.tagName];
    [cardIdsAndTagName addObject:[NSNumber numberWithInt:tag.groupId]];
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

  // Quick return with a status error if we didn't get a 200
  if ([request responseStatusCode] != 200)
  {
    NSError *error = [NSError errorWithDomain:NetworkRequestErrorDomain
                                         code:[request responseStatusCode] 
                                     userInfo:[NSDictionary dictionaryWithObject:[request responseStatusMessage] forKey:NSLocalizedDescriptionKey]];
    if ([responseType isEqualToString:@"backup"])
    {
      [self didFailToBackupUserDataWithError:error];
    }
    else if ([responseType isEqualToString:@"restore"])
    {
      [self didFailToRestoreUserDataWithError:error];
    }
    return;
  }

  if ([responseType isEqualToString:@"backup"])
  {
    [self didBackupUserData];
  }
  else if ([responseType isEqualToString:@"restore"])
  {
    [self _installDataFromResponse:request];
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  NSString *responseType = [[request userInfo] objectForKey:@"requestType"];
  NSError *error = [request error];
  
  if ([responseType isEqualToString:@"backup"])
  {
    [self didFailToBackupUserDataWithError:error];
  }
  else if ([responseType isEqualToString:@"restore"])
  {
    [self didFailToRestoreUserDataWithError:error];
  }
}

@end

NSString * const LWEBackupManagerErrorDomain  = @"LWEBackupManagerErrorDomain";