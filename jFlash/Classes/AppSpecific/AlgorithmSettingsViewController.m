//
//  algorithmSettingsViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/9/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "AlgorithmSettingsViewController.h"


@implementation AlgorithmSettingsViewController
@synthesize maxCardsUISlider, frequencyUISlider, difficultySegmentControl, tableView;

enum Sections {
  kControlsSection = 0,
  kFrequencyMultiplierSection = 1,
  kShowBurriedSection = 2,
  NUM_SECTIONS
};

enum ControlSectionRows
{
  kMaxCardsRow = 0,
  NUM_CONTROL_SECTION_ROWS
};

#pragma mark - UIViewController Methods

- (void)viewDidLoad 
{
  [super viewDidLoad];  
   self.navigationItem.title = NSLocalizedString(@"Change Difficulty",@"AlgorithmSettingsViewController.NavBarTitle");
}

- (void)viewDidUnload 
{
  self.maxCardsUISlider = nil;
  self.frequencyUISlider = nil;
  self.difficultySegmentControl = nil;
  self.tableView = nil;
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  // TODO: iPad customization!
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.tableView.backgroundColor = [UIColor clearColor];
  self.difficultySegmentControl.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
}

// TODO: why is viewDidAppear here and this code not in viewWillAppear?  Or even viewDidLoad?
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSNumber *segmentedIndex = [NSNumber numberWithInt:[settings integerForKey:APP_DIFFICULTY]];
  self.difficultySegmentControl.selectedSegmentIndex = [segmentedIndex intValue];
  [self setDifficulty:self.difficultySegmentControl];
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
  return NUM_SECTIONS;
}

-(NSString*) tableView: (UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
  NSString *returnVal = @"";
  if (section == kControlsSection)
  {
    returnVal = NSLocalizedString(@"Number of Cards in Study Pool",@"AlgorithmVC.NumberCards");
  }
  else if (section == kFrequencyMultiplierSection)
  {
    returnVal = NSLocalizedString(@"Frequency of New Cards",@"AlgorithmVC.NewCardFrequency");
  }
  return returnVal;
}

// these numbers are controlled by enums at top of this page
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
  return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)lcltableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if(indexPath.section == kControlsSection)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"maxCards" onTable:lcltableView usingStyle:UITableViewCellStyleValue1];
    NSNumber *sliderValue = [NSNumber numberWithInt:[settings integerForKey:APP_MAX_STUDYING]];
    // TODO: iPad customization!
    self.maxCardsUISlider = [[[UISlider alloc] initWithFrame: CGRectMake(40, 0, 230, 48)] autorelease];
    self.maxCardsUISlider.minimumValue = MIN_MAX_STUDYING;
    self.maxCardsUISlider.maximumValue = MAX_MAX_STUDYING;
    self.maxCardsUISlider.value = [sliderValue floatValue];
    self.maxCardsUISlider.tag = kMaxCardsRow;
    self.maxCardsUISlider.continuous = NO;
    [self.maxCardsUISlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];

    // the label on the left of the cell
    // TODO: iPad customization!
    UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, 20, 35)];
    leftLabel.font = [UIFont boldSystemFontOfSize:17];
    leftLabel.text = [NSString stringWithFormat:@"%d", MIN_MAX_STUDYING];
    [cell addSubview:leftLabel];
    [leftLabel release];
    
    // the slider
    [cell addSubview: maxCardsUISlider];
    
    // the label on the right
    // TODO: iPad customization!
    UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(280, 5, 20, 35)];
    // TODO: iPad customization!
    rightLabel.font = [UIFont boldSystemFontOfSize:17];
    rightLabel.text = [NSString stringWithFormat:@"%d", MAX_MAX_STUDYING];
    [cell addSubview:rightLabel];
    
    [rightLabel release];
  }
  else if (indexPath.section == kFrequencyMultiplierSection)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"frequency" onTable:lcltableView usingStyle:UITableViewCellStyleValue1];
    NSNumber *sliderValue = [NSNumber numberWithInt:[settings integerForKey:APP_FREQUENCY_MULTIPLIER]];

    // TODO: iPad customization!
    self.frequencyUISlider = [[[UISlider alloc] initWithFrame:CGRectMake(20, 0, 180, 50)] autorelease];
    self.frequencyUISlider.minimumValue = MIN_FREQUENCY_MULTIPLIER;
    self.frequencyUISlider.maximumValue = MAX_FREQUENCY_MULTIPLIER;
    self.frequencyUISlider.value = [sliderValue floatValue];
    self.frequencyUISlider.tag = kFrequencyMultiplierSection; 
    self.frequencyUISlider.continuous = NO;
    [self.frequencyUISlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [cell addSubview:self.frequencyUISlider];
    // TODO: iPad customization!
    UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(210, 5, 95, 35)];
    // TODO: iPad customization!
    rightLabel.font = [UIFont boldSystemFontOfSize:17];
    rightLabel.text = [NSString stringWithFormat:@"More Often"];
    [cell addSubview:rightLabel];
    [rightLabel release];
  }
  else if (indexPath.section == kShowBurriedSection)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"showBuried" onTable:lcltableView usingStyle:UITableViewCellStyleDefault];
    BOOL hideBuriedCard = [settings boolForKey:APP_HIDE_BURIED_CARDS];
    
    cell.textLabel.text = NSLocalizedString(@"Hide Learned Cards",@"AlgorithmVC.HideLearnedCards");
    
    //Documentation says that the size component will be completely ignored
    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switchView setOn:hideBuriedCard];
    [switchView addTarget:self action:@selector(switchView_eventValueChanged:) forControlEvents:UIControlEventValueChanged];
    [cell setAccessoryView:switchView];
    [cell addSubview:switchView];
    [switchView release];
  }
  else 
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"cell" onTable:lcltableView usingStyle:UITableViewCellStyleDefault];
  }
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;  
}

