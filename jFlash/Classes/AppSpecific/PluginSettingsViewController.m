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

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
  
  
  // Source plugin information from PluginManager
  
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  NSArray *pluginArray = [NSArray arrayWithObjects:[pm loadedPluginsByName],[pm loadedPluginsByKey],@"Installed Plugins",nil];  
  
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
    return 1;
  }
  else
  {
    // section == PLUGIN_SETTINGS_AVAILABLE_SECTION
    return 1;
  }
}

//! Makes the table cells
- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
  UITableViewCell *cell = [LWEUITableUtils reuseCellForIdentifier:@"pluginsTable" onTable:tableView usingStyle:UITableViewCellStyleValue1];
  if (indexPath.section == PLUGIN_SETTINGS_INSTALLED_SECTION)
  {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  }
  cell.detailTextLabel.text = @"Text about plugin";
  cell.textLabel.text = @"plugin name"; //displayName;
  return cell;  
}

//! what to do if selected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == PLUGIN_SETTINGS_AVAILABLE_SECTION)
  {
    LWE_LOG(@"INSTALL A PLUGIN");
  }
}

//! Get the titles
- (NSString *) tableView: (UITableView*) tableView titleForHeaderInSection:(NSInteger)section
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
