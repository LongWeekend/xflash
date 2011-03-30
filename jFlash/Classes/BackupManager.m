//
//  BackupManager.m
//  jFlash
//
//  Created by Ross on 3/24/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "BackupManager.h"
#import "LWEJanrainLoginManager.h"

@implementation BackupManager

/*!
 @method     restoreUserData
 @abstract   downloads and installs the data file from the web service. Alerts for success or failure.
 */
+ (void) _restoreUserDataFromWebService 
{
  // Stop listening for a login
  [[NSNotificationCenter defaultCenter] removeObserver:self name:LWEJanrainLoginManagerUserDidAuthenticate object:nil];
  
  //  TODO: make this pull data from a web service
  //  download the userdate file
  NSData* data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"https://s3.amazonaws.com/japanese-flash/jFlashDataBackup.archive"]];
  if (data)
  {
    [BackupManager createUserSetsForData:data];
    [TagPeer recacheCountsForUserTags];
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Data Restored", @"BackupManager_DataRestored") 
                                       message:NSLocalizedString(@"Your data has been restored successfully. Enjoy Japanese Flash!", @"BackupManager_DataRestoredBody")]; 
  }
  else
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"No Backup Found", @"BackupManager_DataNotFound") 
                                       message:NSLocalizedString(@"We couldn't find a backup for you! Please login with another account or create a backup first.", @"BackupManager_DataNotFoundBody")];
  }
}

/*!
 @method     restoreUserData
 @abstract   Checks login status and either calls the private install or listens for it
 */
+ (void) restoreUserData
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

+ (int) _getTagIdForName: (NSString *) tagName AndId: (NSNumber *) key  {
  int tagId;
  if (key == [NSNumber numberWithInt:0])
    {
      tagId = 0;
    }
    else
    {
      // see if the tag already exists
      Tag* existingTag = [TagPeer retrieveTagByName:tagName];
      if (existingTag.tagId == 0) // no tag, create one
      {
        tagId = [TagPeer createTag:tagName withOwner:0];
      }
      else // just use the existing tag
      {
        tagId = existingTag.tagId;
      }
    }
  return tagId;
}
//! Takes a NSData created by serializedDataForUserSets and populates the data tables
+ (void) createUserSetsForData:(NSData*)data
{
  NSDictionary* idsDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  NSEnumerator *enumerator = [idsDict keyEnumerator];
  NSNumber* key;
  NSMutableArray* currentCardIds = [NSMutableArray array];
  
  while ((key = [enumerator nextObject])) 
  {
    NSArray* cardIdsAndTagName = [idsDict objectForKey:key];
    NSEnumerator *objEnumerator = [cardIdsAndTagName objectEnumerator];
    
    // the first oject is the tag name
    NSString* tagName = [objEnumerator nextObject];
    
    int tagId = [self _getTagIdForName: tagName AndId: key];
    
    // the rest are card ids, so add them to the tag we just made
    NSArray* cards = [CardPeer retrieveCardIdsForTagId:tagId];
    for (Card* card in cards)
    {
      [currentCardIds addObject:[NSNumber numberWithInt:card.cardId]];
    }
    
    NSNumber* newCardId;
    while ((newCardId = [objEnumerator nextObject])) 
    { 
      // add the card to the tag if it isn't already there
      if ([currentCardIds containsObject:newCardId] == NO)
      {
        [TagPeer subscribe:[newCardId intValue] tagId:tagId];
      }
    }
    [currentCardIds removeAllObjects];
  }
}

//! Returns an NSData containing the serialized associative array
+ (NSData*) serializedDataForUserSets
{
  NSMutableDictionary* cardDict = [NSMutableDictionary dictionary];
  for (Tag* tag in [TagPeer retrieveMyTagList])
  {
    NSMutableArray* cards = [CardPeer retrieveCardIdsForTagId:tag.tagId];
    NSMutableArray* cardIdsAndTagName = [NSMutableArray array];
    [cardIdsAndTagName addObject:tag.tagName];
    for (Card* card in cards)
    {
      [cardIdsAndTagName addObject:[NSNumber numberWithInt:card.cardId]];
    }
    [cardDict setObject:cardIdsAndTagName forKey:[NSNumber numberWithInt:tag.tagId]];
  }
  
  NSData* archivedData = [NSKeyedArchiver archivedDataWithRootObject:cardDict]; // serialize the cardDict
  
  return archivedData;
}

@end
