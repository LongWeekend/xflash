//
//  PluginSettingsViewController.h
//  jFlash
//
//  Created by Mark Makdad on 6/3/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PluginManager.h"
#import "SmallLoadingView.h"

@interface PluginSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
  IBOutlet UITableView* tableView;
  IBOutlet UILabel *lblLastUpdate;
  IBOutlet UIButton *btnCheckUpdate;
  NSArray *installedPlugins;
  NSArray *availablePlugins;
	
	NSDateFormatter *_dateFormatter;
}

- (void) reloadTableData;
- (IBAction) checkUpdatePluggin:(id)sender;

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UIButton *btnCheckUpdate;
@property (nonatomic, retain) IBOutlet UILabel *lblLastUpdate;
@property (nonatomic, retain) NSArray *availablePlugins;
@property (nonatomic, retain) NSArray *installedPlugins;

- (void)_changeLastUpdateLabel;

@end