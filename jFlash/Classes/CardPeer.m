#import "CardPeer.h"

@implementation CardPeer

//--------------------------------------------------------------------------
// NSMutableArray searchCardsForKeyword
// Returns an array of Cards for a given search string
//--------------------------------------------------------------------------
+ (NSMutableArray*) searchCardsForKeyword: (NSString*) keyword doSlowSearch:(BOOL)slowSearch
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSMutableArray *cardList = [[[NSMutableArray alloc] init] autorelease];
  NSString* sql;
  FMResultSet *rs;
  NSString* keywordWildcard;
  
  if (!slowSearch){
    int queryLimit = 100;
    int queryLimit2;
    keywordWildcard = [keyword stringByReplacingOccurrencesOfString:@"?" withString:@"*"];

    // Do the search using SQLite FTS (PTAG results)
    sql = [NSString stringWithFormat:@""
           "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id FROM cards c, cards_html ch "
           "WHERE c.card_id = ch.card_id AND c.card_id in (SELECT card_id FROM cards_search_content WHERE content MATCH '%@' AND ptag = 1 LIMIT %d) "
           "ORDER BY c.headword", keywordWildcard, queryLimit];
    rs = [[db dao] executeQuery:sql];
    int cardListCount = 0;
    while ([rs next]) {
      cardListCount++;
      Card* tmpCard = [[[Card alloc] init] autorelease];
      [tmpCard hydrate:rs];
      [cardList addObject: tmpCard];
    }

    if(cardListCount < queryLimit)
      queryLimit2 = (queryLimit-cardListCount)+queryLimit;
    else
      queryLimit2 = queryLimit;
      
    // Do the search using SQLite FTS (NON-PTAG results)
    sql = [NSString stringWithFormat:@""
           "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id FROM cards c, cards_html ch "
           "WHERE c.card_id = ch.card_id AND c.card_id in (SELECT card_id FROM cards_search_content WHERE content MATCH '%@' AND ptag = 0 LIMIT %d) "
           "ORDER BY c.headword", keywordWildcard, queryLimit2];
    rs = [[db dao] executeQuery:sql];
    while ([rs next]) {
      Card* tmpCard = [[[Card alloc] init] autorelease];
      [tmpCard hydrate:rs];
      [cardList addObject: tmpCard];
    }
    [rs close];
  }
  else
  {
    // Do slow substring match (w/ ASTERISK)
    keywordWildcard = [keyword stringByReplacingOccurrencesOfString:@" " withString:@"* "];
    sql = [NSString stringWithFormat:@""
           "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id FROM cards c, cards_html ch "
           "WHERE c.card_id = ch.card_id AND c.card_id in (SELECT card_id FROM cards_search_content WHERE content MATCH '%@*' AND ptag = 0 LIMIT %d) "
           "ORDER BY c.headword", keywordWildcard, 200];
    rs = [[db dao] executeQuery:sql];
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
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = '%d'",setId];
	FMResultSet *rs = [[db dao] executeQuery:sql];
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
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  while ([db dao].inUse && i < 5)
  {
    LWE_LOG(@"Database is busy %d",i);
    usleep(100);
    i++;
  }
  FMResultSet *rs = [[db dao] executeQuery:sql];
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
  NSString *sql = [[NSString alloc] initWithFormat:@""
      "SELECT c.card_id AS card_id,u.card_level as card_level,u.user_id as user_id,u.wrong_count as wrong_count,u.right_count as right_count,c.headword,c.headword_en,c.reading,c.romaji,ch.meaning "
      "FROM cards c INNER JOIN cards_html ch ON c.card_id = ch.card_id LEFT OUTER JOIN user_history u ON c.card_id = u.card_id AND u.user_id = '%d' "
      "WHERE c.card_id = ch.card_id AND c.card_id = '%d'",[settings integerForKey:@"user_id"], cardId];
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
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql = [[NSString alloc] initWithFormat:@""
                   "SELECT c.card_id AS card_id,u.card_level as card_level,u.user_id as user_id,u.wrong_count as wrong_count,u.right_count as right_count,c.headword,c.headword_en,c.reading,c.romaji,ch.meaning "
                   "FROM cards c INNER JOIN cards_html ch ON c.card_id = ch.card_id LEFT OUTER JOIN user_history u ON c.card_id = u.card_id AND u.user_id = '%d' "
                   "WHERE c.card_id = ch.card_id AND c.card_id = '%d'",[settings integerForKey:@"user_id"], [card cardId]];
  FMResultSet *rs = [[db dao] executeQuery:sql];
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
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  Card *tmpCard;
	NSString *sql, *sql2;
  sql = [[NSString alloc] initWithFormat:@""
      "SELECT card_level,u.card_id AS card_id,u.wrong_count as wrong_count,u.right_count as right_count "
      "FROM card_tag_link l, user_history u WHERE u.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d' "
      "AND u.card_level = '%d' LIMIT 1 OFFSET %d",setId,[settings integerForKey:@"user_id"],levelId,randomNum];
  int cardId = 0;
  int cardLevel = 0;
  int wrongCount = 0;
  int rightCount = 0;
  FMResultSet *rs = [[db dao] executeQuery:sql];
  while ([rs next])
  {
    cardId     = [rs intForColumn:@"card_id"];
    cardLevel  = [rs intForColumn:@"card_level"];
    wrongCount = [rs intForColumn:@"wrong_count"];
    rightCount = [rs intForColumn:@"right_count"];
  }
  [rs close];
  sql2 =  [[NSString alloc] initWithFormat:@""
    "SELECT %d as card_level, %d AS wrong_count, %d AS right_count, %d AS user_id, * "
    "FROM cards WHERE card_id = '%d'",cardLevel,wrongCount,rightCount,[settings integerForKey:@"user_id"],cardId];
  FMResultSet *rs2 = [[db dao] executeQuery:sql2];
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
// NSMutableArray* retrieveCardSet: setId
// Returns an array of Cards for a given tag
//--------------------------------------------------------------------------
+ (NSMutableArray*) retrieveCardSetWithSQL: (NSString*) sql hydrate:(BOOL)hydrate
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  FMResultSet *rs = [[db dao] executeQuery:sql];
  Card* tmpCard;
  NSMutableArray *cardList = [[[NSMutableArray alloc] init] autorelease];
  int i = 0;
  while ([rs next])
  {
    i++;
    tmpCard = [[Card alloc] init];
    if (hydrate)
    {
      [tmpCard hydrate:rs];
    }
    else
    {
      [tmpCard setCardId:[rs intForColumn:@"card_id"]];
    }
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
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSMutableArray *cardIdList = [[[NSMutableArray alloc] init] autorelease];
  for(int i = 0; i < 6; i++)
  {
    [cardIdList addObject:[[[NSMutableArray alloc] init] autorelease]];
  }
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT l.card_id AS card_id,u.card_level as card_level "
"FROM card_tag_link l LEFT OUTER JOIN user_history u ON u.card_id = l.card_id AND u.user_id = '%d' WHERE l.tag_id = '%d'",[settings integerForKey:@"user_id"],tagId];
  FMResultSet *rs = [[db dao] executeQuery:sql];
  while ([rs next])
  {
    [[cardIdList objectAtIndex:[rs intForColumn:@"card_level"]] addObject:[NSNumber numberWithInt:[rs intForColumn:@"card_id"]]];
  }
  [rs close];
  [sql release];
  return cardIdList;
}

