//
//  WebGradientView.h
//  jFlash
//
//  Created by Mark Makdad on 6/21/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebGradientView : UIView
{
  UIView *subview;
}

- (id)initWithFrame:(CGRect)frame subview:(UIWebView*)aSubview;

@property (nonatomic, retain) UIView *subview;

@end
