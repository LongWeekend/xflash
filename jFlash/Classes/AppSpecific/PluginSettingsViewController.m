    //
//  PluginSettingsViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "PluginSettingsViewController.h"

#define PLUGIN_SETTINGS_INSTALLED_SECTION 0
#define PLUGIN_SETTINGS_AVAILABLE_SECTION 1

@implementation PluginSettingsViewController

@synthesize tableView, availablePlugins, installedPlugins;

//! UIView delegate - sets tint color et al of the nav bar
- (void)viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setBackgroundColor:[UIColor clearColor]];
}


//! UIView delegate - sets title & creates plugin arrays
- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setTitle:@"Plugins"];

  // Get plugin data
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  [self setInstalledPlugins:[pm loadedPlugins]];
  [self setAvailablePlugins:[pm availablePlugins]];
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
  UITableViewCell *cell = [LWEUITableUtils reuseCellForIdentifier:@"pluginsTable" onTable:lclTableView usingStyle:UITableViewCellStyleSubtitle];
  if (indexPath.section == PLUGIN_SETTINGS_INSTALLED_SECTION)
  {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.detailTextLabel.text = [[[self installedPlugins] objectAtIndex:indexPath.row] objectForKey:@"plugin_details"];
    cell.textLabel.text = [[[self installedPlugins] objectAtIndex:indexPath.row] objectForKey:@"plugin_name"];
  }
  else
  {
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
- (NSString *) tableView: (UITableView*) lclTableView titleForHeaderInSection:(NSInteger)section
{
  if (section == PLUGIN_SETTINGS_INSTALLED_SECTION)
  {
    return @"Installed Plugins";
  }
  else
  {
    return @"Available Plugins";
  }
}


- (void)dealloc
{
    [super dealloc];
}

@end