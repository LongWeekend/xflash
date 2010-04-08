#import "CardPeer.h"

@implementation CardPeer

//--------------------------------------------------------------------------
// NSMutableArray searchCardsForKeyword
// Returns an array of Cards for a given search string
//--------------------------------------------------------------------------
+ (NSMutableArray*) searchCardsForKeyword: (NSString*) keyword doSlowSearch:(BOOL)slowSearch
{
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  NSMutableArray *cardList = [[[NSMutableArray alloc] init] autorelease];
  NSString* sql;
  FMResultSet *rs;

  if (!slowSearch){
    // Do the search using SQLite FTS
    sql = [NSString stringWithFormat:@"SELECT c.*, 0 as card_level, 0 as user_id FROM cards_search_content csc INNER JOIN cards c ON csc.card_id = c.card_id WHERE csc.content MATCH '%@' ORDER BY csc.ptag DESC, c.headword LIMIT 200",keyword];
        //sql = [NSString stringWithFormat:@"SELECT c.*, 0 as card_level, 0 as user_id FROM cards_search_content csc INNER JOIN cards c ON csc.card_id = c.card_id WHERE csc.content MATCH '%@' AND csc.ptag = 1 LIMIT 150",keyword];
    rs = [appSettings.dao executeQuery:sql];
    while ([rs next]) {
      Card* tmpCard = [[[Card alloc] init] autorelease];
      [tmpCard hydrate:rs];
      [cardList addObject: tmpCard];
    }
    [rs close];
  }
  else
  {
    // Do slow substring match (w/ LIKE)
    sql = [NSString stringWithFormat:@"SELECT card_id,headword,reading,meaning,romaji,0 as card_level,0 as user_id FROM cards WHERE headword LIKE '%%%@%%' OR headword_en LIKE '%%%@%%' OR reading LIKE '%%%@%%' ORDER BY headword LIMIT 100",keyword,keyword,keyword];
    rs = [appSettings.dao executeQuery:sql];
    while ([rs next])
    {
      Card* tmpCard = [[[Card alloc] init] autorelease];
      [tmpCard hydrate:rs];
      [cardList addObject: tmpCard];
    }
    [rs close];
  }
  
	return cardList;
}


//--------------------------------------------------------------------------
// NSString retrieveCsvCardIdsForTag
// Returns a CSV string of card Ids for a given tag
//--------------------------------------------------------------------------
+ (NSString*) retrieveCsvCardIdsForTag: (NSInteger)setId
{
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = '%d'",setId];
	FMResultSet *rs = [appSettings.dao executeQuery:sql];
	NSString *outputStr = [[[NSString alloc] init] autorelease];
  int cardId;
  BOOL firstTime = YES;
	while ([rs next])
  {
    cardId = [rs intForColumn:@"card_id"];
    if (firstTime == YES)
    {
      outputStr = [outputStr stringByAppendingFormat:@"%d",cardId];
      firstTime = NO;
    }
    else {
      outputStr = [outputStr stringByAppendingFormat:@",%d",cardId];
    }
  }
	[rs close];
  [sql release];
	return outputStr;
}


//--------------------------------------------------------------------------
// Card* retrieveCardWithSQL: sql
// Returns single card with SQL - assumes 1 record, if multiple, will take last record
//--------------------------------------------------------------------------
+ (Card*) retrieveCardWithSQL: (NSString*) sql
{
  int i = 0;
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  while (appSettings.dao.inUse && i < 5)
  {
    NSLog(@"Database is busy %d",i);
    usleep(100);
    i++;
  }
  FMResultSet *rs = [appSettings.dao executeQuery:sql];
  Card* tmpCard = [[[Card alloc] init] autorelease];
  while ([rs next])
  {
    [tmpCard hydrate:rs];
  }
  [rs close];
  return tmpCard;
}


