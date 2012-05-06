//
//  BackupManager.m
//  jFlash
//
//  Created by Ross on 3/24/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "BackupManager.h"
#import "UserPeer.h"
#import "UserHistory.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

NSString * const BackupManagerRestoreURL = @"http://lweflash.appspot.com/api/getBackup";
NSString * const BackupManagerBackupURL = @"http://lweflash.appspot.com/api/uploadBackup";
NSString * const BMRequestType = @"requestType";
NSString * const BMBackup = @"backup";
NSString * const BMRestore = @"restore";
NSString * const BMBackupFilename = @"backupFile";
NSString * const BMBackupUserHistory = @"userHistory";
NSString * const BMBackupUserHistoryUserId = @"userId";
NSString * const BMFlashType = @"flashType";
NSString * const BMVersionKey = @"version";

@interface BackupManager ()
- (Tag *) _tagForName:(NSString *)tagName andId:(NSNumber *)key andGroupId:(NSNumber *)groupId;
- (NSString *) _stringForFlashType;
- (NSString *) _stringForBundleVersion;
//! Returns a dictionary with keys for each tag ID containing the relevant cards
- (NSMutableDictionary*) _dictionaryForUserSetsWithDictionary:(NSMutableDictionary *)cardDict;
//! Returns the dictionary with keys added for each user's UserHistory objects
- (NSMutableDictionary *)_dictionaryForUserHistoryWithDictionary:(NSMutableDictionary *)dict;
//! Installs the sets for a serialized associative array of sets
- (void) _createUserSetsFromDictionary:(NSDictionary*)setDict;
//! Installs the user history for an array of UserHistory objects for each user
- (void) _createUserHistoryFromDictionary:(NSDictionary *)historyDict;
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
    self.loginManager.delegate = self;
  }
  return self;
}

- (void) dealloc
{
  [loginManager release];
  [super dealloc];
}

//! Helper method that returns the flashType string name used by the API
- (NSString*) _stringForFlashType
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (NSString *) _stringForBundleVersion
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (void) _updateProgress:(NSNumber *)progress
{
  // Don't let this be called from the background as it could update the UI on the other side
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(_updateProgress:) withObject:progress waitUntilDone:NO];
    return;
  }
  
  // Hack apart the progress that the individual steps are sending us -- they are sending us 0-100 of THEIR step, 
  // but we want to average that out over the whole process.
  CGFloat currentSectionPercent = (CGFloat)(currentSection) / (CGFloat)(progressSections);
  CGFloat nextSectionPercent = (CGFloat)(currentSection + 1) / ((CGFloat)progressSections);
  if (nextSectionPercent > 1.0f)
  {
    nextSectionPercent = 1.0f;
  }
  
  // Now multiply THEIR progress by the difference and report that + the currentSectionPercent.
  CGFloat difference = (nextSectionPercent - currentSectionPercent);
  CGFloat diffProgress = [progress floatValue] * difference;
  CGFloat actualProgress = currentSectionPercent + diffProgress;
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(backupManager:currentProgress:)])
  {
    [self.delegate backupManager:self currentProgress:actualProgress];
  }
}

- (void) _updateStatus:(NSString *)status
{
  // Don't let this be called from the background as it could update the UI on the other side
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(_updateStatus:) withObject:status waitUntilDone:NO];
    return;
  }

  // Increment the progress section counter
  currentSection++;
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(backupManager:statusDidChange:)])
  {
    [self.delegate backupManager:self statusDidChange:status];
  }
  
}

#pragma mark - Public Methods

//! Backup the user's data to our API, currently set's and set membership only
- (void) backupUserData
{
  // Reset the progress section counter
  currentSection = 0;

  // It's important to update this number to reflect the number of times you're going to call
  // _updateStatus for a (potentially) long-running task
  progressSections = 4;
  
  // For authentication callback
  isBackingUp = YES;

  if ([self.loginManager isAuthenticated])
  {
    [self performSelectorInBackground:@selector(_backupUserData) withObject:nil];
  }
  else
  {
    [self.loginManager login]; // need to be logged in for this
  }
}


/*!
 @method     restoreUserData
 @abstract   Checks login status and either calls the private install or listens for it
 */
- (void) restoreUserData
{
  // Reset the progress section counter
  currentSection = 0;
  
  // It's important to update this number to reflect the number of times you're going to call
  // _updateStatus for a (potentially) long-running task
  progressSections = 5;

  // For authentication callback
  isBackingUp = NO;
  
  if ([self.loginManager isAuthenticated])
  {
    [self performSelectorInBackground:@selector(_restoreUserDataFromWebService) withObject:nil];
  }
  else
  {
    [self.loginManager login]; // need to be logged in for this
  }
}

#pragma mark - Login Manager Delegate

-(void)loginManagerDidAuthenticate:(LWEJanrainLoginManager *)manager
{
  if (isBackingUp)
  {
    [self performSelectorInBackground:@selector(_backupUserData) withObject:nil];
  }
  else
  {
    [self performSelectorInBackground:@selector(_restoreUserDataFromWebService) withObject:nil];
  }
}

