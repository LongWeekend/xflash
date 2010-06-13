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

#define SECTION_SENTENCE 0
#define SECTION_CARDS 1

@interface DisplaySearchedSentenceViewController : UITableViewController
{
  ExampleSentence *sentence;      //! holds reference to the ExampleSentence shown here
  NSArray *cards;                 //! holds an array of all cards linked on this example sentence
}

- (id) initWithSentence:(ExampleSentence*) initSentence;

@property (nonatomic, retain) ExampleSentence *sentence;
@property (nonatomic, retain) NSArray *cards;

@end
