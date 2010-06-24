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
  NUM_SECTIONS
};

enum ControlSectionRows
{
  kMaxCardsRow = 0,
  NUM_CONTROL_SECTION_ROWS
};

- (void)viewDidLoad 
{
  [super viewDidLoad];  
   self.navigationItem.title = NSLocalizedString(@"Change Difficulty",@"AlgorithmSettingsViewController.NavBarTitle");
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
  difficultySegmentControl.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSNumber *segmentedIndex = [[NSNumber alloc] initWithInt: [settings integerForKey:APP_DIFFICULTY]];
  difficultySegmentControl.selectedSegmentIndex = [segmentedIndex intValue];
  [segmentedIndex release];
  [self setDifficulty:difficultySegmentControl];
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return NUM_SECTIONS;
}

-(NSString*) tableView: (UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == kControlsSection)
  {
    return @"Number of Cards in Study Pool";
  }
  else if(section == kFrequencyMultiplierSection)
  {
    return @"Frequency of New Cards";
  }
  return @"";
}

// these numbers are controlled by enums at top of this page
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
  return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)lcltableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if(indexPath.section == kControlsSection)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"maxCards" onTable:lcltableView usingStyle:UITableViewCellStyleValue1];
    UISlider *tmpSlider = [[UISlider alloc] initWithFrame: CGRectMake(40, 0, 230, 48)];
    [self setMaxCardsUISlider:tmpSlider];
    [tmpSlider release];
    
    NSNumber *sliderValue = [[NSNumber alloc] initWithInt: [settings integerForKey:APP_MAX_STUDYING]];
    maxCardsUISlider.minimumValue = MIN_MAX_STUDYING;
    maxCardsUISlider.maximumValue = MAX_MAX_STUDYING;
    maxCardsUISlider.value = [sliderValue floatValue];
    maxCardsUISlider.tag = kMaxCardsRow;
    maxCardsUISlider.continuous = NO;
    [maxCardsUISlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    cell.textLabel.text = [NSString stringWithFormat:@"%d", MIN_MAX_STUDYING];
    [cell addSubview: maxCardsUISlider];
    UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(280, 5, 20, 35)];
    rightLabel.font = [UIFont boldSystemFontOfSize:17];
    rightLabel.text = [NSString stringWithFormat:@"%d", MAX_MAX_STUDYING];
    [cell addSubview:rightLabel];
    [rightLabel release];
  }
  else if (indexPath.section == kFrequencyMultiplierSection)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"frequency" onTable:lcltableView usingStyle:UITableViewCellStyleValue1];
    UISlider *tmpSlider = [[UISlider alloc] initWithFrame: CGRectMake(20, 0, 180, 50)];
    [self setFrequencyUISlider:tmpSlider];
    [tmpSlider release];
    
    NSNumber *sliderValue = [[NSNumber alloc] initWithInt: [settings integerForKey:APP_FREQUENCY_MULTIPLIER]];
    frequencyUISlider.minimumValue = MIN_FREQUENCY_MULTIPLIER;
    frequencyUISlider.maximumValue = MAX_FREQUENCY_MULTIPLIER;
    frequencyUISlider.value = [sliderValue floatValue];
    frequencyUISlider.tag = kFrequencyMultiplierSection; 
    frequencyUISlider.continuous = NO;
    [frequencyUISlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [cell addSubview: frequencyUISlider];
    UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(210, 5, 95, 35)];
    rightLabel.font = [UIFont boldSystemFontOfSize:17];
    rightLabel.text = [NSString stringWithFormat:@"More Often"];
    [cell addSubview:rightLabel];
    [rightLabel release];
    [sliderValue release];
  }
  else 
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"cell" onTable:lcltableView usingStyle:UITableViewCellStyleDefault];
  }
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;  
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}

#pragma mark -
#pragma mark Segmented Control

/*!
    @function
    @abstract   Sets the ui sliders values based on the segmented value selected by the user
    @param      UISegmentedControl* sender
    @result     Void
*/
- (IBAction) setDifficulty:(UISegmentedControl*)sender
{
  int value = [sender selectedSegmentIndex];
  
  // store the result
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];  
  [settings setInteger:value forKey:APP_DIFFICULTY];

  LWE_LOG(@"segmentedCotnrolAction: sender = %d, value = %d", [sender tag], value);
  
  [maxCardsUISlider setEnabled:NO];
  [frequencyUISlider setEnabled:NO];
  
  if(value == 0)
  {
    // TODO: Refactor - pull these numbers out into constants?
    [maxCardsUISlider setValue:10];
    [frequencyUISlider setValue:1];
  }
  else if(value == 1)
  {
    [maxCardsUISlider setValue:30];
    [frequencyUISlider setValue:2];
  }
  else if(value == 2)
  {
    [maxCardsUISlider setValue:40];
    [frequencyUISlider setValue:3];
  }
  else if (value == 3)
  {
    [maxCardsUISlider setEnabled:YES];
    [frequencyUISlider setEnabled:YES];
  }
  [self sliderAction:maxCardsUISlider];
  [self sliderAction:frequencyUISlider];
}

#pragma mark -
#pragma mark Slider

- (void)sliderAction:(UISlider*)sender
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  int value = lroundf([sender value]);
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


#pragma mark -
#pragma mark Class Plumbing

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
  [maxCardsUISlider release];
  [frequencyUISlider release];
  [difficultySegmentControl release];
  [tableView release];
  [super dealloc];
}

@end