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

NSString * const BackupManagerRestoreURL = @"http://lweflash.appspot.com/api/getBackup";
NSString * const BackupManagerBackupURL = @"http://lweflash.appspot.com/api/uploadBackup";
NSString * const BMRequestType = @"requestType";
NSString * const BMBackup = @"backup";
NSString * const BMRestore = @"restore";
NSString * const BMBackupFilename = @"backupFile";
NSString * const BMFlashType = @"flashType";

@interface BackupManager ()
- (Tag *) _tagForName:(NSString *)tagName andId:(NSNumber *)key andGroupId:(NSNumber *)groupId;
//! Returns an NSData containing the serialized associative array
- (NSData*) _serializedDataForUserSets;
//! Installs the sets for a serialized associative array of sets
- (void) _createUserSetsForData:(NSData*)data;
@end

@implementation BackupManager
@synthesize delegate, loginManager;

#pragma mark - Class Plumbing

//! Init the BackupManager with a Delegate
- (BackupManager*) initWithDelegate:(id<LWEBackupManagerDelegate>)aDelegate
{
  if ((self = [super init]))
  {
    self.delegate = aDelegate;
    self.loginManager = [[[LWEJanrainLoginManager alloc] init] autorelease];
  }
  return self;
}

- (void) dealloc
{
  [loginManager release];
  // In case we get dealloc'ed while waiting on an observation
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
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
    [self _createUserSetsForData:data];
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
  
  //  download the userdate file - concatenate the URL depending if this is JFlash or CFlash
  NSString *dataURL = [BackupManagerRestoreURL stringByAppendingFormat:@"?%@=%@",BMFlashType,[self stringForFlashType]];
  
  //This url will return the value of the 'ASIHTTPRequestTestCookie' cookie
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:dataURL]];
  [request setDelegate:self];
  [request setUserInfo:[NSDictionary dictionaryWithObject:BMRestore forKey:BMRequestType]];
  [request startAsynchronous];
}

/*!
 @method     restoreUserData
 @abstract   Checks login status and either calls the private install or listens for it
 */
- (void) restoreUserData
{
  if ([self.loginManager isAuthenticated])
  {
    [self _restoreUserDataFromWebService];
  }
  else
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_restoreUserDataFromWebService) name:LWEJanrainLoginManagerUserDidAuthenticate object:nil];
    [self.loginManager login]; // need to be logged in for this
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
- (void) _createUserSetsForData:(NSData*)data
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
  NSData *archivedData = [self _serializedDataForUserSets];
  
  // Perform the request
  ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:BackupManagerBackupURL]];
  [request setUserInfo:[NSDictionary dictionaryWithObject:BMBackup forKey:BMRequestType]];
  [request setDelegate:self];
  // Is this JFlash or CFlash?
  [request setPostValue:[self stringForFlashType] forKey:BMFlashType];
  [request setData:archivedData forKey:BMBackupFilename];
  [request startAsynchronous];
}

//! Backup the user's data to our API, currently set's and set membership only
- (void) backupUserData
{
  if ([self.loginManager isAuthenticated])
  {
    [self _backupUserData];
  }
  else
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backupUserData) name:LWEJanrainLoginManagerUserDidAuthenticate object:nil];
    [self.loginManager login]; // need to be logged in for this
  }
}

//! Returns an NSData containing the serialized associative array
- (NSData*) _serializedDataForUserSets
{
  NSMutableDictionary *cardDict = [NSMutableDictionary dictionary];
  NSArray *tags = [TagPeer retrieveUserTagList];
  NSInteger totalCount = [tags count];
  NSInteger i = 0;
  for (Tag *tag in tags)
  {
    // Report the progress of the retrieve/serialize to the delegate
    i++;
    [self _updateProgress:((CGFloat)i/(CGFloat)totalCount)];
    
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
  NSString *responseType = [[request userInfo] objectForKey:BMRequestType];

  // Quick return with a status error if we didn't get a 200
  if ([request responseStatusCode] != 200)
  {
    NSError *error = [NSError errorWithDomain:NetworkRequestErrorDomain
                                         code:[request responseStatusCode] 
                                     userInfo:[NSDictionary dictionaryWithObject:[request responseStatusMessage] forKey:NSLocalizedDescriptionKey]];
    if ([responseType isEqualToString:BMBackup])
    {
      [self didFailToBackupUserDataWithError:error];
    }
    else if ([responseType isEqualToString:BMRestore])
    {
      [self didFailToRestoreUserDataWithError:error];
    }
    return;
  }

  if ([responseType isEqualToString:BMBackup])
  {
    [self didBackupUserData];
  }
  else if ([responseType isEqualToString:BMRestore])
  {
    [self _installDataFromResponse:request];
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  NSString *responseType = [[request userInfo] objectForKey:BMRequestType];
  NSError *error = [request error];
  
  if ([responseType isEqualToString:BMBackup])
  {
    [self didFailToBackupUserDataWithError:error];
  }
  else if ([responseType isEqualToString:BMRestore])
  {
    [self didFailToRestoreUserDataWithError:error];
  }
}

@end

NSString * const LWEBackupManagerErrorDomain  = @"LWEBackupManagerErrorDomain";