//--------------------------------------------------------------------------
// Card* retrieveCardByPK: cardId
// Returns single card by PK
//--------------------------------------------------------------------------
+ (Card*) retrieveCardByPK: (NSInteger)cardId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT c.card_id AS card_id,u.card_level as card_level,u.user_id as user_id,u.wrong_count as wrong_count,u.right_count as right_count,headword,headword_en,reading,meaning,romaji FROM cards c, user_history u WHERE c.card_id = u.card_id AND u.user_id = '%d' AND c.card_id = '%d'",[settings integerForKey:@"user_id"], cardId];
  Card* tmpCard = [CardPeer retrieveCardWithSQL:sql];
	[sql release];
	return tmpCard;
}


//--------------------------------------------------------------------------
// Card* hydrateCardByPK: card
// Hydrates a card
//--------------------------------------------------------------------------
+ (Card*) hydrateCardByPK: (Card*) card
{
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT c.card_id AS card_id,u.card_level as card_level,u.user_id as user_id,u.wrong_count as wrong_count,u.right_count as right_count,headword,headword_en,reading,meaning,romaji FROM cards c, user_history u WHERE c.card_id = u.card_id AND u.user_id = '%d' AND c.card_id = '%d'",[settings integerForKey:@"user_id"], [card cardId]];
  FMResultSet *rs = [appSettings.dao executeQuery:sql];
  while ([rs next])
  {
    [card setHeadword:[rs stringForColumn:@"headword"]];
    [card setHeadword_en:[rs stringForColumn:@"headword_en"]];
    [card setReading:[rs stringForColumn:@"reading"]];
    [card setRomaji:[rs stringForColumn:@"romaji"]];
    [card setMeaning:[rs stringForColumn:@"meaning"]];
  }
  [rs close];
	[sql release];
	return card;
}


//--------------------------------------------------------------------------
// Card* retrieveCardByLevel: levelId setId: setId
// Returns single card from a set by a level
//--------------------------------------------------------------------------
+ (Card*) retrieveCardByLevel: (NSInteger)levelId setId: (NSInteger)setId withRandom: (NSInteger) randomNum
{
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  Card *tmpCard;
	NSString *sql, *sql2;
  sql = [[NSString alloc] initWithFormat:@"SELECT card_level,u.card_id AS card_id,u.wrong_count as wrong_count,u.right_count as right_count FROM card_tag_link l, user_history u WHERE u.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d' AND u.card_level = '%d' LIMIT 1 OFFSET %d",setId,[settings integerForKey:@"user_id"],levelId,randomNum];
  int cardId = 0;
  int cardLevel = 0;
  int wrongCount = 0;
  int rightCount = 0;
  FMResultSet *rs = [appSettings.dao executeQuery:sql];
  while ([rs next])
  {
    cardId     = [rs intForColumn:@"card_id"];
    cardLevel  = [rs intForColumn:@"card_level"];
    wrongCount = [rs intForColumn:@"wrong_count"];
    rightCount = [rs intForColumn:@"right_count"];
  }
  [rs close];
  sql2 =  [[NSString alloc] initWithFormat:@"SELECT %d as card_level, %d AS wrong_count, %d AS right_count, %d AS user_id, * FROM cards WHERE card_id = '%d'",cardLevel,wrongCount,rightCount,[settings integerForKey:@"user_id"],cardId];
  FMResultSet *rs2 = [appSettings.dao executeQuery:sql2];
  tmpCard = [[[Card alloc] init] autorelease];
  while ([rs2 next])
  {
    [tmpCard hydrate:rs2];
  }
  [rs2 close];
	[sql release];
	return tmpCard;
}


