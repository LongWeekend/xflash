//
//  UserHistoryPeer.m
//  jFlash
//
//  Created by シャロット ロス on 5/6/09.//WIP
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//
#import "UserHistoryPeer.h"
#import "CardPeer.h"

@implementation UserHistoryPeer

//--------------------------------------------------------------------------
// (NSArray*) getSetRightWrongTotals: (int)cardId
// Returns the right and wrong totals
//--------------------------------------------------------------------------
+ (NSArray*) getRightWrongTotalsBySet: (NSInteger)tagId
{
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql  = [[NSString alloc] initWithFormat:@"SELECT sum(right_count) FROM user_history WHERE user_id = %d AND tag_id = %d", [settings integerForKey:@"user_id"], tagId];
  NSString *sql2 = [[NSString alloc] initWithFormat:@"SELECT sum(wrong_count) as TotalWrong FROM user_history WHERE user_id = %d AND tag_id = %d", [settings integerForKey:@"user_id"], tagId];
  int right = [[appSettings dao] intForQuery:sql];
  int wrong = [[appSettings dao] intForQuery:sql2];
  NSNumber *rightCount = [[NSNumber alloc] initWithInt:right];
  NSNumber *wrongCount = [[NSNumber alloc] initWithInt:wrong];
  NSArray* results = [NSArray arrayWithObjects: rightCount, wrongCount, nil];
  [rightCount release];
  [wrongCount release];
  [sql release];
  [sql2 release];
  return results;
}

//--------------------------------------------------------------------------
// + (int) getNextAfterLevel:(int) level gotItRight: (BOOL)gotItRight
// Returns what the next level should be based on the user's answer
//--------------------------------------------------------------------------
+ (int) getNextAfterLevel:(int)level gotItRight: (BOOL)gotItRight
{
  if (gotItRight)
  {
    // User got it right
    if (level >= 1 && level < 5)
    {
      level++;
      return level;
    }
    // if the get an unseen card right it should go into the "Right 1x" bucket
    else if (level == 0)
    {
       return 2;
    }
    else return 5;
  }
  else
  {
    // User got it wrong, put it at 1
    return 1;
  }
}


//--------------------------------------------------------------------------
// (void) recordResult: (Card*)card withTagId:(int)tagId gotItRight:(BOOL) gotItRight knewIt:(BOOL) knewIt
// Updates the database based on the user's answer
//--------------------------------------------------------------------------

+ (void) recordResult: (Card*)card gotItRight:(BOOL) gotItRight knewIt:(BOOL) knewIt
{
  // Get database singleton
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

  NSString *sql;
  int nextLevel = 0;
//UNUSED  int oldLevel = card.levelId;
  
  // Get the card_level counter cache
  // int oldLevelCount = ;
  // int nextLevelCount = ;

  // Get the next level
  if (knewIt)
  {
    nextLevel = 5;
  }
  else
  {
    nextLevel = [self getNextAfterLevel:card.levelId gotItRight:gotItRight];
  }

  // Did we get it right?
  if (gotItRight)
  {
    // int oldNextLevel
    sql = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO user_history (card_id,timestamp,created_on,user_id,right_count,wrong_count,card_level) VALUES ('%d',current_timestamp,current_timestamp,'%d','%d','%d','%d')",card.cardId,[settings integerForKey:@"user_id"],(card.rightCount+1),card.wrongCount,nextLevel];
  }
  else
  {
    // int
    sql = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO user_history (card_id,timestamp,created_on,user_id,right_count,wrong_count,card_level) VALUES ('%d',current_timestamp,current_timestamp,'%d','%d','%d','%d')",card.cardId,[settings integerForKey:@"user_id"],card.rightCount,(card.wrongCount+1),nextLevel];      
  }
  //sql2 = [[NSString alloc] initWithFormat: @"INSERT OR REPLACE INTO tag_user_card_levels SET card_level_%@_count = %@", oldLevel, oldLevelCount, nextLevel, nextLevelCount];
  [appSettings.dao executeUpdate:sql];
  [sql release];
  [[appSettings activeSet] updateLevelCounts:card nextLevel:nextLevel];
}


@end