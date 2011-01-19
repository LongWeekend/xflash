//
//  GradientCustomCellBackgroundView.m
//

#import "GradientCustomCellBackgroundView.h"

static void addRoundedRectToPath(CGContextRef context, CGRect rect,float ovalWidth,float ovalHeight);

@implementation GradientCustomCellBackgroundView
@synthesize position;

- (BOOL) isOpaque 
{
  return NO;
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

- (id)initWithFrame:(CGRect)frame 
{
  if ((self = [super initWithFrame:frame])) 
  {
    // Initialization code
    const float* topCol = CGColorGetComponents([[UIColor redColor] CGColor]);
    const float* bottomCol = CGColorGetComponents([[UIColor blueColor] CGColor]);
    
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    /*
     CGFloat colors[] =
     {
       5.0 / 255.0, 140.0 / 255.0, 245.0 / 255.0, 1.00,
       1.0 / 255.0,  93.0 / 255.0, 230.0 / 255.0, 1.00,
     };*/
    CGFloat colors[]=
    {
      topCol[0], topCol[1], topCol[2], topCol[3],
      bottomCol[0], bottomCol[1], bottomCol[2], bottomCol[3]
    };
    gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
    CGColorSpaceRelease(rgb);
  }
  return self;
}

-(void)drawRect:(CGRect)rect 
{
  // Drawing code
  CGContextRef c = UIGraphicsGetCurrentContext();
  
  if (position == CustomCellBackgroundViewPositionTop) 
  {
    CGFloat minx = CGRectGetMinX(rect) , midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect) ;
    CGFloat miny = CGRectGetMinY(rect) , maxy = CGRectGetMaxY(rect) ;
    minx = minx + 1;
    miny = miny + 1;
    maxx = maxx - 1;
    maxy = maxy ;
    
    CGContextMoveToPoint(c, minx, maxy);
    CGContextAddArcToPoint(c, minx, miny, midx, miny, ROUND_SIZE);
    CGContextAddArcToPoint(c, maxx, miny, maxx, maxy, ROUND_SIZE);
    CGContextAddLineToPoint(c, maxx, maxy);
    
    // Close the path
    CGContextClosePath(c);
    
    CGContextSaveGState(c);
    CGContextClip(c);
    CGContextDrawLinearGradient(c, gradient, CGPointMake(minx,miny), CGPointMake(minx,maxy), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextRestoreGState(c);
    
    return;
  } 
  else if (position == CustomCellBackgroundViewPositionBottom) 
  {
    
    CGFloat minx = CGRectGetMinX(rect) , midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect) ;
    CGFloat miny = CGRectGetMinY(rect) , maxy = CGRectGetMaxY(rect) ;
    minx = minx + 1;
    miny = miny + 1;
    maxx = maxx - 1;
    maxy = maxy - 1;
    
    CGContextMoveToPoint(c, minx, miny);
    CGContextAddArcToPoint(c, minx, maxy, midx, maxy, ROUND_SIZE);
    CGContextAddArcToPoint(c, maxx, maxy, maxx, miny, ROUND_SIZE);
    CGContextAddLineToPoint(c, maxx, miny);
    // Close the path
    CGContextClosePath(c);
    
    CGContextSaveGState(c);
    CGContextClip(c);
    CGContextDrawLinearGradient(c, gradient, CGPointMake(minx,miny), CGPointMake(minx,maxy), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextRestoreGState(c);
    
    return;
  } 
  else if (position == CustomCellBackgroundViewPositionMiddle) 
  {
    CGFloat minx = CGRectGetMinX(rect) , maxx = CGRectGetMaxX(rect) ;
    CGFloat miny = CGRectGetMinY(rect) , maxy = CGRectGetMaxY(rect) ;
    minx = minx + 1;
    miny = miny + 1;
    maxx = maxx - 1;
    maxy = maxy ;
    
    CGContextMoveToPoint(c, minx, miny);
    CGContextAddLineToPoint(c, maxx, miny);
    CGContextAddLineToPoint(c, maxx, maxy);
    CGContextAddLineToPoint(c, minx, maxy);
    // Close the path
    CGContextClosePath(c);
    
    CGContextSaveGState(c);
    CGContextClip(c);
    CGContextDrawLinearGradient(c, gradient, CGPointMake(minx,miny), CGPointMake(minx,maxy), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextRestoreGState(c);
    
    return;
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
    
    // Close the path
    CGContextClosePath(c);              
    
    CGContextSaveGState(c);
    CGContextClip(c);
    CGContextDrawLinearGradient(c, gradient, CGPointMake(minx,miny), CGPointMake(minx,maxy), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextRestoreGState(c);
    return;         
  }
}

- (void)dealloc 
{
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
