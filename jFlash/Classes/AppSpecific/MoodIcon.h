//
//  MoodIcon.h
//  jFlash
//
//  Created by シャロット ロス on 2/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MoodIcon : NSObject {
  UIButton *moodIconBtn;
  UILabel *percentCorrectLabel;
}


//! Update the mood icon depending on the current percentage correct
- (void)updateMoodIcon: (float)tmpRatio;
+ (UIImageView*) makeHappyMoodIconView;

@property (retain,nonatomic) UIButton *moodIconBtn;
@property (retain,nonatomic) UILabel *percentCorrectLabel;

@end
