//
//  WebGradientView.m
//  jFlash
//
//  Created by Mark Makdad on 6/21/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "WebGradientView.h"


@implementation WebGradientView

@synthesize subview;

- (id)initWithFrame:(CGRect)frame subview:(UIWebView*)aSubview
{
  if (self = [super initWithFrame:frame])
  {
    [self setSubview:aSubview];
    [self addSubview:[self subview]];
  }
  return self;
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	// Draw a clear background
	[[UIColor clearColor] setFill];
  CGContextFillRect(context, rect);
  
	// Create an image mask from what we've drawn so far
  CFDataRef imgData = (CFDataRef)[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"WebViewMask.png"]];
  NSLog(@"Getting file at %@",[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"WebViewMask.png"]);
	CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData (imgData);
  CGImageRef alphaMask = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, NO, kCGRenderingIntentDefault);
  
	// Draw a white background (overwriting the previous work)
  //	[[UIColor whiteColor] setFill];
  //	CGContextFillRect(context, rect);
  
  // Draw the image, clipped by the mask
	CGContextSaveGState(context);
	CGContextClipToMask(context, rect, alphaMask);
	CGContextRestoreGState(context);
	CGImageRelease(alphaMask);
}


- (void)dealloc
{
  [[self subview] removeFromSuperview];
  [self setSubview:nil];
  [super dealloc];
}

@end
