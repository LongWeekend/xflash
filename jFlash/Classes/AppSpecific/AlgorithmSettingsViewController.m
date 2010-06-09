//
//  algorithmSettingsViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/9/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "AlgorithmSettingsViewController.h"


@implementation AlgorithmSettingsViewController

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

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (id) init
{
	if (self = [super initWithStyle:UITableViewStyleGrouped])
  {
    //self.title = @"Settings";
    //self.navigationItem.title = @"Settings";
  }  
  return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
  
    self.navigationItem.title = @"Study Algorithm";
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}

-(NSString*) tableView: (UITableView*) tableView titleForHeaderInSection:(NSInteger)section{
  if (section == kControlsSection)
  {
    return @"Max Words in \"Studying\" level";
  }
  else if(section == kFrequencyMultiplierSection)
  {
    return @"New / Studying Card Frequency";
  }
  return @"";
}

// these numbers are controlled by enums at top of this page
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
  return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  // setup the cell for the full entry
  if(indexPath.section == kControlsSection)
  {
      cell = [LWEUITableUtils reuseCellForIdentifier:@"maxCards" onTable:tableView usingStyle:UITableViewCellStyleValue1];
      UISlider *maxCardsUISlider = [ [ UISlider alloc ] initWithFrame: CGRectMake(20, 0, 280, 50) ];
      
      NSNumber *sliderValue = [[NSNumber alloc] initWithInt: [settings integerForKey:APP_MAX_STUDYING]];
      
      maxCardsUISlider.minimumValue = MIN_MAX_STUDYING;
      maxCardsUISlider.maximumValue = MAX_MAX_STUDYING;
      maxCardsUISlider.value = [sliderValue floatValue];
      maxCardsUISlider.tag = kMaxCardsRow;
      maxCardsUISlider.continuous = NO;
      [maxCardsUISlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
      [cell addSubview: maxCardsUISlider];
      [maxCardsUISlider release];
  }
  else if (indexPath.section == kFrequencyMultiplierSection)
  {
      cell = [LWEUITableUtils reuseCellForIdentifier:@"frequency" onTable:tableView usingStyle:UITableViewCellStyleValue1];
      UISlider *frequencyUISlider = [ [ UISlider alloc ] initWithFrame: CGRectMake(20, 0, 280, 50) ];
      NSNumber *sliderValue = [[NSNumber alloc] initWithInt: [settings integerForKey:APP_FREQUENCY_MULTIPLIER]];
      
      frequencyUISlider.minimumValue = MIN_FREQUENCY_MULTIPLIER;
      frequencyUISlider.maximumValue = MAX_FREQUENCY_MULTIPLIER;
      frequencyUISlider.value = [sliderValue floatValue];
      frequencyUISlider.tag = kFrequencyMultiplierSection; 
      frequencyUISlider.continuous = NO;
      [frequencyUISlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
      [cell addSubview: frequencyUISlider];
      [frequencyUISlider release];
  }
  else 
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"cell" onTable:tableView usingStyle:UITableViewCellStyleDefault];
  }
  
  return cell;  
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
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
  [sender setValue:value];
  
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
    [super dealloc];
}


@end

