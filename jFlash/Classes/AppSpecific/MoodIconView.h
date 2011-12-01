//
//  MoodIcon.h
//  jFlash
//
//  Created by シャロット ロス on 2/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MoodIconView : UIView

//! Update the mood icon depending on the current percentage correct
- (void) updateMoodIcon:(CGFloat)percentCorrect;

@property (retain,nonatomic) IBOutlet UIButton *moodIconBtn;
@property (retain,nonatomic) IBOutlet UILabel *percentCorrectLabel;

@end
