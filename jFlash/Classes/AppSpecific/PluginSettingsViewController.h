//
//  PluginSettingsViewController.h
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PluginSettingsViewController : UITableViewController
{
  IBOutlet UITableView* tableView;
}

@property (nonatomic, retain) IBOutlet UITableView* tableView;

@end
