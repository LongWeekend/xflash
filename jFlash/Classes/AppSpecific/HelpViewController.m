//
//  HelpViewController.m
//  jFlash
//
//  Created by シャロット ロス on 12/28/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "HelpViewController.h"
#import "HelpWebViewController.h"

@implementation HelpViewController
@synthesize sectionTitles, htmlFilenames;

- (HelpViewController*) init
{
	if (self = [super initWithStyle:UITableViewStyleGrouped])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"90-lifebuoy.png"];
    self.title = NSLocalizedString(@"Help",@"HelpViewController.NavBarTitle");
    self.navigationItem.title = NSLocalizedString(@"Help",@"HelpViewController.NavBarTitle");
    
    NSArray *names = [NSArray arrayWithObjects:NSLocalizedString(@"Welcome",@"HelpViewController.Table_Welcome"),
                                               NSLocalizedString(@"Study Sets",@"HelpViewController.Table_StudySets"),
                                               NSLocalizedString(@"Practice",@"HelpViewController.Table_Practice"),
                                               NSLocalizedString(@"Browse Mode",@"HelpViewController.Table_BrowseMode"),
                                               NSLocalizedString(@"Word Search",@"HelpViewController.Table_WordSearch"),
                                               NSLocalizedString(@"Sharing",@"HelpViewController.Table_Sharing"),
                                               NSLocalizedString(@"Feedback",@"HelpViewController.Table_Feedback"),nil];
    NSArray *htmls = [NSArray arrayWithObjects:@"welcome",@"studysets",@"practice",@"browse",@"search",@"share",@"feedback",nil];
    [self setSectionTitles:names];
    [self setHtmlFilenames:htmls];    
  }
	return self;
}

- (void)viewWillAppear: (BOOL)animated
{
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
}

# pragma mark UI Table View Methods

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger i = [[self sectionTitles] count];
  return i;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  NSInteger row = [indexPath row];
  
  cell = [LWEUITableUtils reuseCellForIdentifier:@"help" onTable:tableView usingStyle:UITableViewCellStyleDefault];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.text = [[self sectionTitles] objectAtIndex:row];
  return cell;  
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger row = indexPath.row;
  HelpWebViewController *webViewController = [[HelpWebViewController alloc] initWithFilename:[[self htmlFilenames] objectAtIndex:row] usingTitle:[[self sectionTitles] objectAtIndex:row]];
  [[self navigationController] pushViewController:webViewController animated:YES];
  [tableView deselectRowAtIndexPath:indexPath animated:NO];  
}


- (void)dealloc
{
  [self setSectionTitles:nil];
  [self setHtmlFilenames:nil];
  [super dealloc];
}

@end