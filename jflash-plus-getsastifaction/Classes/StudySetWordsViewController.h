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
#import "Util.h"
#import "CardPeer.h"
#import "ASIFormDataRequest.h"

enum settingsRows {
  kWordSetOptionsStart = 0,
  kWordSetOptionsPublish = 1,
  settingsRowsLenght
};

enum settingsSections {
  kWordSetOptionsSection = 0,
  kWordSetListSections = 1,
  settingsSectionsLength
};

@interface StudySetWordsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  UIAlertView* statusMsgBox;
	Tag* tag;
  IBOutlet UITableView *studySetWordsTable;
	NSMutableArray* cards;
  NSOperationQueue* queue;
}

- (void) uploadThisSet;
- (void) postDataToURL:(NSString*)csvData;

@property (nonatomic, retain) Tag *tag;
@property (nonatomic, retain) UIAlertView *statusMsgBox;
@property (retain) NSMutableArray *cards;
@property (nonatomic, retain) IBOutlet UITableView *studySetWordsTable;
@property (retain) NSOperationQueue *queue;

@end