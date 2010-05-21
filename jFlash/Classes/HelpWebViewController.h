//
//  HelpWebViewController.h
//  jFlash
//
//  Created by Mark Makdad on 4/10/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HelpWebViewController : UIViewController
{
  NSString *filename;
}

- (id) initWithFilename:(NSString *)filename usingTitle:(NSString*) title;

@property (nonatomic, retain) NSString *filename;

@end
