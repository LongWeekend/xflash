//
//  UserHistory.m
//  xFlash
//
//  Created by Mark Makdad on 5/6/12.
//  Copyright (c) 2012 Long Weekend LLC. All rights reserved.
//

#import "UserHistory.h"

@interface UserHistory ()
- (id) _init;
@end

@implementation UserHistory

@synthesize cardId, rightCount, wrongCount, cardLevel, lastUpdated, createdAt;

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeInteger:self.cardId forKey:@"cardId"];
  [aCoder encodeInteger:self.rightCount forKey:@"rightCount"];
  [aCoder encodeInteger:self.wrongCount forKey:@"wrongCount"];
  [aCoder encodeInteger:self.cardLevel forKey:@"cardLevel"];
  [aCoder encodeObject:self.lastUpdated forKey:@"lastUpdated"];
  [aCoder encodeObject:self.createdAt forKey:@"createdAt"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self)
  {
    self.cardId = [aDecoder decodeIntegerForKey:@"cardId"];
    self.rightCount = [aDecoder decodeIntegerForKey:@"rightCount"];
    self.wrongCount = [aDecoder decodeIntegerForKey:@"wrongCount"];
    self.cardLevel = [aDecoder decodeIntegerForKey:@"cardLevel"];
    self.createdAt = [aDecoder decodeObjectForKey:@"createdAt"];
    self.lastUpdated = [aDecoder decodeObjectForKey:@"lastUpdated"];
  }
  return self;
}

#pragma mark - CRUD

+(UserHistory *)userHistoryWithResultSet:(FMResultSet *)rs
{
  UserHistory *history = [[[UserHistory alloc] _init] autorelease];
  history.cardId = [rs intForColumn:@"card_id"];
  history.rightCount = [rs intForColumn:@"right_count"];
  history.wrongCount = [rs intForColumn:@"wrong_count"];
  history.cardLevel = [rs intForColumn:@"card_level"];
  return history;
}

- (BOOL) saveToUserId:(NSInteger)userId
{
  LWE_ASSERT_EXC((self.cardId > 0),@"Must have a valid card ID");
  LWE_ASSERT_EXC((self.cardLevel >= 0),@"Must have a valid card level");
  LWE_ASSERT_EXC((userId >= 0),@"Must have a valid user ID");
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = @"INSERT OR REPLACE INTO user_history (card_id,timestamp,created_on,user_id,right_count,wrong_count,card_level) VALUES (?,?,?,?,?,?,?)";
  NSNumber *cardIdNum = [NSNumber numberWithInteger:self.cardId];
  NSNumber *rightNum = [NSNumber numberWithInteger:self.rightCount];
  NSNumber *wrongNum = [NSNumber numberWithInteger:self.wrongCount];
  NSNumber *levelNum = [NSNumber numberWithInteger:self.cardLevel];
  NSNumber *userNum = [NSNumber numberWithInteger:userId];
  return [db.dao executeUpdate:sql,cardIdNum,self.lastUpdated,self.createdAt,userNum,rightNum,wrongNum,levelNum];
}

#pragma mark - Class Plumbing

- (id) _init
{
  // We need to declare this because we've added an exception to the regular init below.
  self = [super init];
  return self;
}

- (id) init
{
  [NSException raise:NSInternalInconsistencyException format:@"Use factory method +userHistoryWithResultSet to instantiate this, or initWithCoder: by dearchiving"];
  return nil;
}

- (void) dealloc
{
  [lastUpdated release];
  [createdAt release];
  [super dealloc];
}

@end