//--------------------------------------------------------------------------
// int retrieveCardCountByLevel: setId levelId: levelId
// Returns the number of cards in each level by set
//--------------------------------------------------------------------------
+ (NSInteger) retrieveCardCountByLevel: (NSInteger)setId levelId:(NSInteger)levelId
{
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  // Variable decs
  int i = -1;
  NSString *sql = nil;
  FMResultSet *rs = nil;

  // Check the cache table
  sql = [[NSString alloc] initWithFormat:@"SELECT count FROM tag_level_count_cache WHERE tag_id = '%d' AND user_id = '%d' AND card_level = '%d'",setId,[settings integerForKey:@"user_id"],levelId];
  rs = [[appSettings dao] executeQuery:sql];
  while ([rs next])
  {
    i = [rs intForColumn:@"count"];
  }
  [rs close]; 
  [sql release];
  // If cache does not exist
  if (i < 0)
  {
    LWE_LOG(@"Cache does not exist, must create from database");
    
    NSLog(@"START NORMAL ----------------------------------------");
    sql = [[NSString alloc] initWithFormat:@"SELECT COUNT(l.card_id) as card_count FROM card_tag_link l, user_history u WHERE l.card_id = u.card_id AND l.tag_id = '%d' AND u.user_id = '%d' AND u.card_level = '%d'",setId,[settings integerForKey:@"user_id"],levelId];
    rs = [[appSettings dao] executeQuery:sql];
    while ([rs next])
    {
      i = [rs intForColumn:@"card_count"];
    }
    [rs close]; 
    [sql release];
    
    /*
    NSLog(@"START SUBSELECT ----------------------------------------");
    sql = [[NSString alloc] initWithFormat:@"SELECT COUNT(card_id) as card_count FROM user_history WHERE card_id IN (SELECT card_id from card_tag_link WHERE tag_id = '%d') AND user_id = '%d' AND card_level = '%d'",setId,[settings integerForKey:@"user_id"],levelId];
    rs = [[appSettings dao] executeQuery:sql];
    while ([rs next])
     {
       i = [rs intForColumn:@"card_count"];
     }
    [rs close]; 
    [sql release];    
    NSLog(@"END SUBSELECT ----------------------------------------");
     */
    
    // Finally, cache the result
    sql = [[NSString alloc] initWithFormat:@"INSERT OR REPLACE INTO tag_level_count_cache (tag_id,user_id,card_level,count) VALUES ('%d','%d','%d','%d')",setId,[settings integerForKey:@"user_id"],levelId,i];
    [[appSettings dao] executeUpdate:sql];
    [sql release];
  }
  return i;    
}


//--------------------------------------------------------------------------
// NSMutableArray* retrieveCardSet: setId
// Returns an array of Cards for a given tag
//--------------------------------------------------------------------------
+ (NSMutableArray*) retrieveCardSetWithSQL: (NSString*) sql
{
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  FMResultSet *rs = [appSettings.dao executeQuery:sql];
  NSMutableArray *cardList = [[[NSMutableArray alloc] init] autorelease];
  int i = 0;
  while ([rs next])
  {
    i++;
    Card* tmpCard = [[Card alloc] init];
    [tmpCard hydrate:rs];
    [cardList addObject: tmpCard];
    [tmpCard release];
  }
  [rs close];
  return cardList;
}


//--------------------------------------------------------------------------
// NSMutableArray* retrieveCardSetIds: setId
// Returns an array of Card Ids for a given tag
//--------------------------------------------------------------------------
+ (NSMutableArray*) retrieveCardSetIds: (NSInteger) tagId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  NSMutableArray *cardIdList = [[[NSMutableArray alloc] init] autorelease];
  // Original
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT l.card_id AS card_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count FROM card_tag_link l, user_history u WHERE u.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d'",tagId,[settings integerForKey:@"user_id"]];
  // Variants
//  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT l.card_id AS card_id,u.user_id as user_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count FROM card_tag_link l, user_history u WHERE l.tag_id = '%d' AND u.user_id = '%d' AND u.card_id = l.card_id",tagId,[settings integerForKey:@"user_id"]];
  // Subselect
//  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT card_id,user_id,card_level,wrong_count,right_count FROM user_history u WHERE card_id IN (SELECT card_id FROM card_tag_link WHERE tag_id = '%d') AND user_id = '%d'",tagId,[settings integerForKey:@"user_id"]];
  FMResultSet *rs = [[appSettings dao] executeQuery:sql];
  while ([rs next])
  {
    Card* tmpCard = [[Card alloc] init];
    [tmpCard setCardId:[rs intForColumn:@"card_id"]];
    [tmpCard setLevelId:[rs intForColumn:@"card_level"]];
    [cardIdList addObject: tmpCard];
    [tmpCard release];
  }
  [rs close];
  [sql release];
  return cardIdList;
}

