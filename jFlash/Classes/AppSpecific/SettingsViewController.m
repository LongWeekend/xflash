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

@implementation SettingsViewController
@synthesize sectionArray, settingsChanged, directionChanged, themeChanged, readingChanged, appirater, dataSource;

NSString * const APP_ABOUT = @"about";
NSString * const APP_TWITTER = @"twitter";
NSString * const APP_FACEBOOK = @"facebook";
NSString * const APP_NEW_UPDATE = @"new_update";

// Notification
NSString * const LWECardSettingsChanged = @"LWECardSettingsChanged";
NSString * const LWESettingsChanged = @"LWESettingsChanged";

#pragma mark -

- (id) init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (self)
  {
    self.tabBarItem.image = [UIImage imageNamed:@"20-gear2.png"];
    self.title = NSLocalizedString(@"Settings", @"SettingsViewController.NavBarTitle");
  }
  return self;
}

/** Customized to add support for observers/notifications */
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.sectionArray = [self.dataSource settingsArray];
  

  [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:LWESettingsChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateTableDataAfterPluginInstall:) name:LWEPluginDidInstall object:nil];
  // TODO: get rid of this
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_addPluginMenuItem) name:@"taskDidCompleteSuccessfully" object:nil];
}

/**
 * Makes the settings show the plugins when required (e.g. after the user updates their version to JFlash 1.1)
 */
- (void) _addPluginMenuItem
{
  self.navigationItem.rightBarButtonItem = nil;
  [self _updateTableDataAfterPluginInstall:nil];
}

/**
 * Called when plugin installed
 */
- (void) _updateTableDataAfterPluginInstall:(NSNotification *)notification
{
	LWE_LOG(@"Update table data after plugin install is called");
  self.sectionArray = [self.dataSource settingsArray];
  [self.tableView reloadData];
}


- (void)viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  UIBarButtonItem *rateUsBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Rate Us",@"SettingsViewController.RateUsButton") style:UIBarButtonItemStyleBordered target:self action:@selector(_launchAppirater)];
  self.navigationItem.leftBarButtonItem = rateUsBtn;
  [rateUsBtn release];
  
  //Added this in, so that it refreshes it self when the user is going to this Settings view, after the user changes something that is connected with the appearance of this Settings View Controller. 
  self.sectionArray = [self.dataSource settingsArray];
	
  self.tableView.backgroundColor = [UIColor clearColor];
  [self.tableView reloadData];
}

//! Only re-load the set if settings were changed, otherwise there is no need to do anything
- (void) viewWillDisappear: (BOOL)animated
{
  [super viewWillDisappear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  if (settingsChanged)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:LWESettingsChanged object:self];
  }
  if (directionChanged || themeChanged || readingChanged)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:LWECardSettingsChanged object:self];
  }
  
  // we've sent the notifications, so reset to unchanged
  directionChanged = NO;
  themeChanged = NO;
  readingChanged = NO;
  settingsChanged = NO;
}


//! launchAppirater - convenience method for appirater
- (void) _launchAppirater
{
  self.appirater = [[[Appirater alloc] init] autorelease];
  [self.appirater showPromptManually];
}


//! Makes "setting" move to its next state
- (void) iterateSetting: (NSString*) setting
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSDictionary *dict = [self.dataSource.settingsHash objectForKey:setting];
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
    NSEnumerator *tmpEnumerator = [dict keyEnumerator];
    nextValue = [tmpEnumerator nextObject];
  }
  [settings setValue:nextValue forKey:setting];
  return;
}


# pragma mark UI Table View Methods

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return [self.sectionArray count];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger i = [[[self.sectionArray objectAtIndex:section] objectAtIndex:0] count];
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
    int numInstalled = [[[[CurrentState sharedCurrentState] pluginMgr] downloadedPlugins] count];
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
    // TODO: iPad customization!
    if(key == APP_TWITTER)
      tmpView.image = [UIImage imageNamed:@"icon_twitter_30x30.png"];
    else
      tmpView.image = [UIImage imageNamed:@"icon_facebook_30x30.png"];
  }
  else if (key == APP_ALGORITHM)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_ALGORITHM onTable:tableView usingStyle:UITableViewCellStyleDefault];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  }
	else if (key == APP_NEW_UPDATE)
	{
		cell = [LWEUITableUtils reuseCellForIdentifier:APP_NEW_UPDATE onTable:tableView usingStyle:UITableViewCellStyleDefault];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	
	}
  else
  {
    // Anything else
    cell = [LWEUITableUtils reuseCellForIdentifier:key onTable:tableView usingStyle:UITableViewCellStyleValue1];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.text = [[self.dataSource.settingsHash objectForKey:key] objectForKey:[settings objectForKey:key]];        
  }
  
  cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
  cell.textLabel.numberOfLines = 0;
  cell.textLabel.text = displayName;
  return cell;  
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *thisSectionArray = [[self sectionArray] objectAtIndex:indexPath.section];
  NSString *key = [[thisSectionArray objectAtIndex:1] objectAtIndex:indexPath.row];

  CGFloat size;
  // Special case for about section
  if (key == APP_ABOUT)
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
  else if ((key == APP_PLUGIN)||(key == APP_NEW_UPDATE))
  {
		// TODO: iPad customization!
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
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reload",@"Global.Reload")
                                                            style:UIBarButtonItemStyleBordered target:webView action:@selector(reload)];
    webVC.navigationItem.rightBarButtonItem = bbi;
    [bbi release];

    NSURL *url = nil;
    if (key == APP_FACEBOOK)
    {
      url = [NSURL URLWithString:@"http://m.facebook.com/pages/Japanese-Flash/111141367918"];
    }
    else
    {
      url = [NSURL URLWithString:@"http://twitter.com/long_weekend/"];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
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
    [self.tableView reloadData];
    if (key == APP_HEADWORD) // we don't want the current card to change for just a headword switch
    {
      directionChanged = YES;
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

//! Turns off the network activity indicator & shows a "you are not connected" error
- (void) webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [LWEUIAlertView noNetworkAlertWithDelegate:self];
}

//! Turns off the network activity indicator
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void) viewDidUnload
{
	LWE_LOG(@"Settings View Controller get unload");
  [super viewDidUnload];
  [[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


# pragma mark - Housekeeping

- (void)dealloc
{
  [dataSource release];
  [sectionArray release];
  [appirater release];
  [super dealloc];
}

@end