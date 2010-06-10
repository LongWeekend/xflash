//
//  ExampleSentencePeer.m
//  jFlash
//
//  Created by シャロット ロス on 6/6/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ExampleSentencePeer.h"

/*!
    @class ExampleSentencePeer
    @abstract    Handles getting ExampleSentence objects from LWEDatabase
 */
@implementation ExampleSentencePeer


/** Returns a mutable array of ExampleSentence objects based on the SQL passed via the \param sql */
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


/** returns a single hydrated ExampleSentence object using \param sentenceId */
+ (ExampleSentence*) retrieveExampleSentenceByPK: (NSInteger)sentenceId;
{
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM example_sentences WHERE sentence_id = '%d'", sentenceId];
  NSMutableArray* tmpSentences = [ExampleSentencePeer retrieveSentencesWithSQL:sql hydrate:YES];
	[sql release];
	return [tmpSentences objectAtIndex:0];
}


/** Returns all ExampleSentence objects that are linked to \param cardId */
+ (NSMutableArray*) getExampleSentencesByCardId: (NSInteger)cardId
{
  NSString *sql = [[NSString alloc] initWithFormat:@"SELECT s.* FROM example_sentences s, example_card_link l WHERE l.card_id = '%d' AND s.sentence_id = l.example_sentence_id", cardId];
  NSMutableArray* tmpSentences = [ExampleSentencePeer retrieveSentencesWithSQL:sql hydrate:YES];
	[sql release];
	return tmpSentences;
}

@end
