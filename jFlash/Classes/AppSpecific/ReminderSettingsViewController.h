//
//  ReminderSettingsViewController.h
//  jFlash
//
//  Created by Mark Makdad on 10/19/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReminderSettingsViewController : UITableViewController

- (IBAction) switchValueChanged:(UISwitch*)sender;
- (IBAction) sliderValueChanged:(UISlider*)sender;

@property BOOL remindersOn;

@property (nonatomic,retain) IBOutlet UISwitch *onOffSwitch;
@property (nonatomic,retain) IBOutlet UISlider *timeSlider;
@end