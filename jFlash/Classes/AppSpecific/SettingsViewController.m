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
#import "UserPeer.h"
#import "VersionManager.h"

@implementation SettingsViewController
@synthesize sectionArray, settingsChanged, headwordChanged, themeChanged, readingChanged, appirater, settingsDict;

NSString * const APP_ABOUT = @"about";
NSString * const APP_TWITTER = @"twitter";
NSString * const APP_FACEBOOK = @"facebook";
NSString * const APP_ALGORITHM = @"algorithm";

- (SettingsViewController*) init
{
	if (self = [super initWithStyle:UITableViewStyleGrouped])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"20-gear2.png"];
    self.title = NSLocalizedString(@"Settings",@"SettingsViewController.NavBarTitle");

    // The following dictionaries contain all the mappings from actual settings to how they display on the phone
    NSArray *modeObjects = [NSArray arrayWithObjects:NSLocalizedString(@"Practice",@"SettingsViewController.Practice"), NSLocalizedString(@"Browse",@"SettingsViewController.Browse"), nil];
    NSArray *modeKeys = [NSArray arrayWithObjects:SET_MODE_QUIZ,SET_MODE_BROWSE,nil];
    NSDictionary* modeDict = [NSDictionary dictionaryWithObjects:modeObjects forKeys:modeKeys];
        
    NSArray *headwordObjects = [NSArray arrayWithObjects:NSLocalizedString(@"Japanese",@"SettingsViewController.HeadwordLanguage_Japanese"), 
                                                         NSLocalizedString(@"English",@"SettingsViewController.HeadwordLanguage_English"), nil];
    NSArray *headwordKeys = [NSArray arrayWithObjects:SET_J_TO_E,SET_E_TO_J,nil];
    NSDictionary* headwordDict = [NSDictionary dictionaryWithObjects:headwordObjects forKeys:headwordKeys];
    
    // Source theme information from the ThemeManager
    ThemeManager *tm = [ThemeManager sharedThemeManager];
    NSDictionary* themeDict = [NSDictionary dictionaryWithObjects:[tm themeNameList] forKeys:[tm themeKeysList]];
    
    NSArray *readingObjects = [NSArray arrayWithObjects:NSLocalizedString(@"Kana",@"SettingsViewController.DisplayReading_Kana"),
                                                        NSLocalizedString(@"Romaji",@"SettingsViewController.DisplayReading_Romaji"),
                                                        NSLocalizedString(@"Both",@"SettingsViewController.DisplayReading_Both"),nil];
    NSArray *readingKeys = [NSArray arrayWithObjects:SET_READING_KANA,SET_READING_ROMAJI,SET_READING_BOTH,nil];
    NSDictionary* readingDict = [NSDictionary dictionaryWithObjects:readingObjects forKeys:readingKeys];
    
    // Create a complete dictionary of all settings display names & their setting constants
    NSArray *dictObjects = [NSArray arrayWithObjects:headwordDict,themeDict,readingDict,modeDict,nil];
    NSArray *dictKeys = [NSArray arrayWithObjects:APP_HEADWORD,APP_THEME,APP_READING,APP_MODE,nil];
    self.settingsDict = [NSDictionary dictionaryWithObjects:dictObjects forKeys:dictKeys];

    // These are the keys and display names of each row
    NSArray *cardSettingNames = [NSArray arrayWithObjects:NSLocalizedString(@"Study Mode",@"SettingsViewController.SettingNames_StudyMode"),
                                                          NSLocalizedString(@"Study Language",@"SettingsViewController.SettingNames_StudyLanguage"),
                                                          NSLocalizedString(@"Furigana / Reading",@"SettingsViewController.SettingNames_DisplayFuriganaReading"),
                                                          NSLocalizedString(@"Difficulty",@"SettingsViewController.SettingNames_ChangeDifficulty"),nil];
    NSArray *cardSettingKeys = [NSArray arrayWithObjects:APP_MODE,APP_HEADWORD,APP_READING,APP_ALGORITHM,nil];
    NSArray *cardSettingArray = [NSArray arrayWithObjects:cardSettingNames,cardSettingKeys,NSLocalizedString(@"Studying",@"SettingsViewController.TableHeader_Studying"),nil]; // Puts single section together, 3rd index is header name

    NSMutableArray *userSettingNames = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Theme",@"SettingsViewController.SettingNames_Theme"),
                                        NSLocalizedString(@"Active User",@"SettingsViewController.SettingNames_ActiveUser"),
                                        NSLocalizedString(@"Updates",@"SettingsViewController.SettingNames_DownloadExtras"),nil];
    NSMutableArray *userSettingKeys = [NSMutableArray arrayWithObjects:APP_THEME,APP_USER,APP_PLUGIN,nil];

    // Can we upgrade at all?  If so, hide the plugins
    if ([VersionManager databaseIsUpdatable])
    {
      [userSettingNames removeLastObject];
      [userSettingKeys removeLastObject];
    }
    
    NSArray *userSettingArray = [NSArray arrayWithObjects:userSettingNames,userSettingKeys,NSLocalizedString(@"Application",@"SettingsViewController.TableHeader_Application"),nil];
    
    NSArray *socialNames = [NSArray arrayWithObjects:NSLocalizedString(@"Follow us on Twitter",@"SettingsViewController.SettingNames_Twitter"),
                                                     NSLocalizedString(@"See us on Facebook",@"SettingsViewController.SettingNames_Facebook"),nil];
    NSArray *socialKeys = [NSArray arrayWithObjects:APP_TWITTER,APP_FACEBOOK,nil];
    NSArray *socialArray = [NSArray arrayWithObjects:socialNames,socialKeys,NSLocalizedString(@"Follow Us",@"SettingsViewController.TableHeader_FollowUs"),nil];

    NSArray *aboutNames = [NSArray arrayWithObjects:NSLocalizedString(@"Japanese Flash was created on a Long Weekend over a few steaks and a few more Coronas. Special thanks goes to Teja for helping us write and simulate the frequency algorithm. This application also uses data from the EDICT dictionary and Tanaka Corpus. The EDICT files are property of the Electronic Dictionary Research and Development Group, and are used in conformance with the Group's license. Some icons by Joseph Wain / glyphish.com. The Japanese Flash Logo & Product Name are original creations and any perceived similarities to other trademarks is unintended and purely coincidental.",@"SettingsViewController.Acknowledgements"),nil];
    NSArray *aboutKeys = [NSArray arrayWithObjects:APP_ABOUT,nil];
    NSArray *aboutArray = [NSArray arrayWithObjects:aboutNames,aboutKeys,NSLocalizedString(@"Acknowledgements",@"SettingsViewController.TableHeader_Acknowledgements"),nil];
    
    // Make the order
  

    self.sectionArray = [NSArray arrayWithObjects:cardSettingArray,userSettingArray,socialArray,aboutArray,nil];
    
    settingsChanged = NO;
    headwordChanged = NO;
    themeChanged = NO;
    readingChanged = NO;
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
  UIBarButtonItem *rateUsBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Rate Us",@"SettingsViewController.RateUsButton") style:UIBarButtonItemStyleBordered target:self action:@selector(_launchAppirater)];
  self.navigationItem.leftBarButtonItem = rateUsBtn;
  [rateUsBtn release];
  
  // Do we need to show a button on the other side?
  if ([VersionManager databaseIsUpdatable])
  {
    UIBarButtonItem *updateBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update",@"SettingsViewController.UpdateButton") style:UIBarButtonItemStyleBordered target:self action:@selector(_showUpdaterModal)];
    self.navigationItem.rightBarButtonItem = updateBtn;
    [updateBtn release];
  }
  
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
  [[self tableView] reloadData];
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
  if (readingChanged)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"readingWasChanged" object:self];
  }
  
  // we've sent the notifications, so reset to unchanged
  headwordChanged = NO;
  themeChanged = NO;
  readingChanged = NO;
  settingsChanged = NO;
}

