//
//  UserHistory.m
//  xFlash
//
//  Created by Mark Makdad on 5/6/12.
//  Copyright (c) 2012 Long Weekend LLC. All rights reserved.
//

#import "UserHistory.h"

@implementation UserHistory

@synthesize cardId, rightCount, wrongCount, cardLevel, lastUpdated, createdAt;

+(UserHistory *)userHistoryWithResultSet:(FMResultSet *)rs
{
  UserHistory *history = [[[UserHistory alloc] init] autorelease];
  history.cardId = [rs intForColumn:@"card_id"];
  history.rightCount = [rs intForColumn:@"right_count"];
  history.wrongCount = [rs intForColumn:@"wrong_count"];
  history.cardLevel = [rs intForColumn:@"card_level"];
  return history;
}

- (void) dealloc
{
  [lastUpdated release];
  [createdAt release];
  [super dealloc];
}

@end
