//
//  HelpViewController.m
//  jFlash
//
//  Created by シャロット ロス on 12/28/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "HelpViewController.h"
#import "HelpWebViewController.h"

/**
 * View controller for the user help.
 * Loads a web view controller w/ HTML data when a user
 * selects one of the  cells from the table on this view
 */
@implementation HelpViewController
@synthesize sectionTitles, htmlFilenames;

/**
 * Initializer - sets all of the titles and filenames of the help files.
 */
- (id) init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped]))
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"90-lifebuoy.png"];
    self.title = NSLocalizedString(@"Help",@"HelpViewController.NavBarTitle");
    self.navigationItem.title = NSLocalizedString(@"Help",@"HelpViewController.NavBarTitle");
    NSArray *names = [NSArray arrayWithObjects:NSLocalizedString(@"Welcome",@"HelpViewController.Table_Welcome"),
                                               NSLocalizedString(@"Study Sets",@"HelpViewController.Table_StudySets"),
                                               NSLocalizedString(@"Practice",@"HelpViewController.Table_Practice"),
                                               NSLocalizedString(@"Browse Mode",@"HelpViewController.Table_BrowseMode"),
                                               NSLocalizedString(@"Search",@"HelpViewController.Table_WordSearch"),
                                               NSLocalizedString(@"Corrections",@"HelpViewController.Table_Corrections"),
                                               NSLocalizedString(@"Learning Algorithm",@"HelpViewController.Table_LearningAlgorithm"),
                                               NSLocalizedString(@"Tag Glossary",@"HelpViewController.Table_TagGlossary"),
                                               NSLocalizedString(@"Sharing",@"HelpViewController.Table_Sharing"),
                                               NSLocalizedString(@"Feedback",@"HelpViewController.Table_Feedback"),nil];
    NSArray *htmls = [NSArray arrayWithObjects:@"welcome",@"studysets",@"practice",@"browse",@"search",@"corrections",@"algorithm",@"tags",@"share",@"feedback",nil];
    [self setSectionTitles:names];
    [self setHtmlFilenames:htmls];
    currentIndex = 0;
  }
	return self;
}

/** Changes the help view to the next page */
- (void) navigateToNextHelpPage
{
  NSInteger newIndex = currentIndex + 1;
  // Note that newIndex is a 0-based index, whereas count returns a 1-based count - so we use greater than, not equal
  if (newIndex < [[self htmlFilenames] count] && newIndex < [[self sectionTitles] count])
  {
    // This SHOULD be the HelpWebViewController - but you never know!
    UIViewController *tmpVC = [[self navigationController] topViewController];
    if ([tmpVC respondsToSelector:@selector(loadPageWithBundleFilename:usingTitle:)])
    {
      [tmpVC performSelector:@selector(loadPageWithBundleFilename:usingTitle:) withObject:[[self htmlFilenames] objectAtIndex:newIndex] withObject:[[self sectionTitles] objectAtIndex:newIndex]];
      currentIndex = newIndex;
      
      // Also figure out if we need to kill the next button if we have gone to the last page
      // Again note that the indices for these two ways of counting are off by 1
      if (currentIndex == ([[self sectionTitles] count]-1))
      {
        tmpVC.navigationItem.rightBarButtonItem = nil;
      }
    }
  }
}


/** Sets the nav bar tint to the current theme and sets the background to our standard */
- (void)viewWillAppear: (BOOL)animated
{
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
}

# pragma mark UITableView Delegate Methods

/** Hardcoded to 1 **/
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}


/** Returns the number of items in array sectionTitles */
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection:(NSInteger)section
{
  return [[self sectionTitles] count];
}


/**
 * Creates a cell with default style with an accessory disclosure indicator
 * The text of the cell is held in sectionTitles
 */
- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  cell = [LWEUITableUtils reuseCellForIdentifier:@"help" onTable:tableView usingStyle:UITableViewCellStyleDefault];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
  cell.textLabel.text = [[self sectionTitles] objectAtIndex:indexPath.row];
  return cell;  
}


/** Loads the HelpWebViewController with the selected row's HTML file */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  NSInteger row = indexPath.row;
  currentIndex = row;
  HelpWebViewController *webViewController = [[HelpWebViewController alloc] initWithFilename:[[self htmlFilenames] objectAtIndex:row] usingTitle:[[self sectionTitles] objectAtIndex:row]];
  // If there is a next, show the next button - note the array indices are different so we need a -1
  if (currentIndex < ([[self sectionTitles] count]-1))
  {
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next >",@"HelpViewController.Next") style:UIBarButtonItemStyleBordered target:self action:@selector(navigateToNextHelpPage)];
    webViewController.navigationItem.rightBarButtonItem = btn;
    [btn release];
  }
  [[self navigationController] pushViewController:webViewController animated:YES];
  [webViewController release];
}


# pragma mark -
# pragma mark Class Plumbing

//! Standard dealloc
- (void)dealloc
{
  [self setSectionTitles:nil];
  [self setHtmlFilenames:nil];
  [super dealloc];
}

@end