-(void)loginManager:(LWEJanrainLoginManager *)manager didFailAuthenticationWithError:(NSError *)error
{
  if (isBackingUp)
  {
    [self _didFailToBackupUserDataWithError:error];
  }
  else
  {
    [self _didFailToRestoreUserDataWithError:error];
  }
}

#pragma mark - Restore

//! Delegate on success
- (void)_didRestoreUserData
{
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(_didRestoreUserData) withObject:nil waitUntilDone:NO];
    return;
  }
  
  LWE_DELEGATE_CALL(@selector(backupManagerDidRestoreUserData:), self);
}

//! Delegate on failure
- (void)_didFailToRestoreUserDataWithError:(NSError *)error
{
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(_didFailToRestoreUserDataWithError:) withObject:error waitUntilDone:NO];
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
  // Don't run this on the main thread
  LWE_ASSERT_EXC(([NSThread isMainThread] == NO),@"This is a long-running task that sohuld not run on the main thread");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSData *data = [request responseData];
  
  // Quick return if there's some sort of problem
  if (data == nil)
  {
    NSError *error = [NSError errorWithDomain:LWEBackupManagerErrorDomain code:kDataNotFound userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not find backup data on web sevice.",@"") forKey:NSLocalizedDescriptionKey]];
    [self _didFailToRestoreUserDataWithError:error];
    return;
  }
  
  [self _updateStatus:NSLocalizedString(@"Decompressing",@"Unarchiving Backup File")];
  NSDictionary *backupDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  
  // Create the user's sets out of the dictionary
  [self _updateStatus:NSLocalizedString(@"Restoring Sets",@"Restoring Sets")];
  [self _createUserSetsFromDictionary:backupDict];

  // This is a "safe" call -- if the backupDict doesn't have any user history, nothing will happen.
  [self _updateStatus:NSLocalizedString(@"Restoring Progress",@"Restoring Progress")];
  [self _createUserHistoryFromDictionary:backupDict];

  [self _updateStatus:NSLocalizedString(@"Finalizing",@"Finalizing by Recaching")];
  [TagPeer recacheCountsForUserTags];
  [self _didRestoreUserData];
  [pool release];
}

/*!
 @method     restoreUserData
 @abstract   downloads and installs the data file from the web service. Alerts for success or failure.
 */
- (void) _restoreUserDataFromWebService 
{
  LWE_ASSERT_EXC(([NSThread isMainThread] == NO),@"This method should be run from the BG.");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  //  download the userdate file - concatenate the URL depending if this is JFlash or CFlash
  NSString *dataURL = [BackupManagerRestoreURL stringByAppendingFormat:@"?%@=%@",BMFlashType,[self _stringForFlashType]];
  
  // Append a version number so that the remote API knows what we are capable of receiving
  dataURL = [dataURL stringByAppendingFormat:@"&%@=%@",BMVersionKey,[self _stringForBundleVersion]];
  
  [self _updateStatus:NSLocalizedString(@"Retrieving Backup",@"Downloading Backup File")];
  
  //This url will return the value of the 'ASIHTTPRequestTestCookie' cookie
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:dataURL]];
  request.userInfo = [NSDictionary dictionaryWithObject:BMRestore forKey:BMRequestType];
  request.delegate = self;
  request.downloadProgressDelegate = self;
  [request startAsynchronous];
  [pool release];
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

//! Takes a NSDictionary w/ Tag ID indexes and makes sets out of them
- (void) _createUserSetsFromDictionary:(NSDictionary *)idsDict
{
  NSInteger totalCardsAndSets = 0;
  NSInteger i = 0;
  
  // First, get all the numeric keys -- those are the ones we want.
  NSMutableDictionary *tagIdsDict = [NSMutableDictionary dictionary];
  for (id key in idsDict)
  {
    // For legacy reasons (everything is in one data dump), we have mixed keys - we only want the numbers.
    if ([key isKindOfClass:[NSNumber class]])
    {
      NSArray *thisTag = [idsDict objectForKey:key];
      [tagIdsDict setObject:thisTag forKey:key];
      totalCardsAndSets++;

      // While we are here, get the count of cards - we can use that for updating the progress.
      // We subtract 2 because the first 2 indexes of the array are metadata, not cards.
      totalCardsAndSets = totalCardsAndSets + ([thisTag count] - 2);
    }
  }
  
  for (NSNumber *tagIdNum in tagIdsDict)
  {
    // Increment the counter and call back to the progress delegate
    i++;
    CGFloat progress = ((CGFloat)i/(CGFloat)totalCardsAndSets);
    [self _updateProgress:[NSNumber numberWithFloat:progress]];

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
        i++;
        // We don't need to update the progress EVERY time.
        if ((i % 10) == 0)
        {
          CGFloat progress = ((CGFloat)i/(CGFloat)totalCardsAndSets);
          [self _updateProgress:[NSNumber numberWithFloat:progress]];
        }
        [TagPeer subscribeCard:newCard toTag:userTag];
      }
    }
  }
}

