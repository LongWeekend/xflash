#import "CardPeer.h"
#import "JapaneseCard.h"
#import "ChineseCard.h"

@implementation CardPeer

/**
 * Factory that cares about what language we are using
 */
+ (Card *) blankCard
{
#if defined(LWE_JFLASH)
  return [[[JapaneseCard alloc] init] autorelease];
#elif defined(LWE_CFLASH)
  return [[[ChineseCard alloc] init] autorelease];
#else
  return nil;
#endif
}

/**
 * Returns an array of Card objects after searching keyword
 */
+ (NSMutableArray*) searchCardsForKeyword: (NSString*) keyword doSlowSearch:(BOOL)slowSearch
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSMutableArray *cardList = [NSMutableArray array];
  NSString *sql = nil;
  FMResultSet *rs = nil;
  NSString *keywordWildcard = nil;
  
  if (!slowSearch)
  {
    int queryLimit = 100;
    int queryLimit2;
    keywordWildcard = [keyword stringByReplacingOccurrencesOfString:@"?" withString:@"*"];

    // Do the search using SQLite FTS (PTAG results)
    sql = [NSString stringWithFormat:@""
           "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id, 0 as wrong_count, 0 as right_count FROM cards c, cards_html ch "
           "WHERE c.card_id = ch.card_id AND c.card_id in (SELECT card_id FROM cards_search_content WHERE content MATCH '%@' AND ptag = 1 LIMIT %d) "
           "ORDER BY c.headword", keywordWildcard, queryLimit];
    rs = [db executeQuery:sql];
    int cardListCount = 0;
    while ([rs next])
    {
      cardListCount++;
      Card *tmpCard = [CardPeer blankCard];
      [tmpCard hydrate:rs];
      [cardList addObject: tmpCard];
    }

    if(cardListCount < queryLimit)
    {
      queryLimit2 = (queryLimit-cardListCount)+queryLimit;
    }
    else
    {
      queryLimit2 = queryLimit;
    }
    
    // Do the search using SQLite FTS (NON-PTAG results)
    sql = [NSString stringWithFormat:@""
           "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id, 0 as wrong_count, 0 as right_count FROM cards c, cards_html ch "
           "WHERE c.card_id = ch.card_id AND c.card_id in (SELECT card_id FROM cards_search_content WHERE content MATCH '%@' AND ptag = 0 LIMIT %d) "
           "ORDER BY c.headword", keywordWildcard, queryLimit2];
    rs = [db executeQuery:sql];
    while ([rs next])
    {
      Card *tmpCard = [CardPeer blankCard]; // [[[Card alloc] init] autorelease];
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
           "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id, 0 as wrong_count, 0 as right_count FROM cards c, cards_html ch "
           "WHERE c.card_id = ch.card_id AND c.card_id in (SELECT card_id FROM cards_search_content WHERE content MATCH '%@*' AND ptag = 0 LIMIT %d) "
           "ORDER BY c.headword", keywordWildcard, 200];
    rs = [db executeQuery:sql];
    while ([rs next])
    {
      Card *tmpCard = [CardPeer blankCard];
      [tmpCard hydrate:rs];
      [cardList addObject:tmpCard];
    }
    [rs close];
  }
  
	return cardList;
}


/**
 * Returns single card from SQL result - assumes 1 record, if multiple, will take last record
 */ 
+ (Card*) retrieveCardWithSQL: (NSString*) sql
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  FMResultSet *rs = [db executeQuery:sql];
  Card *tmpCard = [CardPeer blankCard];
  while ([rs next])
  {
    [tmpCard hydrate:rs];
  }
  [rs close];
  return tmpCard;
}


/**
 * Takes a cardId and returns a hydrated Card from the database
 */
+ (Card*) retrieveCardByPK:(NSInteger)cardId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql = [[NSString alloc] initWithFormat:@""
      "SELECT c.card_id AS card_id,u.card_level as card_level,u.user_id as user_id,"
             "u.wrong_count as wrong_count,u.right_count as right_count,c.headword,c.headword_en,c.reading,c.romaji,ch.meaning "
      "FROM cards c INNER JOIN cards_html ch ON c.card_id = ch.card_id LEFT OUTER JOIN user_history u ON c.card_id = u.card_id AND u.user_id = '%d' "
      "WHERE c.card_id = ch.card_id AND c.card_id = '%d'",[settings integerForKey:@"user_id"], cardId];
  Card *tmpCard = [CardPeer retrieveCardWithSQL:sql];
  [sql release];
  return tmpCard;
}


/**
 * Takes a Card object with cardId set, returns a hydrated Card
 */
+ (Card*) hydrateCardByPK:(Card*)card
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql = [[NSString alloc] initWithFormat:@""
                   "SELECT c.card_id AS card_id,u.card_level as card_level,u.user_id as user_id,u.wrong_count as wrong_count,u.right_count as right_count, "
                          "c.headword,c.headword_en,c.reading,c.romaji,ch.meaning "
                   "FROM cards c INNER JOIN cards_html ch ON c.card_id = ch.card_id LEFT OUTER JOIN user_history u ON c.card_id = u.card_id AND u.user_id = '%d' "
                   "WHERE c.card_id = ch.card_id AND c.card_id = '%d'",[settings integerForKey:@"user_id"], [card cardId]];
  FMResultSet *rs = [db executeQuery:sql];
  while ([rs next])
  {
    [card hydrate:rs];
//    [card setHeadword:[rs stringForColumn:@"headword"]];
//    [card setHeadword_en:[rs stringForColumn:@"headword_en"]];
//    [card setReading:[rs stringForColumn:@"reading"]];
//    [card setRomaji:[rs stringForColumn:@"romaji"]];
//    [card setMeaning:[rs stringForColumn:@"meaning"]];
  }
  [rs close];
  [sql release];
  return card;
}