//! showUpdaterModal - convenience method for updater
- (void) _showUpdaterModal
{
  [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldShowUpdaterModal" object:self];
}


//! launchAppirater - convenience method for appirater
- (void) _launchAppirater
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
    cell.detailTextLabel.text = [[UserPeer getUserByPK:[settings integerForKey:APP_USER]] userNickname];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  else if (key == APP_PLUGIN)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_PLUGIN onTable:tableView usingStyle:UITableViewCellStyleValue1];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    int numInstalled = [[[[CurrentState sharedCurrentState] pluginMgr] loadedPluginsByKey] count];
    if (numInstalled > 0)
      cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d installed",@"SettingsViewController.Plugins_NumInstalled"),numInstalled];
    else
      cell.detailTextLabel.text = NSLocalizedString(@"None",@"Global.None");
  }
  else if (key == APP_ABOUT)
  {
    // About section
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_ABOUT onTable:tableView usingStyle:UITableViewCellStyleDefault];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  else if (key == APP_FACEBOOK || key == APP_TWITTER)
  {
    // Set up the image
    cell = [LWEUITableUtils reuseCellForIdentifier:@"social" onTable:tableView usingStyle:UITableViewCellStyleDefault];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    UIImageView* tmpView = cell.imageView;
    if(key == APP_TWITTER)
      tmpView.image = [UIImage imageNamed:@"twitter-icon.png"];
    else
      tmpView.image = [UIImage imageNamed:@"facebook-icon.png"];
  }
  else if (key == APP_ALGORITHM)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_ALGORITHM onTable:tableView usingStyle:UITableViewCellStyleDefault];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  }
  else
  {
    // Anything else
    cell = [LWEUITableUtils reuseCellForIdentifier:key onTable:tableView usingStyle:UITableViewCellStyleValue1];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.text = [[[self settingsDict] objectForKey:key] objectForKey:[settings objectForKey:key]];        
  }
  
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
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  
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
    webVC.title = NSLocalizedString(@"Follow Us",@"SettingsViewController.TableHeader_FollowUs");
    webVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reload",@"Global.Reload")
                                                                       style:UIBarButtonItemStyleBordered target:webView action:@selector(reload)];

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
  else if (key == APP_ALGORITHM)
  {
    AlgorithmSettingsViewController *avc = [[AlgorithmSettingsViewController alloc] init];
    [self.navigationController pushViewController:avc animated:YES];
    [avc release];
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
      // Also reload the nav bar for this page
      self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
    }
    else if (key == APP_READING)
    {
      readingChanged = YES; 
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
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to Connect",@"Network.UnableToConnect_AlertViewTitle")
                                                message:NSLocalizedString(@"Please check your network connection and try again.",@"Network.UnableToConnect_AlertViewMessage")
                                                delegate:self
                                                cancelButtonTitle:nil
                                                otherButtonTitles:NSLocalizedString(@"OK",@"Global.OK"),nil];
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