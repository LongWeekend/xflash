//
//  TouchableTextView.m
//  jFlash
//
//  Created by paul on 5/6/09.
//  Copyright LONG WEEKEND INC. 2009 All rights reserved.
//

#import "TouchableTextView.h"

@implementation TouchableTextView

// Override any of the touch events here
- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event {	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"imTouched" object:self];
	[super touchesEnded: touches withEvent: event];
}


- (void) dealloc{
//	[NSNotificationCenter defaultCenter];
    [super dealloc];
}
@end
