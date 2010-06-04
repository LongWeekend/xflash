//
//  PluginSettingsViewController.h
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PluginManager.h"

@interface PluginSettingsViewController : UITableViewController
{
  IBOutlet UITableView* tableView;
  NSArray *installedPlugins;
  NSArray *availablePlugins;
}

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) NSArray *availablePlugins;
@property (nonatomic, retain) NSArray *installedPlugins;

@end