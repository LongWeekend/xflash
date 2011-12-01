//
//  MoodIcon.m
//  jFlash
//
//  Created by シャロット ロス on 2/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "MoodIcon.h"

//! Handles "hot head" mood icons
@implementation MoodIcon

@synthesize percentCorrectLabel,moodIconBtn;

- (void) updateMoodIcon:(CGFloat)percentCorrect
{
  self.percentCorrectLabel.text = [NSString stringWithFormat:@"%.0f%%",percentCorrect];

  // TODO: iPad customization!
  NSArray *hotHeadsArray = [[NSArray alloc] initWithObjects: @"mood-icons/positive/hh-ecstatic.png", @"mood-icons/positive/hh-happy.png", @"mood-icons/positive/hh-jolly.png", @"mood-icons/neutral/hh-small-smile.png", @"mood-icons/neutral/hh-my-name-is-forest.png",
                            @"mood-icons/neutral/hh-uncommunicative.png", @"mood-icons/negative/hh-wounded.png", @"mood-icons/negative/hh-losin-it.png", @"mood-icons/negative/hh-pissed.png", @"mood-icons/negative/hh-sea-sick.png", @"mood-icons/negative/hh-wounded.png", nil];
  //  NSArray* transitionHHArray = [[NSArray alloc] initWithObjects: @"positive/hh-on-a-roll.png", @"positive/hh-smug.png", @"negative/hh-aggro.png", @"negative/hh-frustrated.png", nil]; 
  
  NSInteger loopCount = 0;
  //  bool shouldAnimate = NO;
  //NSArray* transitionHHAnimationArray;
  
  CGFloat a = 100.0f; 
  NSString *hotheadName = nil;

  // default when no animtions
  ThemeManager *tm = [ThemeManager sharedThemeManager];
  hotheadName = [tm elementWithCurrentTheme:[hotHeadsArray objectAtIndex:0]];
  
  while (a >= 0)
  {
    if (percentCorrect <= a && percentCorrect > a - 10)
    {
      hotheadName = [tm elementWithCurrentTheme:[hotHeadsArray objectAtIndex:loopCount]];
      break;
    }
    a -= 10;
    loopCount++;
  }
  
  [self.moodIconBtn setBackgroundImage:[UIImage imageNamed:hotheadName] forState:UIControlStateNormal];
  [hotHeadsArray release];
}

@end
