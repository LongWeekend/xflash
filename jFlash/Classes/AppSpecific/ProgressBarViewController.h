//
//  ProgressBarViewController.h
//  jFlash
//
//  Created by シャロット ロス on 5/27/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDColoredProgressView.h"


@interface ProgressBarViewController : UIViewController {
  NSMutableArray* levelDetails;
  
  IBOutlet UILabel *cardSetProgressLabel1;
  IBOutlet UILabel *cardSetProgressLabel2;
  IBOutlet UILabel *cardSetProgressLabel3;
  IBOutlet UILabel *cardSetProgressLabel4;
  IBOutlet UILabel *cardSetProgressLabel5;
}

- (void) drawProgressBar;

@property (nonatomic, retain) NSMutableArray *levelDetails;
@property (nonatomic, retain) UILabel *cardSetProgressLabel1;
@property (nonatomic, retain) UILabel *cardSetProgressLabel2;
@property (nonatomic, retain) UILabel *cardSetProgressLabel3;
@property (nonatomic, retain) UILabel *cardSetProgressLabel4;
@property (nonatomic, retain) UILabel *cardSetProgressLabel5;

@end
