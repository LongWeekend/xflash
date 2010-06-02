//
//  SettingsViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/17/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "SettingsViewController.h"
#import "UserViewController.h"

//TODO: this is only for debug
#import "ReportBadDataViewController.h"

@implementation SettingsViewController
@synthesize sectionArray, settingsChanged, headwordChanged, themeChanged, appirater, settingsDict;


- (SettingsViewController*) init
{
	if (self = [super initWithStyle:UITableViewStyleGrouped])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"20-gear2.png"];
    
    self.title = @"Settings";
    self.navigationItem.title = @"Settings";

    // The following dictionaries contain all the mappings from actual settings to how they display on the phone
    NSArray *modeObjects = [NSArray arrayWithObjects:@"Off", @"On", nil];
    NSArray *modeKeys = [NSArray arrayWithObjects:SET_MODE_QUIZ,SET_MODE_BROWSE,nil];
    NSDictionary* modeDict = [NSDictionary dictionaryWithObjects:modeObjects forKeys:modeKeys];
        
    NSArray *headwordObjects = [NSArray arrayWithObjects:@"Japanese", @"English", nil];
    NSArray *headwordKeys = [NSArray arrayWithObjects:SET_J_TO_E,SET_E_TO_J,nil];
    NSDictionary* headwordDict = [NSDictionary dictionaryWithObjects:headwordObjects forKeys:headwordKeys];
    
    // Source theme information from the ThemeManager
    ThemeManager *tm = [ThemeManager sharedThemeManager];
    NSDictionary* themeDict = [NSDictionary dictionaryWithObjects:[tm themeNameList] forKeys:[tm themeKeysList]];
    
    NSArray *readingObjects = [NSArray arrayWithObjects:@"Kana",@"Romaji",@"Both",nil];
    NSArray *readingKeys = [NSArray arrayWithObjects:SET_READING_KANA,SET_READING_ROMAJI,SET_READING_BOTH,nil];
    NSDictionary* readingDict = [NSDictionary dictionaryWithObjects:readingObjects forKeys:readingKeys];
    
    // Create a complete dictionary of all settings display names & their setting constants
    NSArray *dictObjects = [NSArray arrayWithObjects:headwordDict,themeDict,readingDict,modeDict,nil];
    NSArray *dictKeys = [NSArray arrayWithObjects:APP_HEADWORD,APP_THEME,APP_READING,APP_MODE,nil];
    self.settingsDict = [NSDictionary dictionaryWithObjects:dictObjects forKeys:dictKeys];

    // These are the keys and display names of each row
    NSArray *cardSettingNames = [NSArray arrayWithObjects:@"Browse Mode",@"Headword",@"Reading Display As",nil];
    NSArray *cardSettingKeys = [NSArray arrayWithObjects:APP_MODE,APP_HEADWORD,APP_READING,nil];
    NSArray *cardSettingArray = [NSArray arrayWithObjects:cardSettingNames,cardSettingKeys,@"",nil]; // Puts single section together, 3rd index is header name

    NSArray *userSettingNames = [NSArray arrayWithObjects:@"Active User",nil];
    NSArray *userSettingKeys = [NSArray arrayWithObjects:APP_USER,nil];
    NSArray *userSettingArray = [NSArray arrayWithObjects:userSettingNames,userSettingKeys,@"",nil];
    
    NSArray *appSettingNames = [NSArray arrayWithObjects:@"Theme",nil];
    NSArray *appSettingKeys = [NSArray arrayWithObjects:APP_THEME,nil];
    NSArray *appSettingArray = [NSArray arrayWithObjects:appSettingNames,appSettingKeys,@"",nil];
    
    NSArray *aboutNames = [NSArray arrayWithObjects:@"Japanese Flash was created on a Long Weekend over a few steaks and a few more Coronas. Special thanks goes to Teja for helping us write and simulate the frequency algorithm. This application also uses the EDICT dictionary files. These files are the property of the Electronic Dictionary Research and Development Group, and are used in conformance with the Group's license. Some icons by Joseph Wain / glyphish.com. The Japanese Flash Logo & Product Name are original creations and any perceived similarities to other trademarks is unintended and purely coincidental.",nil];
    NSArray *aboutKeys = [NSArray arrayWithObjects:@"about",nil];
    NSArray *aboutArray = [NSArray arrayWithObjects:aboutNames,aboutKeys,@"Acknowledgements",nil];
    
    // Make the order
    self.sectionArray = [NSArray arrayWithObjects:cardSettingArray,userSettingArray,appSettingArray,aboutArray,nil];
    
    settingsChanged = NO;
    headwordChanged = NO;
    themeChanged = NO;
  }
	return self;
}

- (void)loadView
{
  [super loadView];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"settingsWereChanged" object:nil];
}

