//
//  ExampleSentences.h
//  jFlash
//
//  Created by シャロット ロス on 6/6/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExampleSentence : NSObject {
  NSInteger sentenceId;
  NSString *sentenceJa;
  NSString *sentenceEn;
  NSInteger checked;
}

- (void) hydrate: (FMResultSet*) rs;

@property (nonatomic) NSInteger sentenceId;
@property (nonatomic, retain) NSString* sentenceJa;
@property (nonatomic, retain) NSString* sentenceEn;
@property (nonatomic) NSInteger checked;
@end