//
//  PluginSettingsViewController.h
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PluginManager.h"
#import "GradientButton.h"

@interface PluginSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSDateFormatter *_dateFormatter;
}

- (IBAction) checkUpdatePlugin:(id)sender;

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIButton *btnCheckUpdate;
@property (nonatomic, retain) IBOutlet UILabel *lblLastUpdate;
@property (retain) NSArray *availablePlugins;
@property (retain) NSArray *installedPlugins;
@property (retain) PluginManager *pluginManager;

@end