//--------------------------------------------------------------------------
// NSMutableArray* retrieveCardIdsForTagId: tagId
// Returns an array of Cards ids for a given set
//--------------------------------------------------------------------------
+ (NSMutableArray*) retrieveCardIdsForTagId: (NSInteger)tagId
{
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = '%d'",tagId];
  NSMutableArray *cardList = [CardPeer retrieveCardSetWithSQL:sql hydrate:NO];
  [sql release];
  return cardList;
}


//--------------------------------------------------------------------------
// NSMutableArray* retrieveCardSet: setId
// Returns an array of Cards for a given tag
//--------------------------------------------------------------------------
+ (NSMutableArray*) retrieveCardSet: (NSInteger) tagId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql = [[NSString alloc] initWithFormat:@""
        "SELECT c.card_id AS card_id,u.user_id as user_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count,c.headword,c.headword_en,c.reading,c.romaji,ch.meaning "
        "FROM cards c, cards_html ch, card_tag_link l, user_history u WHERE c.card_id = ch.card_id AND c.card_id = u.card_id AND "
        "c.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d'",tagId,[settings integerForKey:@"user_id"]];
  NSMutableArray *cardList = [CardPeer retrieveCardSetWithSQL:sql hydrate:YES];
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
  NSString *sql = [[NSString alloc] initWithFormat:@""
        "SELECT c.card_id AS card_id,u.user_id as user_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count,c.headword,c.headword_en,c.reading,c.romaji,ch.meaning "
        "FROM cards c, cards_html ch, card_tag_link l, user_history u WHERE c.card_id = ch.card_id AND c.card_id = u.card_id "
        "AND c.card_id = l.card_id AND u.user_id = '%d' AND l.tag_id = '%d' AND u.card_level = '%d'",[settings integerForKey:@"user_id"],setId,levelId];
  NSMutableArray *cardList = [CardPeer retrieveCardSetWithSQL:sql hydrate:YES];
	[sql release];
	return cardList;
}


@end