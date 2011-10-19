//
//  SettingsViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/17/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "SettingsViewController.h"
#import "PluginSettingsViewController.h"
#import "Appirater.h"
#import "AlgorithmSettingsViewController.h"
#import "ReminderSettingsViewController.h"
#import "UserViewController.h"
#import "UserPeer.h"

@interface SettingsViewController ()
-(void) _updateTableDataAfterPluginInstall:(NSNotification*)notification;
@end

@implementation SettingsViewController
@synthesize sectionArray, dataSource, delegate;

NSString * const APP_ABOUT = @"about";
NSString * const APP_TWITTER = @"twitter";
NSString * const APP_FACEBOOK = @"facebook";
NSString * const APP_NEW_UPDATE = @"new_update";

// Notification
NSString * const LWECardSettingsChanged = @"LWECardSettingsChanged";
NSString * const LWEUserSettingsChanged = @"LWESettingsChanged";

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

  [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:LWEUserSettingsChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateTableDataAfterPluginInstall:) name:LWEPluginDidInstall object:nil];
}

- (void) viewDidUnload
{
  [super viewDidUnload];
  [[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
  // TODO: iPad customization!
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
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
  
  BOOL shouldSendChangeNotification = NO;
  BOOL shouldSendCardChangeNotification = NO;
  if (self.delegate && [self.delegate respondsToSelector:(@selector(shouldSendChangeNotification))])
  {
    shouldSendChangeNotification = [self.delegate shouldSendChangeNotification];
  }
  if (self.delegate && [self.delegate respondsToSelector:(@selector(shouldSendCardChangeNotification))])
  {
    shouldSendCardChangeNotification = [self.delegate shouldSendCardChangeNotification];
  }
  
  // Note that this is an else-if because a "settings changed" will re-run everything, so there is no
  // reason to call both if you're calling the first.
  if (shouldSendChangeNotification)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:LWEUserSettingsChanged object:self];
  }
  else if (shouldSendCardChangeNotification)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:LWECardSettingsChanged object:self];
  }
  
  LWE_DELEGATE_CALL(@selector(settingsViewControllerWillDisappear:),self);
}


// TODO: this could be a block someday.
//! launchAppirater - convenience method for appirater
- (void) _launchAppirater
{
  Appirater *appirater = [[[Appirater alloc] init] autorelease];
  [appirater showPromptManually];
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


# pragma mark - UITableViewDataSource Methods

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return [self.sectionArray count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger i = [[[self.sectionArray objectAtIndex:section] objectAtIndex:0] count];
  return i;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  // Get our key name and display name
  NSArray *thisSectionArray = [self.sectionArray objectAtIndex:indexPath.section];
  NSString *key = [[thisSectionArray objectAtIndex:1] objectAtIndex:indexPath.row];
  NSString *displayName = [[thisSectionArray objectAtIndex:0] objectAtIndex:indexPath.row];
  
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
    NSInteger numInstalled = [[[[CurrentState sharedCurrentState] pluginMgr] downloadedPlugins] count];
    if (numInstalled > 0)
    {
      cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d installed",@"SettingsViewController.Plugins_NumInstalled"),numInstalled];
    }
    else
    {
      cell.detailTextLabel.text = NSLocalizedString(@"None",@"Global.None");
    }
  }
  else if (key == APP_REMINDER)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_REMINDER onTable:tableView usingStyle:UITableViewCellStyleValue1];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    UIImageView *tmpView = cell.imageView;
    // TODO: iPad customization!
    if (key == APP_TWITTER)
    {
      tmpView.image = [UIImage imageNamed:@"icon_twitter_30x30.png"];
    }
    else if (key == APP_FACEBOOK)
    {
      tmpView.image = [UIImage imageNamed:@"icon_facebook_30x30.png"];
    }
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

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *thisSectionArray = [self.sectionArray objectAtIndex:indexPath.section];
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
  else if (key == APP_PLUGIN || key == APP_NEW_UPDATE)
  {
		// TODO: iPad customization!
		PluginSettingsViewController *psvc = [[PluginSettingsViewController alloc] initWithNibName:@"PluginSettingsView" bundle:nil];
		[self.navigationController pushViewController:psvc animated:YES];
		[psvc release];
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
  else if (key == APP_ABOUT)
  {
    // Do nothing, about section
  }
  else if (key == APP_REMINDER)
  {
    ReminderSettingsViewController *tmpVC = [[ReminderSettingsViewController alloc] init];
    [self.navigationController pushViewController:tmpVC animated:YES];
    [tmpVC release];
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
    LWE_DELEGATE_CALL(@selector(settingWillChange:),key);
    [self iterateSetting:key];
    [self.tableView reloadData];
    
    // One special case, theme: reload the nav bar for this page
    if ([key isEqualToString:APP_THEME])
    {
      self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
    }
  }
}

- (NSString *) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  NSArray *thisSectionArray = [self.sectionArray objectAtIndex:section];
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

# pragma mark - Housekeeping

- (void)dealloc
{
  [dataSource release];
  [sectionArray release];
  [super dealloc];
}

@end