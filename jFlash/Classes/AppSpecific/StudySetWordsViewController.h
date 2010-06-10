//
//  StudySetWordViewController.h
//  jFlash
//
//  Created by Ross Sharrott on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TagPeer.h"
#import "Tag.h"
#import "CardPeer.h"

// TODO: pretty well sure these two enums are no longer used in active code
enum settingsRows
{
  kWordSetOptionsStart = 0,
  kWordSetOptionsPublish = 1,
  settingsRowsLength
};


enum wordsSections
{
  kWordSetOptionsSection = 0,
  kWordSetListSections = 1,
  wordsSectionsLength
};

@interface StudySetWordsViewController : UITableViewController 
{
	Tag* tag;
	NSMutableArray* cards;
  //TODO: next version
  // UIAlertView* statusMsgBox;
  //  NSOperationQueue* queue;
  UIActivityIndicatorView *activityIndicator;
}


- (id) initWithTag:(Tag*) initTag;

//TODO: next version
//- (void) uploadThisSet;
//- (void) postDataToURL:(NSString*)csvData;

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) Tag *tag;
@property (retain) NSMutableArray *cards;

@end