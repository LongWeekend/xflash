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

@interface AlgorithmSettingsViewController : UIViewController <UITableViewDelegate>
{
  UISlider *maxCardsUISlider;
  UISlider *frequencyUISlider;
  IBOutlet UISegmentedControl *difficultySegmentControl;
  IBOutlet UITableView *tableView;
}

- (IBAction) setDifficulty:(UISegmentedControl*)sender;
- (void)sliderAction:(UISlider*)sender;

@property (nonatomic, retain) UISlider *maxCardsUISlider;
@property (nonatomic, retain) UISlider *frequencyUISlider;
@property (nonatomic, retain) UISegmentedControl *difficultySegmentControl;
@property (nonatomic, retain) UITableView *tableView;

@end
