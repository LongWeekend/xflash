//
//  LWEViewAnimationUtils.m
//  jFlash
//
//  Created by Mark Makdad on 6/2/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "LWEViewAnimationUtils.h"

//! Helper class to take some of the heavy lifting out of animating views
@implementation LWEViewAnimationUtils


//! Translation animate a view from current location to new location by adding the values contained in point
+ (void) translateView:(UIView*)view byPoint:(CGPoint)point withInterval:(float)delay
{
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:delay];
  CGAffineTransform transform = CGAffineTransformMakeTranslation(point.x, point.y);
  view.transform = transform;
  [UIView commitAnimations];
}

@end
