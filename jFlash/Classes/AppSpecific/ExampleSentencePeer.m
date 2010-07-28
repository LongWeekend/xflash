//
//  ExampleSentencePeer.m
//  jFlash
//
//  Created by シャロット ロス on 6/6/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ExampleSentencePeer.h"
#import "CardPeer.h"

/*!
    @class ExampleSentencePeer
    @abstract    Handles getting ExampleSentence objects from LWEDatabase
 */
@implementation ExampleSentencePeer


/**
 * Returns a mutable array of ExampleSentence objects based on custom SQL
 * \param sql SQL string used to return the ExampleSentence objects
 * \param hydrate If YES, the -hydrate:rs method will be called on each ExampleSentence
 */
+ (NSMutableArray*) retrieveSentencesWithSQL:(NSString*)sql hydrate:(BOOL)hydrate
{
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  FMResultSet *rs = [[db dao] executeQuery:sql];
  ExampleSentence* tmpSentence;
  NSMutableArray *sentenceList = [[[NSMutableArray alloc] init] autorelease];
  while ([rs next])
  {
    tmpSentence = [[ExampleSentence alloc] init];
    if (hydrate)
    {
      [tmpSentence hydrate:rs];
    }
    else
    {
      [tmpSentence setSentenceId:[rs intForColumn:@"sentence_id"]];
    }
    [sentenceList addObject: tmpSentence];
    [tmpSentence release];
  }
  [rs close];
  return sentenceList;
}


/**
 * Returns a single hydrated ExampleSentence object
 * \param sentenceId primary key of the Sentence to be retrieved from the DB
 */
+ (ExampleSentence*) retrieveExampleSentenceByPK: (NSInteger)sentenceId;
{
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM sentences WHERE sentence_id = '%d'", sentenceId];
  NSMutableArray* tmpSentences = [ExampleSentencePeer retrieveSentencesWithSQL:sql hydrate:YES];
	[sql release];
	return [tmpSentences objectAtIndex:0];
}


/**
 * Returns all linked ExampleSentence objects for a given card
 * \param cardId Primary key of the Card object for which to retrieve ExampleSentences
 */
+ (NSMutableArray*) getExampleSentencesByCardId: (NSInteger)cardId
{
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT s.* FROM sentences s, card_sentence_link l WHERE l.card_id = %d AND s.sentence_id = l.sentence_id limit 10", cardId];
  NSMutableArray* tmpSentences = [ExampleSentencePeer retrieveSentencesWithSQL:sql hydrate:YES];
  [sql release];
  return tmpSentences;
}

/**
 * Returns a boolean YES if example sentences exist for a given card id. NO if none exist/
 */
+ (BOOL) sentencesExistForCardId: (NSInteger)cardId
{
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT sentence_id FROM card_sentence_link WHERE card_id = %d LIMIT 1", cardId];
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  FMResultSet *rs = [[db dao] executeQuery:sql];
  [sql release];
  if ([rs next])
  {
    return YES;
  }
  [rs close];
  return NO;
}


/**
 * Returns an array of Sentence objects after searching keyword - for search
 */
+ (NSMutableArray*) searchSentencesForKeyword: (NSString*)keyword doSlowSearch:(BOOL)slowSearch
{
  NSMutableArray *cardList = [CardPeer searchCardsForKeyword:keyword doSlowSearch:slowSearch];
  
  // Do a clever IN SQL statement!  Aha!
  NSString *inStatement = nil;
  Card* card = nil;
  for (int i = 0; i < [cardList count]; i++)
  {
    card = [cardList objectAtIndex:i];
    if (i == 0)
    {
      inStatement = [NSString stringWithFormat:@"%d",[card cardId]];
    }
    else if (i > 0)
    {
      inStatement = [NSString stringWithFormat:@"%@,%d",inStatement,[card cardId]];      
    }
  }
  
  LWE_LOG(@"In Statement: %@",inStatement);
  
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT DISTINCT(s.sentence_id), s.sentence_ja, s.sentence_en, s.checked FROM sentences s, card_sentence_link c WHERE s.sentence_id = c.sentence_id AND c.card_id IN (%@)",inStatement];
  NSMutableArray* exampleSentences = [ExampleSentencePeer retrieveSentencesWithSQL:sql hydrate:YES];
  [sql release];
  return exampleSentences;
/*  
  
  LWEDatabase *db = [LWEDatabase sharedLWEDatabase];
  NSMutableArray *cardList = [[[NSMutableArray alloc] init] autorelease];
  NSString* sql;
  FMResultSet *rs;
  NSString* keywordWildcard;
  
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
    rs = [[db dao] executeQuery:sql];
    int cardListCount = 0;
    while ([rs next])
    {
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
           "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id, 0 as wrong_count, 0 as right_count FROM cards c, cards_html ch "
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
           "SELECT c.*, ch.meaning, 0 as card_level, 0 as user_id, 0 as wrong_count, 0 as right_count FROM cards c, cards_html ch "
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
  
	return cardList;*/
}

@end
