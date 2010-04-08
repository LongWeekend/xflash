//
//  MoodIcon.m
//  jFlash
//
//  Created by シャロット ロス on 2/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "MoodIcon.h"


@implementation MoodIcon

@synthesize percentCorrectLabel,moodIconBtn;

- (void) updateMoodIcon: (float)tmpRatio
{
  NSArray* hotHeadsArray = [[NSArray alloc] initWithObjects: @"positive/hh-ecstatic.png", @"positive/hh-happy.png", @"positive/hh-jolly.png", @"neutral/hh-small-smile.png", @"neutral/hh-my-name-is-forest.png",
                            @"neutral/hh-uncommunicative.png", @"negative/hh-wounded.png", @"negative/hh-losin-it.png", @"negative/hh-pissed.png", @"negative/hh-sea-sick.png", @"negative/hh-wounded.png", nil];
  //  NSArray* transitionHHArray = [[NSArray alloc] initWithObjects: @"positive/hh-on-a-roll.png", @"positive/hh-smug.png", @"negative/hh-aggro.png", @"negative/hh-frustrated.png", nil]; 
  NSString* tmpStr;
  
  float a = 100.0f; 
  int loopCount = 0;
  //  bool shouldAnimate = NO;
  //NSArray* transitionHHAnimationArray;
  NSString* themeName = [ApplicationSettings getThemeName];
  
  // TODO : setting the labels doesn't fit in the text sbubble.
  [percentCorrectLabel setText:[NSString stringWithFormat:@"%.0f%%",tmpRatio]];
  /* Save the animations for version 1.1
   if(currentRightStreak == 3)
   {
   shouldAnimate = YES;
   tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/mood-icons/%@",themeName, [transitionHHArray objectAtIndex:0]];
   transitionHHAnimationArray = [[NSArray alloc] initWithObjects: [UIImage imageNamed:[NSString stringWithFormat:@"/%@theme-cookie-cutters/mood-icons/%@",(NSString*)themeName, @"positive/hh-on-a-roll.png"]],
   [UIImage imageNamed:[NSString stringWithFormat:@"/%@theme-cookie-cutters/mood-icons/%@",(NSString*)themeName, @"positive/hh-smug.png"]], nil]; 
   //    [percentCorrectLabel setText:[NSString stringWithString:@"3 in a row!"]];
   }
   else if (currentRightStreak == 5)
   {
   tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/mood-icons/%@",themeName, [transitionHHArray objectAtIndex:1]];    
   //    [percentCorrectLabel setText:[NSString stringWithString:@"5 in a row!"]];
   }
   else if (currentWrongStreak == 4)
   {
   tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/mood-icons/%@",themeName, [transitionHHArray objectAtIndex:2]];    
   //    [percentCorrectLabel setText:[NSString stringWithString:@"3 wrong!"]];
   }
   else if (currentWrongStreak == 5)
   {
   tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/mood-icons/%@",themeName, [transitionHHArray objectAtIndex:3]];    
   //    [percentCorrectLabel setText:[NSString stringWithString:@"5 wrong!"]];
   }
   else
   { */
  
  // default when no animtions
  tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/mood-icons/%@",themeName, [hotHeadsArray objectAtIndex:0]];
  // default when no animtions
  
  if(a == 0){
    tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/mood-icons/%@",themeName, [hotHeadsArray objectAtIndex:0]];
  }
  while(a >= 0)
  {
    if(tmpRatio <= a && tmpRatio > a - 10) {
      tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/mood-icons/%@",themeName, [hotHeadsArray objectAtIndex:loopCount]];
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
  [tmpStr release];
  [hotHeadsArray release];
}

- (void) reenableHH
{
  [moodIconBtn setHidden:NO];
}


@end
