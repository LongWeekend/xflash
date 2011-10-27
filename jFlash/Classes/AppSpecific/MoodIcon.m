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

- (void) updateMoodIcon: (float)tmpRatio
{
  // TODO: iPad customization!
  NSArray* hotHeadsArray = [[NSArray alloc] initWithObjects: @"mood-icons/positive/hh-ecstatic.png", @"mood-icons/positive/hh-happy.png", @"mood-icons/positive/hh-jolly.png", @"mood-icons/neutral/hh-small-smile.png", @"mood-icons/neutral/hh-my-name-is-forest.png",
                            @"mood-icons/neutral/hh-uncommunicative.png", @"mood-icons/negative/hh-wounded.png", @"mood-icons/negative/hh-losin-it.png", @"mood-icons/negative/hh-pissed.png", @"mood-icons/negative/hh-sea-sick.png", @"mood-icons/negative/hh-wounded.png", nil];
  //  NSArray* transitionHHArray = [[NSArray alloc] initWithObjects: @"positive/hh-on-a-roll.png", @"positive/hh-smug.png", @"negative/hh-aggro.png", @"negative/hh-frustrated.png", nil]; 
  NSString* tmpStr;
  
  float a = 100.0f; 
  int loopCount = 0;
  //  bool shouldAnimate = NO;
  //NSArray* transitionHHAnimationArray;
  ThemeManager *tm = [ThemeManager sharedThemeManager];
  
  self.percentCorrectLabel.text = [NSString stringWithFormat:@"%.0f%%",tmpRatio];
  
  // default when no animtions
  tmpStr = [tm elementWithCurrentTheme:[hotHeadsArray objectAtIndex:0]];
  
  while(a >= 0)
  {
    if (tmpRatio <= a && tmpRatio > a - 10)
    {
      tmpStr = [tm elementWithCurrentTheme:[hotHeadsArray objectAtIndex:loopCount]];
      break;
    }
    a -= 10;
    loopCount++;
  }
  
  [moodIconBtn setBackgroundImage:[UIImage imageNamed:tmpStr] forState:UIControlStateNormal];
  [hotHeadsArray release];
}

//! Returns an image view with a happy HH based on the current theme
+ (UIImageView*) makeHappyMoodIconView
{
  ThemeManager *tm = [ThemeManager sharedThemeManager];
  // TODO: iPad customization!
  NSString* tmpStr = [tm elementWithCurrentTheme:@"positive/hh-happy.png"];
  UIImageView* tmpImgView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:tmpStr]] autorelease];
  return tmpImgView;
}

@end
