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

#import "ChineseSettingsDataSource.h"
#import "JapaneseSettingsDataSource.h"

@implementation SettingsViewController
@synthesize sectionArray, dataSource;
@synthesize downloadManager, pluginManager;

NSString * const APP_ABOUT = @"about";
NSString * const APP_TWITTER = @"twitter";
NSString * const APP_FACEBOOK = @"facebook";
NSString * const APP_NEW_UPDATE = @"new_update";

#pragma mark -

/**
 * Some might say this shouldn't be here.  Then again, this code will change once per xFlash, so I think it 
 * makes sense to keep it with the settings.  Though, it does have knowledge of its own delegate, at least
 * on its constructor.
 */
- (void) awakeFromNib
{
#if defined(LWE_JFLASH)
  self.dataSource = [[[JapaneseSettingsDataSource alloc] init] autorelease];
#elif defined(LWE_CFLASH)
  self.dataSource = [[[ChineseSettingsDataSource alloc] init] autorelease];
#endif
  
  // Update the badge value now that the outlet to the plugin manager is set
  [self updateBadgeValue];

  // Add an observer on the plugin manager so we can update the available for download badge
  [self.pluginManager addObserver:self forKeyPath:@"downloadablePlugins" options:NSKeyValueObservingOptionNew context:NULL];
}

/** Customized to add support for observers/notifications */
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.sectionArray = [self.dataSource settingsArrayWithPluginManager:self.pluginManager];

  self.tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:LWETableBackgroundImage]] autorelease];

  UIBarButtonItem *rateUsBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Rate Us",@"SettingsViewController.RateUsButton") style:UIBarButtonItemStyleBordered target:self action:@selector(_launchAppirater)];
  self.navigationItem.leftBarButtonItem = rateUsBtn;
  [rateUsBtn release];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  //Added this in, so that it refreshes it self when the user is going to this Settings view,
  // after the user changes something that is connected with the appearance of this VC
  // (e.g. after they change users, et al)
  self.sectionArray = [self.dataSource settingsArrayWithPluginManager:self.pluginManager];
  [self.tableView reloadData];
}

#pragma mark - Badge

- (void) updateBadgeValue
{
  NSInteger pluginCount = [self.pluginManager.downloadablePlugins count];
  if (pluginCount > 0)
  {
    self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",pluginCount];
  }
  else
  {
    self.navigationController.tabBarItem.badgeValue = nil;
  }
}


#pragma mark - KVO

//! Monitor the plugin situation and update ourselves accordingly
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"downloadablePlugins"] && [object isKindOfClass:[PluginManager class]])
  {
    // First, update the badge value if necessary
    [self updateBadgeValue];
    
    // Second, reload the table -- chances are something changed that on the plugin row
    self.sectionArray = [self.dataSource settingsArrayWithPluginManager:self.pluginManager];
    [self.tableView reloadData];
  }
}

#pragma mark - Private Methods

// TODO: this could be a block someday.
//! launchAppirater - convenience method for appirater
- (void) _launchAppirater
{
  Appirater *appirater = [[Appirater alloc] init]; // appirater releases itself, do not autorelease here.
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
  return [[[self.sectionArray objectAtIndex:section] objectAtIndex:0] count];
}

- (UITableViewCell *)tableView:(UITableView *)lclTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_USER onTable:lclTableView usingStyle:UITableViewCellStyleValue1];
    cell.detailTextLabel.text = [[UserPeer getUserByPK:[settings integerForKey:APP_USER]] userNickname];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  else if (key == APP_PLUGIN)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_PLUGIN onTable:lclTableView usingStyle:UITableViewCellStyleValue1];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSInteger numInstalled = [self.pluginManager.loadedPlugins count];
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
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_REMINDER onTable:lclTableView usingStyle:UITableViewCellStyleValue1];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSNumber *reminderSetting = [settings objectForKey:APP_REMINDER];
    if ([reminderSetting intValue] > 0)
    {
      cell.detailTextLabel.text = NSLocalizedString(@"On",@"Global.On");
    }
    else
    {
      cell.detailTextLabel.text = NSLocalizedString(@"Off",@"Global.Off");
    }
  }
  else if (key == APP_ABOUT)
  {
    // About section
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_ABOUT onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  else if (key == APP_FACEBOOK || key == APP_TWITTER)
  {
    // Set up the image
    cell = [LWEUITableUtils reuseCellForIdentifier:@"social" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
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
    cell = [LWEUITableUtils reuseCellForIdentifier:APP_ALGORITHM onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  }
	else if (key == APP_NEW_UPDATE)
	{
		cell = [LWEUITableUtils reuseCellForIdentifier:APP_NEW_UPDATE onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	
	}
  else
  {
    // Anything else
    cell = [LWEUITableUtils reuseCellForIdentifier:key onTable:lclTableView usingStyle:UITableViewCellStyleValue1];
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
    size = [self.dataSource sizeForAcknowledgementsRow];
  }
  else
  {
    size = 44.0f;    
  }
  return size;
}


//! Make selection for a table cell
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  
  NSInteger section = indexPath.section;
  NSInteger row = indexPath.row;

  NSArray *thisSectionArray = [self.sectionArray objectAtIndex:section];
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
    psvc.pluginManager = self.pluginManager;
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
#if defined (LWE_JFLASH)
      // JFlash is the only app with its own FB page
      url = [NSURL URLWithString:@"http://m.facebook.com/pages/Japanese-Flash/111141367918"];
#else
      url = [NSURL URLWithString:@"http://www.facebook.com/pages/Long-Weekend/174666231385"];
#endif
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
    ReminderSettingsViewController *tmpVC = [[ReminderSettingsViewController alloc] initWithNibName:@"ReminderSettingsViewController" bundle:nil];
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
    [self iterateSetting:key];
    [lclTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationNone];
    
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
  [self.pluginManager removeObserver:self forKeyPath:@"downloadablePlugins"];
  [pluginManager release];

  [downloadManager release];
  [dataSource release];
  [sectionArray release];
  [super dealloc];
}

@end