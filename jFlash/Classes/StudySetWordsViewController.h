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
//TODO: later do this
//#import "Util.h"
//#import "ASIFormDataRequest.h"


enum settingsRows
{
  kWordSetOptionsStart = 0,
  kWordSetOptionsPublish = 1,
  settingsRowsLenght
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
//@property (nonatomic, retain) UIAlertView *statusMsgBox;
@property (retain) NSMutableArray *cards;
//@property (retain) NSOperationQueue *queue;

@end