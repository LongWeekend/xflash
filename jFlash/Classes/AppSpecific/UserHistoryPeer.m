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

//! Returns what the next level should be based on the user's answer
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


//! Updates the database based on the user's answer
+ (void) recordResult: (Card*)card gotItRight:(BOOL) gotItRight knewIt:(BOOL) knewIt
{
  // Get database singleton & settings singleton
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

  NSString *sql;
  int nextLevel;

  if (knewIt)
  {
    nextLevel = 5;
  }
  else
  {
    nextLevel = [UserHistoryPeer getNextAfterLevel:card.levelId gotItRight:gotItRight];
  }

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
  [[db dao] executeUpdate:sql];
  [sql release];
  [[appSettings activeTag] updateLevelCounts:card nextLevel:nextLevel];
}


@end