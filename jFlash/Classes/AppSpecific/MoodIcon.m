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
  
  // TODO : setting the labels doesn't fit in the text sbubble.
  [percentCorrectLabel setText:[NSString stringWithFormat:@"%.0f%%",tmpRatio]];
  /* Save the animations for version 1.1
   if(currentRightStreak == 3)
   {
   shouldAnimate = YES;
   //TODO: get rid of these path names all over this code - use [ThemeManager 
   tmpStr = [tm elementWithCurrentTheme:[transitionHHArray objectAtIndex:0]];
   transitionHHAnimationArray = [[NSArray alloc] initWithObjects:
      [UIImage imageNamed:[tm elementWithCurrentTheme:@"positive/hh-on-a-roll.png"]],
      [UIImage imageNamed:[tm elementWithCurrentTheme:@"positive/hh-smug.png"]], nil]; 
   //    [percentCorrectLabel setText:[NSString stringWithString:@"3 in a row!"]];
   }
   else if (currentRightStreak == 5)
   {
   tmpStr = [tm elementWithCurrentTheme:[transitionHHArray objectAtIndex:1]];
   //    [percentCorrectLabel setText:[NSString stringWithString:@"5 in a row!"]];
   }
   else if (currentWrongStreak == 4)
   {
   tmpStr = [tm elementWithCurrentTheme:[transitionHHArray objectAtIndex:2]];
   //    [percentCorrectLabel setText:[NSString stringWithString:@"3 wrong!"]];
   }
   else if (currentWrongStreak == 5)
   {
   tmpStr = [tm elementWithCurrentTheme:[transitionHHArray objectAtIndex:3]];
   //    [percentCorrectLabel setText:[NSString stringWithString:@"5 wrong!"]];
   }
   else
   { */
  
  // default when no animtions
  tmpStr = [tm elementWithCurrentTheme:[hotHeadsArray objectAtIndex:0]];
  // default when no animtions
  
  if(a == 0){
    tmpStr = [tm elementWithCurrentTheme:[hotHeadsArray objectAtIndex:0]];
  }
  while(a >= 0)
  {
    if(tmpRatio <= a && tmpRatio > a - 10) {
      tmpStr = [tm elementWithCurrentTheme:[hotHeadsArray objectAtIndex:loopCount]];
      break;
    }
    a -= 10;
    loopCount++;
  }
  /*}
   // do the animation if we are in a streak
   if(shouldAnimate)
   {
   hhAnimationView.animationImages = transitionHHAnimationArray;
   hhAnimationView.animationRepeatCount = 15;
   
   // shut off the mood icon because we animate in the same spot
   [moodIconBtn setHidden:YES];
   [hhAnimationView startAnimating];
   [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(reenableHH) userInfo:nil repeats:NO];
   [transitionHHAnimationArray release];
   } */
  
  [moodIconBtn setBackgroundImage:[UIImage imageNamed:tmpStr] forState:UIControlStateNormal];
  [hotHeadsArray release];
}

- (void) reenableHH
{
  [moodIconBtn setHidden:NO];
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
