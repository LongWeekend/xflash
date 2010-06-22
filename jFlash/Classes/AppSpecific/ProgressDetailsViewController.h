//
//  ProgressDetailsViewController.h
//  jFlash
//
//  Created by Ross Sharrott on 11/23/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDColoredProgressView.h"

@interface ProgressDetailsViewController : UIViewController {
  IBOutlet UILabel *currentNumberOfWords;
  IBOutlet UILabel *totalNumberOfWords;
  
  IBOutlet UIButton *closeBtn;
  IBOutlet UILabel *currentStudySet;
  IBOutlet UILabel *motivationLabel;
  IBOutlet UILabel *streakLabel;
  
  IBOutlet UILabel *cardsViewedNow;
  IBOutlet UILabel *cardsViewedAllTime;
  IBOutlet UILabel *cardsRightNow;
  IBOutlet UILabel *cardsRightAllTime;
  IBOutlet UILabel *cardsWrongNow;
  IBOutlet UILabel *cardsWrongAllTime;
  
  IBOutlet UILabel *cardSetProgressLabel0;
  IBOutlet UILabel *cardSetProgressLabel1;
  IBOutlet UILabel *cardSetProgressLabel2;
  IBOutlet UILabel *cardSetProgressLabel3;
  IBOutlet UILabel *cardSetProgressLabel4;
  IBOutlet UILabel *cardSetProgressLabel5;  
  IBOutlet UILabel *progressViewTitle;  
  
  NSMutableArray* levelDetails;
  NSInteger wrongStreak;
  NSInteger rightStreak;
}

- (IBAction) dismiss;
- (void) drawProgressBars;
- (void) setStreakLabel;

@property (nonatomic, retain) NSMutableArray *levelDetails;
@property (nonatomic,retain) IBOutlet UILabel *currentNumberOfWords;
@property (nonatomic,retain) IBOutlet UILabel *totalNumberOfWords;
@property (nonatomic,retain) IBOutlet UIButton *closeBtn;
@property (nonatomic,retain) IBOutlet UILabel *currentStudySet; 
@property (nonatomic,retain) IBOutlet UILabel *motivationLabel;
@property (nonatomic,retain) IBOutlet UILabel *streakLabel;
@property (nonatomic,retain) IBOutlet UILabel *cardsViewedNow;
@property (nonatomic,retain) IBOutlet UILabel *cardsViewedAllTime;
@property (nonatomic,retain) IBOutlet UILabel *cardsRightNow;
@property (nonatomic,retain) IBOutlet UILabel *cardsRightAllTime;
@property (nonatomic,retain) IBOutlet UILabel *cardsWrongNow;
@property (nonatomic,retain) IBOutlet UILabel *cardsWrongAllTime;
@property NSInteger wrongStreak;
@property NSInteger rightStreak;

@property (nonatomic, retain) UILabel *cardSetProgressLabel0;
@property (nonatomic, retain) UILabel *cardSetProgressLabel1;
@property (nonatomic, retain) UILabel *cardSetProgressLabel2;
@property (nonatomic, retain) UILabel *cardSetProgressLabel3;
@property (nonatomic, retain) UILabel *cardSetProgressLabel4;
@property (nonatomic, retain) UILabel *cardSetProgressLabel5;
@property (nonatomic, retain) UILabel *progressViewTitle;

@end
