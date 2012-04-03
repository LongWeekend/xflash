//
//  DisplaySearchedSentenceViewController.h
//  jFlash
//
//  Created by Mark Makdad on 6/13/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExampleSentence.h"
#import "Card.h"
#import "CardPeer.h"
#import "AddTagViewController.h"

#define SENTENCE_ROW 0
#define SECTION_CARDS 1

@interface DisplaySearchedSentenceViewController : UITableViewController {}

- (id) initWithSentences:(NSArray*) sentences;

@property (nonatomic, retain) NSArray *sentenceArray;
@property (nonatomic, retain) NSMutableArray *cards;

@end
