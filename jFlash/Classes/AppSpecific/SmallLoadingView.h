//
//  SmallLoadingView.h
//  jFlash
//
//  Created by Rendy Pranata on 29/07/10.
//  Copyright 2010 CRUX. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface SmallLoadingView : UIView 
{
	
}

+ (id)loadingView:(UIView *)aSuperview withText:(NSString *)text;
- (void)remove;

@end
