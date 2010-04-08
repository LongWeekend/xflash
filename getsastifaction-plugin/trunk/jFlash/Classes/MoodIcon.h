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

- (void)updateMoodIcon: (float)tmpRatio;
- (void)reenableHH;

@property (retain,nonatomic) UIButton *moodIconBtn;
@property (retain,nonatomic) UILabel *percentCorrectLabel;

@end
