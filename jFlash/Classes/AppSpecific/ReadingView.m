//
//  ReadingView.m
//  jFlash
//
//  Created by Mark Makdad on 8/21/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "ReadingView.h"


//  MultipartLabel.m
//  MultiLabelLabel
//
//  Created by Jason Miller on 10/7/09.
//  Copyright 2009 Jason Miller. All rights reserved.
//

@interface ReadingView (Private)
- (void)updateLayout;
@end

@implementation ReadingView

@synthesize containerView;
@synthesize labels;

-(void)updateNumberOfLabels:(int)numLabels;
{
  [containerView removeFromSuperview];
  self.containerView = nil;
  
  self.containerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)] autorelease];
  [self addSubview:self.containerView];
  self.labels = [NSMutableArray array];
  
  while (numLabels-- > 0) {
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.containerView addSubview:label];
    [self.labels addObject:label];
    [label release];
  }
  
  [self updateLayout];
}

-(void)setText:(NSString *)text forLabel:(int)labelNum;
{
  if( [self.labels count] > labelNum && labelNum >= 0 )
  {
    UILabel * thisLabel = [self.labels objectAtIndex:labelNum];
    thisLabel.text = text;
  }
  
  [self updateLayout];
}

-(void)setText:(NSString *)text andFont:(UIFont*)font forLabel:(int)labelNum;
{
  if( [self.labels count] > labelNum && labelNum >= 0 )
  {
    UILabel * thisLabel = [self.labels objectAtIndex:labelNum];
    thisLabel.text = text;
    thisLabel.font = font;
  }
  
  [self updateLayout];
}

-(void)setText:(NSString *)text andColor:(UIColor*)color forLabel:(int)labelNum;
{
  if( [self.labels count] > labelNum && labelNum >= 0 )
  {
    UILabel * thisLabel = [self.labels objectAtIndex:labelNum];
    thisLabel.text = text;
    thisLabel.textColor = color;
  }
  
  [self updateLayout];
}

-(void)setText:(NSString *)text andFont:(UIFont*)font andColor:(UIColor*)color forLabel:(int)labelNum;
{
  if( [self.labels count] > labelNum && labelNum >= 0 )
  {
    UILabel * thisLabel = [self.labels objectAtIndex:labelNum];
    thisLabel.text = text;
    thisLabel.font = font;
    thisLabel.textColor = color;
  }
  
  [self updateLayout];
}

- (void)updateLayout {
  
  int thisX = 0;
  
  // TODO when it is time to support different sized fonts, need to adjust each y value to line up baselines
  
  for (UILabel * thisLabel in self.labels) {
    CGSize size = [thisLabel.text sizeWithFont:thisLabel.font
                             constrainedToSize:CGSizeMake(9999, 9999)
                                 lineBreakMode:thisLabel.lineBreakMode];
    CGRect thisFrame = CGRectMake( thisX, 0, size.width, size.height );
    thisLabel.frame = thisFrame;
    
    thisX += size.width;
  }
}


- (void)dealloc {
  [labels release];
  labels = nil;
  
  [containerView release];
  containerView = nil;
  
  [super dealloc];
}


@end