//--------------------------------------------------------------------------
// NSMutableArray* retrieveCardSetIds: setId
// Returns an array of Card Ids for a given tag
//--------------------------------------------------------------------------
+ (NSMutableArray*) retrieveCardSetIdsInLevels: (NSInteger) tagId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  NSMutableArray *cardIdList = [[[NSMutableArray alloc] init] autorelease];
  for(int i = 0; i < 6; i++)
   {
     [cardIdList insertObject:[[[NSMutableArray alloc] init] autorelease] atIndex:i];
   }
  
  
  //select out all the cards id and their level
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT l.card_id AS card_id,u.card_level as card_level FROM card_tag_link l, user_history u WHERE u.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d'",tagId,[settings integerForKey:@"user_id"]];
  FMResultSet *rs = [[appSettings dao] executeQuery:sql];
  while ([rs next])
   {    
     [[cardIdList objectAtIndex:[rs intForColumn:@"card_level"]] addObject:[NSNumber numberWithInt:[rs intForColumn:@"card_id"]]];
   }
  [rs close];
  [sql release];
  return cardIdList;
}



//--------------------------------------------------------------------------
// NSMutableArray* retrieveCardSet: setId
// Returns an array of Cards for a given tag
//--------------------------------------------------------------------------
+ (NSMutableArray*) retrieveCardSet: (NSInteger) tagId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT c.card_id AS card_id,u.user_id as user_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count,headword,headword_en,reading,meaning,romaji FROM cards c, card_tag_link l, user_history u WHERE c.card_id = u.card_id AND c.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d'",tagId,[settings integerForKey:@"user_id"]];
//  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT u.card_id AS card_id,u.user_id as user_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count FROM card_tag_link l, user_history u WHERE l.card_id = u.card_id AND l.tag_id = '%d' AND u.user_id = '%d'",tagId,[settings integerForKey:@"user_id"]];
  NSMutableArray *cardList = [CardPeer retrieveCardSetWithSQL:sql];
  [sql release];
	return cardList;
}


//--------------------------------------------------------------------------
// NSMutableArray* retrieveUnseenCards: numCards setId: setId
// Returns an array of unseen Cards for a given set
//--------------------------------------------------------------------------
+ (NSMutableArray*) retrieveUnseenCards:(NSInteger)numCards setId:(NSInteger)setId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  // TODO -- make this work like altered -- 2 stage SQL queries
  NSString* sql = [[NSString alloc] initWithFormat:@"SELECT c.card_id AS card_id,u.user_id as user_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count,headword,headword_en,reading,meaning,romaji FROM cards c, card_tag_link l, user_history u WHERE c.card_id = u.card_id AND c.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d' AND u.card_level = '0' LIMIT %d",setId,[settings integerForKey:@"user_id"],numCards];
  NSMutableArray *cardList = [CardPeer retrieveCardSetWithSQL:sql];
  [sql release];
	return cardList;  
}


//--------------------------------------------------------------------------
// NSMutableArray* retrieveCardSetByLevel: setId levelId: levelId
// Returns an array of Cards for a given set and level
//--------------------------------------------------------------------------
+ (NSMutableArray*) retrieveCardSetByLevel: (NSInteger)setId levelId:(NSInteger)levelId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT c.c ard_id AS card_id,u.user_id as user_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count,headword,headword_en,reading,meaning,romaji FROM cards c, card_tag_link l, user_history u WHERE c.card_id = u.card_id AND c.card_id = l.card_id AND u.user_id = '%d' AND l.tag_id = '%d' AND u.card_level = '%d'",[settings integerForKey:@"user_id"],setId,levelId];
  NSMutableArray *cardList = [CardPeer retrieveCardSetWithSQL:sql];
	[sql release];
	return cardList;
}

@end