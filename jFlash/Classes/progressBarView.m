//
//  progressBarView.m
//  jFlash
//
//  Created by シャロット ロス on 8/15/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "progressBarView.h"

@implementation progressBarView
@synthesize levelDetails; 

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();
    NSArray* colors = [NSArray arrayWithObjects:[UIColor grayColor],[UIColor greenColor],[UIColor yellowColor],[UIColor orangeColor],[UIColor redColor],[UIColor magentaColor],nil];
    
    CGFloat dash[] = {8.5, 1.5};
    CGContextSetLineDash(c, 0, dash, 4);
    CGContextSetLineWidth(c, 13.0);
    CGContextBeginPath(c);
    
    float totalCards = [[levelDetails objectAtIndex:6] floatValue];
    int i;
    float totalLine = 0;
    for (i = 0; i < 6; i++) {
        CGContextSetStrokeColorWithColor(c, [[colors objectAtIndex:i] CGColor]);
        CGContextMoveToPoint(c, totalLine, 30.0f);
        float count = [[levelDetails objectAtIndex:i] floatValue];
        float lineLength = (count/totalCards)*160.0f;
        totalLine = totalLine + lineLength;
        CGContextAddLineToPoint(c, totalLine, 30.0f);
        CGContextStrokePath(c);
    }	
}

- (void)dealloc {
  [levelDetails release];
  [super dealloc];
}


@end
