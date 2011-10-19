    //
//  PluginSettingsViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "PluginSettingsViewController.h"
#import "Constants.h"

#define PLUGIN_SETTINGS_INSTALLED_SECTION 1
#define PLUGIN_SETTINGS_AVAILABLE_SECTION 0

// Private Methods
@interface PluginSettingsViewController()
- (void) _reloadTableData;
- (void)_changeLastUpdateLabel;
@end

@implementation PluginSettingsViewController

@synthesize tableView, availablePlugins, installedPlugins;
@synthesize btnCheckUpdate, lblLastUpdate;

#pragma mark - Check Update Now Button

/**
 * The button check for update will trigger this function, and checks for update
 * with the Plugin Manager. 
 *
 * However, the real method call for updating the available for update list
 * happens in the performCheckUpdateWithLoadingView. The reason is, this method
 * will show the loading screen, and call the other method with the perform
 * selector, with delay. So it allows the iOS to draw the loading screen, and
 * perform the task with the loading screen on top.
 */
- (IBAction) checkUpdatePlugin:(id)sender
{
	//Give the waiting loading screen. It looks a bit messy
	//but its for the sake of it blocks all of the view underneath, so it
	//avoids user clicks the other button while it still loading and
	//perform the checking for update. 
	LWELoadingView *lv = [LWELoadingView loadingView:self.parentViewController.parentViewController.view 
                                          withText:NSLocalizedString(@"Please Wait",@"PleaseWait")];
	
	[self performSelector:@selector(performCheckUpdateWithLoadingView:) withObject:lv afterDelay:0.1f];
}

/**
 * This method will perform the real check update method on the 
 * plugin manager.
 *
 */
- (void)performCheckUpdateWithLoadingView:(LWELoadingView *)lv
{
	PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
	
	[self _changeLastUpdateLabel];
  [pm checkNewPluginsAsynchronous:NO notifyOnNetworkFail:YES];
	[self _reloadTableData];
	
	[lv removeFromSuperview];
}

#pragma mark -

//! UIView delegate - sets tint color et al of the nav bar
- (void)viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.tableView.backgroundColor = [UIColor clearColor];
}


//! UIView delegate - sets title & creates plugin arrays
- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = NSLocalizedString(@"Get Updates",@"PluginSettingsViewController.NavBarTitle");
	
	_dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setDateStyle:NSDateFormatterLongStyle];

  [self _reloadTableData];
	[self _changeLastUpdateLabel];
  
  // Register a reload when they hide the modal
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_reloadTableData) name:@"taskDidCompleteSuccessfully" object:nil];
}

- (void) viewDidUnload
{
  [super viewDidUnload];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//! Helper method for notification
- (void) _reloadTableData
{
  // Refresh plugin data
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  self.installedPlugins = [pm downloadedPlugins];
  self.availablePlugins = [pm availablePlugins];
  [self.tableView reloadData];
}


# pragma mark UITableView delegate methods


//! Hardcoded to 2 - installed and available
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}


//! Return the number of plugins of each type
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == PLUGIN_SETTINGS_INSTALLED_SECTION)
  {
    return [[self installedPlugins] count];
  }
  else
  {
    // section == PLUGIN_SETTINGS_AVAILABLE_SECTION
    return [[self availablePlugins] count];
  }
}

//! Makes the table cells
- (UITableViewCell *)tableView: (UITableView *)lclTableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  if (indexPath.section == PLUGIN_SETTINGS_INSTALLED_SECTION)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"installed" onTable:lclTableView usingStyle:UITableViewCellStyleDefault];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.text = [[[self installedPlugins] objectAtIndex:indexPath.row] objectForKey:@"plugin_name"];
  }
  else
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"available" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
    cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];    
    cell.detailTextLabel.text = [[[self availablePlugins] objectAtIndex:indexPath.row] objectForKey:@"plugin_details"];
    cell.textLabel.text = [[[self availablePlugins] objectAtIndex:indexPath.row] objectForKey:@"plugin_name"];
  }

  return cell;  
}

//! what to do if selected
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == PLUGIN_SETTINGS_AVAILABLE_SECTION)
  {
    [lclTableView deselectRowAtIndexPath:indexPath animated:YES];

    // Fire off a notification to bring up the downloader
    NSDictionary *dict = [[self availablePlugins] objectAtIndex:indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldShowDownloaderModal" object:self userInfo:dict];
  }
}

//! Get the titles
- (NSString *)tableView: (UITableView*) lclTableView titleForHeaderInSection:(NSInteger)section
{
  if (section == PLUGIN_SETTINGS_INSTALLED_SECTION && [[self installedPlugins] count])
  {
    return NSLocalizedString(@"Installed",@"PluginSettingsViewController.TableHeader_Installed");
  }
  else if (section == PLUGIN_SETTINGS_AVAILABLE_SECTION && [[self availablePlugins] count])
  {
    return NSLocalizedString(@"Available (Tap to Download)",@"PluginSettingsViewController.TableHeader_Available");
  }
  else
  {
    return @"";
  }
}

- (void)dealloc
{
  [availablePlugins release];
  [installedPlugins release];
  [btnCheckUpdate release];
  [lblLastUpdate release];
  [_dateFormatter release];
	
  [super dealloc];
}

#pragma mark - Private methods

//! This is the handy method to retreive the last update date from the user setting, OR update it with the updated date and display it right away (Including the saving back to user setting process)
- (void)_changeLastUpdateLabel
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSString *str = nil;
	
	NSDate *date = [settings valueForKey:PLUGIN_LAST_UPDATE];
	if ([date isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]])
	{
		str = [[NSString alloc] initWithFormat:NSLocalizedString(@"Never",@"NeverUpdated")];
	}
	else 
	{
		str = [[NSString alloc] initWithFormat:@"%@", [_dateFormatter stringFromDate:date]];
	}
	
	if (str != nil)
	{
		self.lblLastUpdate.text = [NSString stringWithFormat:NSLocalizedString(@"Last update : %@",@"LastUpdate"), str];
		[str release];
	}
}

@end