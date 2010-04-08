//
//  SwipeView.m
//  jFlash
//
//  Created by Ross Sharrott on 12/20/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "SwipeView.h"


@implementation SwipeView

- (void) setHost: (UIViewController *) aHost
{
	host = aHost;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{ 
	UITouch *touch = [touches anyObject]; 
	startTouchPosition = [touch locationInView:self]; 
	dirString = NULL;
} 

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{ 
	UITouch *touch = touches.anyObject; 
	CGPoint currentTouchPosition = [touch locationInView:self]; 
	
	if (fabsf(startTouchPosition.x - currentTouchPosition.x) >= HORIZ_SWIPE_DRAG_MIN && 
      fabsf(startTouchPosition.y - currentTouchPosition.y) <= VERT_SWIPE_DRAG_MAX) 
   { 
     // Horizontal Swipe
     if (startTouchPosition.x < currentTouchPosition.x) {
       dirString = kCATransitionFromLeft;
     }
     else 
       dirString = kCATransitionFromRight;
   }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	if (dirString) [host swipeTo:dirString];
}

@end