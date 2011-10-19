//
//  ReminderSettingsViewController.m
//  jFlash
//
//  Created by Mark Makdad on 10/19/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "ReminderSettingsViewController.h"

@implementation ReminderSettingsViewController

@synthesize remindersOn, onOffSwitch, timeSlider;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self)
  {
  }
  return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

#pragma mark - IBActions

- (IBAction) switchValueChanged:(UISwitch*)sender
{
  //TODO:
}

- (IBAction) sliderValueChanged:(UISlider*)sender
{
  //TODO;
}

#pragma mark - UITableViewDelegate Methods

#pragma mark - UITableViewDataSource Methods

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  if (self.remindersOn)
  {
    // Switch + settings
    return 2;
  }
  else
  {
    // Switch only
    return 1;
  }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == 0)
  {
    // On/off switch
    return 1;
  }
  else
  {
    // Reminder settings
    return 2;
  }
}

- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  if (indexPath.section == 0)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"reminder" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    cell.textLabel.text = NSLocalizedString(@"Study Reminders", @"RemindersVC.StudyRemindersSwitchLabel");
    cell.accessoryView = self.onOffSwitch;
  }
  else if (indexPath.section == 1)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"settings" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    if (indexPath.row == 0)
    {
      cell.textLabel.text = @"Days";
      cell.accessoryView = self.timeSlider;
    }
    else if (indexPath.row == 1)
    {
      cell.textLabel.text = @"results";
    }
  }
  return cell;
}

#pragma mark -

- (void) dealloc
{
  [timeSlider release];
  [onOffSwitch release];
  [super dealloc];
}

@end
