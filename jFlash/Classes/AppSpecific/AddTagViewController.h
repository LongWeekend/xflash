//
//  AddTagViewController.h
//  jFlash
//
//  Created by Mark Makdad on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"
#import "LWEAudioQueue.h"

@interface AddTagViewController : UITableViewController <LWEAudioQueueDelegate>

- (id) initWithCard:(Card*) card;
- (IBAction) addStudySet;

@property (retain) NSArray *myTagArray;
@property (retain) NSArray *sysTagArray;
@property (retain) Card *currentCard;

@end
