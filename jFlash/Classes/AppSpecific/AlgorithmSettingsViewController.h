//
//  AlgorithmSettingsViewController.h
//  jFlash
//
//  Created by シャロット ロス on 6/9/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThemeManager.h"
#import "Constants.h"

@interface AlgorithmSettingsViewController : UITableViewController {
  UISlider *maxCardsUISlider;
  UISlider *frequencyUISlider;
}

@property (nonatomic, retain) UISlider *maxCardsUISlider;
@property (nonatomic, retain) UISlider *frequencyUISlider;

@end