/**
 * Returns single Card from a Tag by a specified level
 */
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
  FMResultSet *rs = [db executeQuery:sql];
  while ([rs next])
  {
    cardId     = [rs intForColumn:@"card_id"];
    cardLevel  = [rs intForColumn:@"card_level"];
    wrongCount = [rs intForColumn:@"wrong_count"];
    rightCount = [rs intForColumn:@"right_count"];
  }
  [rs close];
  sql2 = [[NSString alloc] initWithFormat:@""
    "SELECT %d as card_level, %d AS wrong_count, %d AS right_count, %d AS user_id, * "
    "FROM cards WHERE card_id = '%d'",cardLevel,wrongCount,rightCount,[settings integerForKey:@"user_id"],cardId];
  FMResultSet *rs2 = [db executeQuery:sql2];
  [sql2 release];
  tmpCard = [CardPeer blankCard];
  while ([rs2 next])
  {
    [tmpCard hydrate:rs2];
  }
  [rs2 close];
	[sql release];
	return tmpCard;
}


/**
 * Calls retrieveCardSetWithSQL:hydrate:isBasicCard where basic card is set to NO
 * This is here for legacy reasons only, could be refactored out later
 * TODO
 */
+ (NSMutableArray*) retrieveCardSetWithSQL: (NSString*) sql hydrate:(BOOL)hydrate 
{
  return [CardPeer retrieveCardSetWithSQL:sql hydrate:hydrate isBasicCard:NO];
}


/**
 * Returns an array of Card objects based on SQL result
 */
+ (NSMutableArray*) retrieveCardSetWithSQL: (NSString*) sql hydrate:(BOOL)hydrate isBasicCard:(BOOL)basicCard
{
	LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db executeQuery:sql];
	Card *tmpCard = nil;
	NSMutableArray *cardList = [NSMutableArray array];
	while ([rs next])
	{
		// Full card?
    tmpCard = [CardPeer blankCard];
    tmpCard.isBasicCard = basicCard;
		
		// Hydrate?
		if (hydrate)
		{
			[tmpCard hydrate:rs];
		}
		else
		{
      tmpCard.cardId = [rs intForColumn:@"card_id"];
		}
		[cardList addObject:tmpCard];
	}
	[rs close];
	return cardList;
}


/**
 * Returns an array of Card ids for a given tagId
 */
+ (NSMutableArray*) retrieveCardIdsSortedByLevel: (NSInteger) tagId
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
  FMResultSet *rs = [db executeQuery:sql];
  while ([rs next])
  {
    [[cardIdList objectAtIndex:[rs intForColumn:@"card_level"]] addObject:[NSNumber numberWithInt:[rs intForColumn:@"card_id"]]];
  }
  [rs close];
  [sql release];
  return cardIdList;
}


/**
 * Returns an array containing cardId integers contained in by the Tag tagId
 */
+ (NSMutableArray*) retrieveCardIdsForTagId: (NSInteger)tagId
{
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = '%d'",tagId];
  NSMutableArray *cardList = [CardPeer retrieveCardSetWithSQL:sql hydrate:NO];
  [sql release];
  return cardList;
}


/**
 * Returns an array containng cardId integers that are linked to the sentence
 * \param sentenceId Primary key of the sentence to look up cards for
 */
+ (NSMutableArray*) retrieveCardSetForSentenceId: (NSInteger) sentenceId
{
	//TODO: This is probably too slow
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT c.*, h.* FROM card_sentence_link l, cards c, cards_html h WHERE c.card_id = h.card_id AND c.card_id = l.card_id AND l.sentence_id = '%d'", sentenceId];
  NSMutableArray *cardList = [CardPeer retrieveCardSetWithSQL:sql hydrate:YES isBasicCard:YES];
  [sql release];
  return cardList;  
}


/**
 * Returns an array containng cardId integers that are linked to the sentence
 * \param sentenceId Primary key of the sentence to look up cards for
 * \param showAll Determines whether to get all links or just trimmed links
 *
 * The difference with the method above is the query performed. This should be faster since it only asks for the data required. 
 *
 */
+ (NSMutableArray*) retrieveCardSetForExampleSentenceID: (NSInteger) sentenceId showAll:(BOOL)showAll
{	
	NSString *sql = nil;
  if (showAll)
  {
    sql = [[NSString alloc] initWithFormat:@"SELECT c.card_id, c.headword, c.reading, c.romaji FROM card_sentence_link l, cards c WHERE l.card_id = c.card_id AND sentence_id = '%d'", sentenceId];
  }
  else
  {
    sql = [[NSString alloc] initWithFormat:@"SELECT c.card_id, c.headword, c.reading, c.romaji FROM card_sentence_link l, cards c WHERE l.card_id = c.card_id AND sentence_id = '%d' AND l.should_show = '1'", sentenceId];
  }
	LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db executeQuery:sql];
  [sql release];
	
	NSMutableArray *cardList = [NSMutableArray array];
	while ([rs next])
	{
		Card *tmpCard = [CardPeer blankCard];
    tmpCard.isBasicCard = YES;
		[tmpCard simpleHydrate:rs];
		[cardList addObject: tmpCard];
	}
	[rs close];

	return cardList; 
}





/**
 * Returns an array of Card objects in the Tag given by tagId
 */
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


/**
 * Returns an array of Card objects matching a given tagId and levelId
 */
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