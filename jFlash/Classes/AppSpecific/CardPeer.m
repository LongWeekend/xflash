#import "CardPeer.h"
#import "JapaneseCard.h"
#import "ChineseCard.h"
#import "ExampleSentencePeer.h"

@interface CardPeer ()
+ (NSArray*) _retrieveCardSetWithSQL:(NSString*)sql hydrate:(BOOL)hydrate;
+ (NSString*) _FTSSQLForKeyword:(NSString*)keyword usePriorityTag:(BOOL)usePTag queryLimit:(NSInteger)limit;
+ (Card*) _retrieveCardWithSQL:(NSString*)sql;
+ (NSMutableArray*) _addCardsToList:(NSMutableArray*)cardList fromResultSet:(FMResultSet*)rs;
@end

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

#pragma mark - Search APIs

/**
 * Returns an array of Card objects after searching keyword
 */
+ (NSArray*) searchCardsForKeyword:(NSString*)keyword doSlowSearch:(BOOL)slowSearch
{
  if (slowSearch)
  {
    return [CardPeer substringSearchForKeyword:keyword];
  }
  else
  {
    return [CardPeer fullTextSearchForKeyword:keyword];
  }
}

// Do slow substring match (w/ ASTERISK)
+ (NSArray*) substringSearchForKeyword:(NSString*)keyword
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSMutableArray *cardList = [NSMutableArray array];

  NSString *keywordWildcard = [keyword stringByReplacingOccurrencesOfString:@" " withString:@"* "];
  NSString *sql = [NSString stringWithFormat:@""
         "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id, 0 as wrong_count, 0 as right_count FROM cards c, cards_html ch "
         "WHERE c.card_id = ch.card_id AND c.card_id in (SELECT card_id FROM cards_search_content WHERE content MATCH '%@*' AND ptag = 0 LIMIT %d) "
         "ORDER BY c.headword", keywordWildcard, 200];
  FMResultSet *rs = [db executeQuery:sql];
  [CardPeer _addCardsToList:cardList fromResultSet:rs];
  return (NSArray*)cardList;
}

//! Runs a search against the full text index returning 100 records
+ (NSArray*) fullTextSearchForKeyword:(NSString*)keyword
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSMutableArray *cardList = [NSMutableArray array];
  NSInteger queryLimit = 100;

  NSString *sql = [CardPeer _FTSSQLForKeyword:keyword usePriorityTag:YES queryLimit:queryLimit];
  FMResultSet *rs = [db executeQuery:sql];
  [CardPeer _addCardsToList:cardList fromResultSet:rs];

  NSInteger queryLimit2 = queryLimit;
  if ([cardList count] < queryLimit)
  {
    queryLimit2 = (queryLimit - [cardList count]) + queryLimit;
  }
  
  sql = [CardPeer _FTSSQLForKeyword:keyword usePriorityTag:NO queryLimit:queryLimit2];
  rs = [db executeQuery:sql];
  [CardPeer _addCardsToList:cardList fromResultSet:rs];
  return (NSArray*)cardList;
}

#pragma mark - Private Methods

/**
 * Looping helper - used by search
 */
+ (NSMutableArray*) _addCardsToList:(NSMutableArray*)cardList fromResultSet:(FMResultSet*)rs
{
  while ([rs next])
  {
    Card *tmpCard = [CardPeer blankCard]; 
    [tmpCard hydrate:rs];
    [cardList addObject:tmpCard];
  }
  [rs close];
  return cardList;
}

+ (NSString*) _FTSSQLForKeyword:(NSString*)keyword usePriorityTag:(BOOL)usePTag queryLimit:(NSInteger)limit
{
  NSString *returnSql = nil;
  NSString *keywordWildcard = [keyword stringByReplacingOccurrencesOfString:@"?" withString:@"*"];
#if defined(LWE_JFLASH)
  // Do the search using SQLite FTS (PTAG results)
  returnSql = [NSString stringWithFormat:@""
         "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id, 0 as wrong_count, 0 as right_count FROM cards c, cards_html ch "
         "WHERE c.card_id = ch.card_id AND c.card_id in (SELECT card_id FROM cards_search_content WHERE content MATCH '%@' AND ptag = %d LIMIT %d) "
         "ORDER BY c.headword", keywordWildcard, usePTag, limit];
#elif defined(LWE_CFLASH)
  returnSql = [NSString stringWithFormat:@""
         "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id, 0 as wrong_count, 0 as right_count FROM cards c, cards_html ch "
         "WHERE c.card_id = ch.card_id AND c.card_id in (SELECT card_id FROM cards_search_content WHERE content MATCH '%@' LIMIT %d) "
         "ORDER BY c.headword_trad", keywordWildcard, limit];
#endif
  return returnSql;
}

