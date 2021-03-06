//
//  ProgressDetailsViewController.h
//  jFlash
//
//  Created by Ross Sharrott on 11/23/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tag.h"
#import "CloseButtonView.h"

@interface ProgressDetailsViewController : UIViewController <CloseButtonViewDelegate>

- (IBAction) dismiss;
- (IBAction)switchToSettings:(id)sender;
- (void) drawProgressBars;
- (void) setStreakLabel;

/**
 Call this to tell the progress detail VC to update all its data.
 */
- (void)updateView;

@property (nonatomic, retain) Tag *tag;

@property (nonatomic, retain) IBOutlet UIView *bgView;
@property (nonatomic,retain) IBOutlet UILabel *currentNumberOfWords;
@property (nonatomic,retain) IBOutlet UILabel *totalNumberOfWords;
@property (nonatomic,retain) IBOutlet UIButton *closeBtn;
@property (nonatomic,retain) IBOutlet UILabel *currentStudySet; 
@property (nonatomic,retain) IBOutlet UILabel *motivationLabel;
@property (nonatomic,retain) IBOutlet UILabel *streakLabel;
@property (nonatomic,retain) IBOutlet UILabel *cardsViewedNow;
@property (nonatomic,retain) IBOutlet UILabel *cardsViewedAllTime;
@property (nonatomic,retain) IBOutlet UILabel *cardsRightNow;
@property (nonatomic,retain) IBOutlet UILabel *cardsWrongNow;
@property NSInteger wrongStreak;
@property NSInteger rightStreak;

@property (nonatomic, retain) IBOutlet UILabel *cardSetProgressLabel0;
@property (nonatomic, retain) IBOutlet UILabel *cardSetProgressLabel1;
@property (nonatomic, retain) IBOutlet UILabel *cardSetProgressLabel2;
@property (nonatomic, retain) IBOutlet UILabel *cardSetProgressLabel3;
@property (nonatomic, retain) IBOutlet UILabel *cardSetProgressLabel4;
@property (nonatomic, retain) IBOutlet UILabel *cardSetProgressLabel5;
@property (nonatomic, retain) IBOutlet UILabel *progressViewTitle;

@property (retain, nonatomic) IBOutlet UIProgressView *progressViewLevel0;
@property (retain, nonatomic) IBOutlet UIProgressView *progressViewLevel1;
@property (retain, nonatomic) IBOutlet UIProgressView *progressViewLevel2;
@property (retain, nonatomic) IBOutlet UIProgressView *progressViewLevel3;
@property (retain, nonatomic) IBOutlet UIProgressView *progressViewLevel4;
@property (retain, nonatomic) IBOutlet UIProgressView *progressViewLevel5;


@end
