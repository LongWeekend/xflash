//
//  SettingsViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/17/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "SettingsViewController.h"
#import "PluginSettingsViewController.h"
#import "UserViewController.h"

@implementation SettingsViewController
@synthesize sectionArray, settingsChanged, headwordChanged, themeChanged, appirater, settingsDict;

NSString * const APP_ABOUT = @"about";
NSString * const APP_TWITTER = @"twitter";
NSString * const APP_FACEBOOK = @"facebook";

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
    NSArray *cardSettingArray = [NSArray arrayWithObjects:cardSettingNames,cardSettingKeys,@"Studying",nil]; // Puts single section together, 3rd index is header name

    NSArray *userSettingNames = [NSArray arrayWithObjects:@"Theme",@"Active User",@"Plugins",nil];
    NSArray *userSettingKeys = [NSArray arrayWithObjects:APP_THEME,APP_USER,APP_PLUGIN,nil];
    NSArray *userSettingArray = [NSArray arrayWithObjects:userSettingNames,userSettingKeys,@"Application",nil];
    
    NSArray *socialNames = [NSArray arrayWithObjects:@"Follow us on Twitter",@"See us on Facebook",nil];
    NSArray *socialKeys = [NSArray arrayWithObjects:APP_TWITTER,APP_FACEBOOK,nil];
    NSArray *socialArray = [NSArray arrayWithObjects:socialNames,socialKeys,@"Follow Us",nil];

    NSArray *aboutNames = [NSArray arrayWithObjects:@"Japanese Flash was created on a Long Weekend over a few steaks and a few more Coronas. Special thanks goes to Teja for helping us write and simulate the frequency algorithm. This application also uses the EDICT dictionary files. These files are the property of the Electronic Dictionary Research and Development Group, and are used in conformance with the Group's license. Some icons by Joseph Wain / glyphish.com. The Japanese Flash Logo & Product Name are original creations and any perceived similarities to other trademarks is unintended and purely coincidental.",nil];
    NSArray *aboutKeys = [NSArray arrayWithObjects:APP_ABOUT,nil];
    NSArray *aboutArray = [NSArray arrayWithObjects:aboutNames,aboutKeys,@"Acknowledgements",nil];
    
    // Make the order
    self.sectionArray = [NSArray arrayWithObjects:cardSettingArray,userSettingArray,socialArray,aboutArray,nil];
    
    settingsChanged = NO;
    headwordChanged = NO;
    themeChanged = NO;
  }
	return self;
}

- (void)loadView
{
  [super loadView];
  [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:@"settingsWereChanged" object:nil];
}

- (void)viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
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
  [super viewWillDisappear:animated];
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
  else if (key == APP_PLUGIN)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_PLUGIN onTable:tableView usingStyle:UITableViewCellStyleValue1];
    int numInstalled = [[[[CurrentState sharedCurrentState] pluginMgr] loadedPluginsByKey] count];
    if (numInstalled > 0)
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%d installed",numInstalled];
    else
      cell.detailTextLabel.text = @"None";

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  else if (key == APP_ABOUT)
  {
    // About section
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_ABOUT onTable:tableView usingStyle:UITableViewCellStyleDefault];
  }
  else if (key == APP_FACEBOOK || key == APP_TWITTER)
  {
    // Set up the image
    cell = [LWEUITableUtils reuseCellForIdentifier:@"social" onTable:tableView usingStyle:UITableViewCellStyleDefault];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    UIImageView* tmpView = cell.imageView;
    if(key == APP_TWITTER)
      tmpView.image = [UIImage imageNamed:@"twitter-icon.png"];
    else
      tmpView.image = [UIImage imageNamed:@"facebook-icon.png"];
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
  // Special case for about section - TODO: this is hardcoded
  if (indexPath.section == 3)
  {
    size = 435.0f;    
  }
  else
  {
    size = 44.0f;    
  }
  return size;
}


//! Make selection for a table cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section = indexPath.section;
  NSInteger row = indexPath.row;

  NSArray *thisSectionArray = [[self sectionArray] objectAtIndex:section];
  NSString *key = [[thisSectionArray objectAtIndex:1] objectAtIndex:row];

  if (key == APP_USER)
  {
    UserViewController *userView = [[UserViewController alloc] init];
    [self.navigationController pushViewController:userView animated:YES];
    [userView release];
  }
  else if (key == APP_PLUGIN)
  {
    PluginSettingsViewController *psvc = [[PluginSettingsViewController alloc] initWithNibName:@"PluginSettingsView" bundle:nil];
    [self.navigationController pushViewController:psvc animated:YES];
    [psvc release];
  }
  else if (key == APP_ABOUT)
  {
    // Do nothing, about section
  }
  else if (key == APP_TWITTER || key == APP_FACEBOOK)
  {
    // Load a UIWebView to show
    UIViewController *webVC = [[UIViewController alloc] init];
    UIWebView *webView = [[UIWebView alloc] init];
    webVC.title = @"Follow Us";
    webVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStyleBordered target:webView action:@selector(reload)];

    NSURL *url = nil;
    if (key == APP_FACEBOOK)
      url = [NSURL URLWithString:@"http://m.facebook.com/pages/Japanese-Flash/111141367918"];
    else
      url = [NSURL URLWithString:@"http://twitter.com/long_weekend/"];
      
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
    webView.delegate = self;
    webVC.view = webView;

    [self.navigationController pushViewController:webVC animated:YES];
    [webVC release];
  }
  else
  {
    // Everything else
    [self iterateSetting:key];
    [[self tableView] reloadData];
    if (key == APP_HEADWORD) // we don't want the current card to change for just a headword switch
    {
      headwordChanged = YES;
    }
    else if (key == APP_THEME)
    {
      themeChanged = YES;
    }
    else
    {
      settingsChanged = YES;
    }
  }
}

- (NSString *) tableView: (UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
  NSArray *thisSectionArray = [[self sectionArray] objectAtIndex:section];
  return [thisSectionArray objectAtIndex:2];
}

# pragma mark - UIWebView delegate methods

//! UIWebView delegate method - called if request fialed
- (void) webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unable to Connect" message:@"Please check your network connection and try again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
  [alertView show];
  [alertView release];
}

# pragma mark - Housekeeping

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
  
  [settingsDict release];
  [sectionArray release];
  [appirater release];
  [super dealloc];
}

@end