/**
 * Returns single card from SQL result - assumes 1 record, if multiple, will take last record
 */ 
+ (Card*) _retrieveCardWithSQL:(NSString*)sql
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  FMResultSet *rs = [db executeQuery:sql];
  Card *tmpCard = nil;
  while ([rs next])
  {
    tmpCard = [CardPeer blankCard];
    [tmpCard hydrate:rs];
  }
  [rs close];
  return tmpCard;
}

/**
 * Returns an array of Card objects based on SQL result
 */
+ (NSArray*) _retrieveCardSetWithSQL:(NSString*)sql hydrate:(BOOL)hydrate
{
	LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db executeQuery:sql];
	NSMutableArray *cardList = [NSMutableArray array];
	Card *tmpCard = nil;
	while ([rs next])
	{
		// Full card?
    tmpCard = [CardPeer blankCard];
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
	return (NSArray*)cardList;
}

#pragma mark - Convenience Helpers

/**
 * Takes a cardId and returns a hydrated Card from the database
 */
+ (Card*) retrieveCardByPK:(NSInteger)cardId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *sql = [[NSString alloc] initWithFormat:@""
                   "SELECT c.card_id AS card_id,u.card_level as card_level,u.user_id as user_id,"
                   "u.wrong_count as wrong_count,u.right_count as right_count,c.*,ch.meaning "
                   "FROM cards c INNER JOIN cards_html ch ON c.card_id = ch.card_id LEFT OUTER JOIN user_history u ON c.card_id = u.card_id AND u.user_id = '%d' "
                   "WHERE c.card_id = ch.card_id AND c.card_id = '%d'",[settings integerForKey:@"user_id"], cardId];
  Card *tmpCard = [CardPeer _retrieveCardWithSQL:sql];
  [sql release];
  return tmpCard;
}


/**
 * Returns an array of Card ids for a given tagId
 */
+ (NSArray*) retrieveCardIdsSortedByLevel:(NSInteger)tagId
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSMutableArray *cardIdList = [NSMutableArray arrayWithCapacity:6];
  for (NSInteger i = 0; i < 6; i++)
  {
    [cardIdList addObject:[NSMutableArray array]];
  }
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT l.card_id AS card_id,u.card_level as card_level "
"FROM card_tag_link l LEFT OUTER JOIN user_history u ON u.card_id = l.card_id AND u.user_id = '%d' WHERE l.tag_id = '%d'",[settings integerForKey:@"user_id"],tagId];
  FMResultSet *rs = [db executeQuery:sql];
  while ([rs next])
  {
    NSInteger levelId = [rs intForColumn:@"card_level"];
    NSInteger cardId = [rs intForColumn:@"card_id"];
    [[cardIdList objectAtIndex:levelId] addObject:[NSNumber numberWithInt:cardId]];
  }
  [rs close];
  [sql release];
  return cardIdList;
}

/**
 * Returns an array containing cardId integers contained in by the Tag tagId
 */
+ (NSArray*) retrieveCardIdsForTagId:(NSInteger)tagId
{
  return [CardPeer _retrieveCardSetWithSQL:[NSString stringWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = '%d'",tagId]
                                   hydrate:NO];
}

/**
 * Returns an array containng cardId integers that are linked to the sentence
 * \param sentenceId Primary key of the sentence to look up cards for
 */
+ (NSArray*) retrieveCardSetForExampleSentenceId:(NSInteger)sentenceId
{	
	NSString *sql = nil;
  if ([ExampleSentencePeer isNewVersion])
  {
    sql = [NSString stringWithFormat:@"SELECT c.* FROM card_sentence_link l, cards c WHERE l.card_id = c.card_id AND sentence_id = '%d' AND l.should_show = '1'", sentenceId];
  }
  else
  {
    sql = [NSString stringWithFormat:@"SELECT c.* FROM card_sentence_link l, cards c WHERE l.card_id = c.card_id AND sentence_id = '%d'", sentenceId];
  }
	LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
	FMResultSet *rs = [db executeQuery:sql];
	
	NSMutableArray *cardList = [NSMutableArray array];
	while ([rs next])
	{
		Card *tmpCard = [CardPeer blankCard];
		[tmpCard hydrate:rs simple:YES];
		[cardList addObject:tmpCard];
	}
	[rs close];

	return (NSArray*)cardList; 
}

@end