//
//  CustomCellBackgroundView.m
//
//  Created by Users on Stackoverflow!!
//
// NOTE: This does not draw the backgrounds exactly like the UIKit originals, so try to avoid mixing background
//       colors when reusing cells. Also you should avoid using it for white (default) background colors!
//

#import "CustomCellBackgroundView.h"

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth,float ovalHeight);

@implementation CustomCellBackgroundView
@synthesize borderColor, fillColor, position;

- (BOOL) isOpaque {
  return NO;
}

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    self.position = CustomCellBackgroundViewPositionBottom;
  }
  return self;
}

- (void)setCellIndexPath:(NSIndexPath*)indexPath tableLength:(NSInteger)tableLength
{
  if (tableLength == 1) {
    self.position = CustomCellBackgroundViewPositionSingle;
  }
  else if (indexPath.row == 0) 
  {
    self.position = CustomCellBackgroundViewPositionTop;
  }
  else if (indexPath.row == tableLength-1)
  {
    self.position = CustomCellBackgroundViewPositionBottom;
  }
  else 
  {
    self.position = CustomCellBackgroundViewPositionMiddle;
  }
}


- (void)drawRect:(CGRect)rect {
  // Drawing code
  CGContextRef c = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(c, [fillColor CGColor]);
  CGContextSetStrokeColorWithColor(c, [borderColor CGColor]);
  CGContextSetLineWidth(c, BORDER_SIZE);
                        
  if (position == CustomCellBackgroundViewPositionTop) {
    CGContextFillRect(c, CGRectMake(0.0f, rect.size.height - ROUND_SIZE, rect.size.width, ROUND_SIZE));
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, 0.0f, rect.size.height - ROUND_SIZE);
    CGContextAddLineToPoint(c, 0.0f, rect.size.height);
    CGContextAddLineToPoint(c, rect.size.width, rect.size.height);
    CGContextAddLineToPoint(c, rect.size.width, rect.size.height - ROUND_SIZE);
    CGContextStrokePath(c);
    CGContextClipToRect(c, CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height - ROUND_SIZE));
  } else if (position == CustomCellBackgroundViewPositionBottom) {
    CGContextFillRect(c, CGRectMake(0.0f, 0.0f, rect.size.width, ROUND_SIZE));
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, 0.0f, ROUND_SIZE);
    CGContextAddLineToPoint(c, 0.0f, 0.0f);
    CGContextStrokePath(c);
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, rect.size.width, 0.0f);
    CGContextAddLineToPoint(c, rect.size.width, ROUND_SIZE);
    CGContextStrokePath(c);
    CGContextClipToRect(c, CGRectMake(0.0f, ROUND_SIZE, rect.size.width, rect.size.height));
  } else if (position == CustomCellBackgroundViewPositionMiddle) {
    CGContextFillRect(c, rect);
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, 0.0f, 0.0f);
    CGContextAddLineToPoint(c, 0.0f, rect.size.height);
    CGContextAddLineToPoint(c, rect.size.width, rect.size.height);
    CGContextAddLineToPoint(c, rect.size.width, 0.0f);
    CGContextStrokePath(c);
    return; // no need to bother drawing rounded corners, so we return
  }
  else if (position == CustomCellBackgroundViewPositionSingle)
  {
    CGFloat minx = CGRectGetMinX(rect) , midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect) ;
    CGFloat miny = CGRectGetMinY(rect) , midy = CGRectGetMidY(rect) , maxy = CGRectGetMaxY(rect) ;
    minx = minx + 1;
    miny = miny + 1;
    maxx = maxx - 1;
    maxy = maxy - 1;
    
    CGContextMoveToPoint(c, minx, midy);
    CGContextAddArcToPoint(c, minx, miny, midx, miny, ROUND_SIZE);
    CGContextAddArcToPoint(c, maxx, miny, maxx, midy, ROUND_SIZE);
    CGContextAddArcToPoint(c, maxx, maxy, midx, maxy, ROUND_SIZE);
    CGContextAddArcToPoint(c, minx, maxy, minx, midy, ROUND_SIZE);
    
    CGContextClosePath(c);
    CGContextDrawPath(c, kCGPathFillStroke);                
    return;         
  }

  // At this point the clip rect is set to only draw the appropriate
  // corners, so we fill and stroke a rounded rect taking the entire rect

  CGContextBeginPath(c);
  addRoundedRectToPath(c, rect, ROUND_SIZE, ROUND_SIZE);
  CGContextFillPath(c);

  CGContextSetLineWidth(c, 1);
  CGContextBeginPath(c);
  addRoundedRectToPath(c, rect, ROUND_SIZE, ROUND_SIZE);
  CGContextStrokePath(c);                      
}

- (void)dealloc {
  [borderColor release];
  [fillColor release];
  [super dealloc];
}

@end

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth,float ovalHeight)
{
  float fw, fh;
  if (ovalWidth == 0 || ovalHeight == 0) {// 1
    CGContextAddRect(context, rect);
    return;
  }
  
  CGContextSaveGState(context);// 2
  CGContextTranslateCTM (context, CGRectGetMinX(rect),// 3
                         CGRectGetMinY(rect));
  CGContextScaleCTM (context, ovalWidth, ovalHeight);// 4
  fw = CGRectGetWidth (rect) / ovalWidth;// 5
  fh = CGRectGetHeight (rect) / ovalHeight;// 6
  CGContextMoveToPoint(context, fw, fh/2); // 7
  CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);// 8
  CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);// 9
  CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);// 10
  CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // 11
  CGContextClosePath(context);// 12
  CGContextRestoreGState(context);// 13
}