- (void)viewWillAppear: (BOOL)animated
{
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  UIBarButtonItem *rateUsBtn = [[UIBarButtonItem alloc] initWithTitle:@"Rate Us" style:UIBarButtonItemStyleBordered target:self action:@selector(launchAppirater)];
  self.navigationItem.leftBarButtonItem = rateUsBtn;
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
  [[self tableView] reloadData];
  [rateUsBtn release];
}

// Only re-load the set if settings were changed, otherwise there is no need to do anything
- (void) viewWillDisappear: (BOOL)animated
{
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  if (settingsChanged)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"settingsWereChanged" object:self];
  }
  if (headwordChanged)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"directionWasChanged" object:self];
  }
  if (themeChanged)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"themeWasChanged" object:self];
  }
  headwordChanged = NO;
  settingsChanged = NO;
}


//! reloadTableData - convenience method for reloading
- (void)reloadTableData
{
  [[self tableView] reloadData];
}


//! launchAppirater - convenience method for appirater
- (void) launchAppirater
{
  appirater = [[Appirater alloc] init];
  [appirater showPromptManually];
}


//! Makes "setting" move to its next state
- (void) iterateSetting: (NSString*) setting
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSDictionary *dict = [settingsDict objectForKey:setting];
  NSEnumerator *enumerator = [dict keyEnumerator];
  NSString *currentValue = [settings objectForKey:setting];
  NSString *lclKey = nil;
  NSString *nextValue = nil;
  
  // Find current match in the enumeration and return the next object
  while ((lclKey = [enumerator nextObject]))
  {
    if ([lclKey isEqual:currentValue])
    {
      nextValue = [enumerator nextObject];
      break;
    }
  }
  // Now check if we got nothing because we were at the end of the list
  if (nextValue == nil)
  {
    NSEnumerator* tmpEnumerator = [dict keyEnumerator];
    nextValue = [tmpEnumerator nextObject];
  }
  [settings setValue:nextValue forKey:setting];
  return;
}


# pragma mark UI Table View Methods

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return [[self sectionArray] count];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger i = [[[[self sectionArray] objectAtIndex:section] objectAtIndex:0] count];
  return i;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  UITableViewCell *cell = nil;
  NSString *key = nil;
  NSString *displayName = nil;
  NSInteger row = [indexPath row];
  NSInteger section = [indexPath section];

  // Get our key name and display name
  NSArray *thisSectionArray = [[self sectionArray] objectAtIndex:section];
  key = [[thisSectionArray objectAtIndex:1] objectAtIndex:row];
  displayName = [[thisSectionArray objectAtIndex:0] objectAtIndex:row];
  
  // Handle special cases first
  if (key == APP_USER)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_USER onTable:tableView usingStyle:UITableViewCellStyleValue1];
    cell.detailTextLabel.text = [[User getUser:[settings integerForKey:APP_USER]] userNickname];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  else if (key == @"about")
  {
    // About section
    cell = [LWEUITableUtils reuseCellForIdentifier:@"other" onTable:tableView usingStyle:UITableViewCellStyleDefault];
  }
  else
  {
    // Anything else
    cell = [LWEUITableUtils reuseCellForIdentifier:key onTable:tableView usingStyle:UITableViewCellStyleValue1];
    cell.detailTextLabel.text = [[[self settingsDict] objectForKey:key] objectForKey:[settings objectForKey:key]];        
  }
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
  cell.textLabel.numberOfLines = 0;
  cell.textLabel.text = displayName;
  return cell;  
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  CGFloat size;
  NSArray* thisSectionArray = [[self sectionArray] objectAtIndex:indexPath.section];
  // Special case for about section
  if ([[thisSectionArray objectAtIndex:1] objectAtIndex:0] == @"about")
  {
    size = 435.0f;    
  }
  else
  {
    size = 44.0f;    
  }
  return size;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section = indexPath.section;
  NSInteger row = indexPath.row;

  NSArray *thisSectionArray = [[self sectionArray] objectAtIndex:section];
  NSString *key = [[thisSectionArray objectAtIndex:1] objectAtIndex:row];

  // Handle special cases first
  if (key == APP_USER)
  {
    UserViewController *userView = [[UserViewController alloc] init];
    [self.navigationController pushViewController:userView animated:YES];
    [userView release];
  }
  else if (key == @"about")
  {
    // Do nothing, about section
  }
  else
  {
    // Everything else
    settingsChanged = YES;
    [self iterateSetting:key];
    [self reloadTableData];
    if (key == APP_HEADWORD)
    {
      headwordChanged = YES;
    }
    else if (key == APP_THEME)
    {
      themeChanged = YES;
    }
  }
}

- (NSString *) tableView: (UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
  NSArray *thisSectionArray = [[self sectionArray] objectAtIndex:section];
  return [thisSectionArray objectAtIndex:2];
}

# pragma mark - Housekeeping

- (void)dealloc
{
  [settingsDict release];
  [sectionArray release];
  [appirater release];
  [super dealloc];
}

@end