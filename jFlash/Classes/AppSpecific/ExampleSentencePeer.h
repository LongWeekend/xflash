//
//  ExampleSentencePeer.h
//  jFlash
//
//  Created by シャロット ロス on 6/6/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExampleSentence.h"


@interface ExampleSentencePeer : NSObject

+ (BOOL) isNewVersion;

+ (ExampleSentence*) retrieveExampleSentenceByPK: (NSInteger)sentenceId;
+ (NSMutableArray*) retrieveSentencesWithSQL:(NSString*)sql hydrate:(BOOL)hydrate;
+ (NSMutableArray*) getExampleSentencesByCardId: (NSInteger)cardId;
+ (BOOL) sentencesExistForCardId: (NSInteger)cardId;
+ (NSMutableArray*) searchSentencesForKeyword: (NSString*)keyword;

@end
