//
//  ProgressBarViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/27/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDColoredProgressView.h"


@interface ProgressBarViewController : UIViewController

- (void) drawProgressBar;

@property (nonatomic, retain) NSMutableArray *levelDetails;

@end
