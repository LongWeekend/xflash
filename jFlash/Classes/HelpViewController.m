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
    self.title = @"Help";
    self.navigationItem.title = @"Help";
    
    NSArray *names = [NSArray arrayWithObjects:@"Welcome",@"Study Sets",@"Practice",@"Browse Mode",@"Word Search",@"Sharing",@"Feedback"];
    NSArray *htmls = [NSArray arrayWithObjects:@"welcome",@"studysets",@"practice",@"browse",@"search",@"share",@"feedback"];
    [self setSectionTitles:names];
    [self setHtmlFilenames:htmls];    
  }
	return self;
}


- (void)viewWillAppear: (BOOL)animated
{
  self.navigationController.navigationBar.tintColor = [CurrentState getThemeTintColor];
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
  
  cell = [LWE_Util_Table reuseCellForIdentifier:@"help" onTable:tableView usingStyle:UITableViewCellStyleDefault];
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



/*


// Quits the app opens in safari.app
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  if (
      // URL to launch itunes app store on phone
      [[[request URL] absoluteString] isEqual:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=367216357&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]
  || 
      // URL to get satisfaction page
      [[[request URL] absoluteString] isEqual:@"http://support.longweekendmobile.com/"]
  ||
      // URL to our twitter page
      [[[request URL] absoluteString] isEqual:@"http://twitter.com/long_weekend"] 
  )
  {
    // Open links in safari.app
    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
  }
  else 
  {
    return YES;
  }
}

*/

- (void)dealloc
{
  [self setSectionTitles:nil];
  [self setHtmlFilenames:nil];
  [super dealloc];
}

@end