//
//  SwipeView.h
//  jFlash
//
//  Created by Ross Sharrott on 12/20/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SwipeView : UIView
{
	CGPoint startTouchPosition;
	NSString *dirString;
	UIViewController *host;
}

- (void) setHost: (UIViewController *) aHost;

@end