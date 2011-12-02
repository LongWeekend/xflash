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

- (IBAction) setDifficulty:(UISegmentedControl*)sender;
- (IBAction) sliderValueChanged:(UISlider*)sender;

@property (nonatomic, retain) IBOutlet UISlider *maxCardsSlider;
@property (nonatomic, retain) IBOutlet UISlider *frequencySlider;
@property (nonatomic, retain) UISegmentedControl *difficultySegmentControl;
@property (nonatomic, retain) UITableView *tableView;

@end