- (void) _createUserHistoryFromDictionary:(NSDictionary *)historyDict
{
  NSArray *users = [UserPeer allUsers];
  
  // Get the total count of records
  NSInteger totalCount = 0;
  for (User *user in users)
  {
    id historyArray = [historyDict objectForKey:[user historyArchiveKey]];
    if (historyArray && [historyArray isKindOfClass:[NSArray class]])
    {
      totalCount = totalCount + [historyArray count];
    }
  }
  
  NSInteger i = 0;
  for (User *user in users)
  {
    id historyArray = [historyDict objectForKey:[user historyArchiveKey]];
    if (historyArray && [historyArray isKindOfClass:[NSArray class]])
    {
      for (UserHistory *history in historyArray)
      {
        // Update progress delegate
        i++;
        CGFloat progress = ((CGFloat)i/(CGFloat)totalCount);
        [self _updateProgress:[NSNumber numberWithFloat:progress]];
        
        LWE_ASSERT_EXC([history isKindOfClass:[UserHistory class]],@"This array should only contain UserHistory objs");
        [history saveToUserId:user.userId];
      }
    }
  }
}

#pragma mark - Backup

//! Delegate on success
- (void)_didBackupUserData
{
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(_didBackupUserData) withObject:nil waitUntilDone:NO];
    return;
  }

  if(self.delegate && [self.delegate respondsToSelector:@selector(backupManagerDidBackupUserData:)])
  {
    [self.delegate backupManagerDidBackupUserData:self];
  }
}

//! Delegate on failure
- (void)_didFailToBackupUserDataWithError:(NSError *)error
{
  if ([NSThread isMainThread] == NO)
  {
    [self performSelectorOnMainThread:@selector(_didFailToBackupUserDataWithError:) withObject:error waitUntilDone:NO];
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
  LWE_ASSERT_EXC(([NSThread isMainThread] == NO),@"This method should be run from the BG.");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // Make & serialized the dictionary
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [self _updateStatus:NSLocalizedString(@"Backing Up Sets",@"Backing Up Sets")];
  dict = [self _dictionaryForUserSetsWithDictionary:dict];
  [self _updateStatus:NSLocalizedString(@"Backing Up Progress",@"Backing Up Progress")];
  dict = [self _dictionaryForUserHistoryWithDictionary:dict];
  [self _updateStatus:NSLocalizedString(@"Compressing",@"Compressing")];
  NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:dict];
  
  // Perform the request
  [self _updateStatus:NSLocalizedString(@"Sending",@"Sending")];
  ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:BackupManagerBackupURL]];
  request.userInfo = [NSDictionary dictionaryWithObject:BMBackup forKey:BMRequestType];
  request.delegate = self;
  request.downloadProgressDelegate = self;

  [request setPostValue:[self _stringForFlashType] forKey:BMFlashType];
  [request setData:archivedData forKey:BMBackupFilename];
  [request startAsynchronous];

  [pool release];
}

//! Returns an NSData containing the serialized associative array
- (NSMutableDictionary*) _dictionaryForUserSetsWithDictionary:(NSMutableDictionary *)cardDict
{
  NSArray *tags = [TagPeer retrieveUserTagList];
  NSInteger totalCount = [tags count];
  NSInteger i = 0;
  for (Tag *tag in tags)
  {
    // Report the progress of the retrieve/serialize to the delegate
    i++;
    CGFloat progress = ((CGFloat)i/(CGFloat)totalCount);
    [self _updateProgress:[NSNumber numberWithFloat:progress]];
    
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

  return cardDict;
}

- (NSMutableDictionary *)_dictionaryForUserHistoryWithDictionary:(NSMutableDictionary *)dict
{
  // Get all users, then iterate each's UserHistory and add it as another key to the dictionary
  NSArray *users = [UserPeer allUsers];
  for (User *user in users)
  {
    [dict setObject:[user studyHistories] forKey:[user historyArchiveKey]];
  }
  return dict;
}

#pragma mark - ASIHTTPRequest Response

//! This is the ASIProgresssDelegate call for getting the status of the request
- (void)setProgress:(float)newProgress
{
  // We just pass it on - our _updateProgress method is smart about how to show it.
  [self _updateProgress:[NSNumber numberWithFloat:newProgress]];
}

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
      [self _didFailToBackupUserDataWithError:error];
    }
    else if ([responseType isEqualToString:BMRestore])
    {
      [self _didFailToRestoreUserDataWithError:error];
    }
    return;
  }

  if ([responseType isEqualToString:BMBackup])
  {
    [self _didBackupUserData];
  }
  else if ([responseType isEqualToString:BMRestore])
  {
    [self performSelectorInBackground:@selector(_installDataFromResponse:) withObject:request];
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  NSString *responseType = [[request userInfo] objectForKey:BMRequestType];
  NSError *error = [request error];
  
  if ([responseType isEqualToString:BMBackup])
  {
    [self _didFailToBackupUserDataWithError:error];
  }
  else if ([responseType isEqualToString:BMRestore])
  {
    [self _didFailToRestoreUserDataWithError:error];
  }
}

@end

NSString * const LWEBackupManagerErrorDomain  = @"LWEBackupManagerErrorDomain";