#pragma mark - Segmented Control

/**
 * Sets the ui sliders values based on the segmented value selected by the user
 * \param sender UISegmentedControl object that called this
 */
- (IBAction) setDifficulty:(UISegmentedControl *)sender
{
  NSInteger selectedIndex = [sender selectedSegmentIndex];
  LWE_ASSERT_EXC((selectedIndex < 4),@"We should only have 4 levels, zero-indexed (0,1,2,3).");
  
  // store the result
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];  
  [settings setInteger:selectedIndex forKey:APP_DIFFICULTY];
  
  if (selectedIndex == 3)
  {
    // The last index - custom value
    self.maxCardsUISlider.enabled = YES;
    self.frequencyUISlider.enabled = YES;
  }
  else
  {
    // Otherwise pull from these predefined values
    NSInteger maxCardsValue[3] = {10,30,40};
    NSInteger freqValue[3] = {1,2,3};
    self.maxCardsUISlider.enabled = NO;
    self.frequencyUISlider.enabled = NO;
    self.maxCardsUISlider.value = maxCardsValue[selectedIndex];
    self.frequencyUISlider.value = freqValue[selectedIndex];
  }
  [self sliderAction:self.maxCardsUISlider];
  [self sliderAction:self.frequencyUISlider];
}

#pragma mark - Slider

- (void)sliderAction:(UISlider *)sender
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSInteger value = lroundf([sender value]);
  if([sender tag] == kMaxCardsRow)
  {
    [settings setInteger:value forKey:APP_MAX_STUDYING];
  }
  else if ([sender tag] == kFrequencyMultiplierSection)
  {
    [settings setInteger:value forKey:APP_FREQUENCY_MULTIPLIER];
  }
  
  LWE_LOG(@"sliderAction: sender = %d, value = %d", [sender tag], value);
}

#pragma mark - UISwitch

- (void)switchView_eventValueChanged:(id)sender
{
  UISwitch *switchView = (UISwitch *)sender; 
  BOOL newValue = [switchView isOn];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  [settings setBool:newValue forKey:APP_HIDE_BURIED_CARDS];
}


#pragma mark - Class Plumbing

- (void)dealloc 
{
  [maxCardsUISlider release];
  [frequencyUISlider release];
  [difficultySegmentControl release];
  [tableView release];
  [super dealloc];
}

@end