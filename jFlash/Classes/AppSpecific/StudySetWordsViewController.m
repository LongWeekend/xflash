//
//  StudySetWordsViewController.m
//  jFlash
//
//  Created by Ross Sharrott on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "StudySetWordsViewController.h"

@implementation StudySetWordsViewController
@synthesize tag, cards, activityIndicator;
// TODO: next version
// @synthesize queue, statusMsgBox;


- (id) initWithTag:(Tag*)initTag
{
  if (self = [super initWithStyle:UITableViewStyleGrouped])
  {
    [self setTag:initTag];
    self.navigationItem.title = [initTag tagName];
  }
  [self setCards:nil];
  [self setActivityIndicator:[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
  [self performSelectorInBackground:@selector(loadWordListInBackground) withObject:nil];
  return self;
}


- (void) viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
}

#pragma mark Table view methods

- (void) loadWordListInBackground
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [self setCards:[CardPeer retrieveCardIdsForTagId:[tag tagId]]];
  [self.tableView reloadData];
  [pool release];
}

- (void)tableView:(UITableView *)lclTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *) indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    [TagPeer cancelMembership:[[cards objectAtIndex:indexPath.row] cardId] tagId: tag.tagId];
    [cards removeObjectAtIndex:indexPath.row];
    [lclTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationRight];
  }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return wordsSectionsLength;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  int returnCount = 0;
  if (section == kWordSetListSections)
  {
    if ([self cards] == nil)
    {
      // Show loading
      returnCount = 1;
    }
    else
    {
      // Show cards & stop the animator
      [activityIndicator stopAnimating];
      returnCount = [cards count];
    }
  }
  else
  {
    // Show one top button
    returnCount = 1;
    // We are hiding publish button in first release
    //  else return 2;
  }
  return returnCount;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  static NSString *HeaderIdentifier = @"Header";
  UITableViewCell *cell;
  if (indexPath.section == kWordSetListSections)
  {
    if ([self cards] == nil)
    {
      cell = [LWEUITableUtils reuseCellForIdentifier:HeaderIdentifier onTable:tableView usingStyle:UITableViewCellStyleDefault];
      cell.textLabel.text = @"Loading words...";
      cell.accessoryView = activityIndicator;
      [activityIndicator startAnimating];
    }
    else
    {
      cell = [LWEUILabelUtils reuseCellForIdentifier:CellIdentifier onTable:tableView usingStyle:UITableViewCellStyleSubtitle];
      cell.selectionStyle = 0;
      Card* tmpCard = [[self cards] objectAtIndex:indexPath.row];
      if ([tmpCard headword] == nil)
      {
        tmpCard = [CardPeer hydrateCardByPK:tmpCard];
        [cards replaceObjectAtIndex:indexPath.row withObject:tmpCard];
      }
      cell.detailTextLabel.text = [tmpCard meaningWithoutMarkup];
      cell.textLabel.text = [tmpCard headword];
    }
  }
  else
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:HeaderIdentifier onTable:tableView usingStyle:UITableViewCellStyleDefault];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    if (indexPath.row == kWordSetOptionsStart)
    {
      cell.textLabel.text = @"Begin Studying These";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
// TODO: Disabled in this release
/*    else {
      cell.textLabel.text = @"Publish This Online";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
*/
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  if (indexPath.section == kWordSetOptionsSection)
  {
    if (indexPath.row == kWordSetOptionsStart)
    {
      // one final check to make sure they do not empty out the set prior to running it
      Tag *tmpTag = [TagPeer retrieveTagById:[[self tag] tagId]];
      if (tmpTag.cardCount > 0)
      {
        // Fire set change notification
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setWasChangedFromWordsList" object:self userInfo:[NSDictionary dictionaryWithObject:[self tag] forKey:@"tag"]];
      }
      [tmpTag release];
    }
    // TODO: implement this well later
    /* else if (indexPath.row == kWordSetOptionsPublish) {
      self.statusMsgBox = [[UIAlertView alloc] initWithTitle:@"Publish Your Set" message:@"This will upload your word set to the Long Weekend server.  You will need network access to do this.  Are you sure?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
      [statusMsgBox show];
    }
  */
  }
}

// DISABLED IN THIS RELEASE
/*

- (void) alertView: (UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  // This is the OK button for Publish
  if (buttonIndex == 1)
  {
    [self uploadThisSet];
  }
}

-(void) uploadThisSet
{
  // TODO: Give the user a progress bar
  // Check to make sure we have network connectivity
  if ([Util connectedToNetwork] == NO)
  {
    // Not connected to the net
    self.statusMsgBox = [[UIAlertView alloc] initWithTitle:@"No Network Detected" message:@"To upload your word set, please check that your iPhone has network connectivity and is not set to Airplane Mode." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
    [statusMsgBox show];
  }
  else {
    // Prepare the data
    NSString* csvData = [CardPeer retrieveCsvCardIdsForTag: tag.tagId];
    // Do the upload
    self.statusMsgBox = [[UIAlertView alloc] initWithTitle:@"Uploading..." message:@"Uploading data to the Long Weekend server.  Please wait a moment." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [statusMsgBox show];
    [self postDataToURL:csvData];
  }
  return;
}

- (void) postDataToURL:(NSString*)csvData
{
  if (![self queue])
  {
    [self setQueue:[[[NSOperationQueue alloc] init] autorelease]];
  }
  NSURL *url = [NSURL URLWithString:@"http://www.rossinjapan.com/jflash/submit.php5"];
  ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
  [request setDelegate:self];
  [request setDidFinishSelector:@selector(requestDone:)];
  [request setDidFailSelector:@selector(requestWentWrong:)];
  [request setPostValue:csvData forKey:@"csv"];
  [request setPostValue:tag.tagName forKey:@"tag"];
  [request setPostValue:[[UIDevice currentDevice] uniqueIdentifier] forKey:@"uuid"];
  [queue addOperation:request]; //queue is an NSOperationQueue
}

- (void)requestDone:(ASIHTTPRequest *)request
{
  [statusMsgBox dismissWithClickedButtonIndex:0 animated:NO];
  [statusMsgBox release];
  if ([request responseStatusCode] == 204)
  {
    // Successfully uploaded
    self.statusMsgBox = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Successfully transferred word list to the server." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
    [statusMsgBox show];
  }
  else {
    // No good
    self.statusMsgBox = [[UIAlertView alloc] initWithTitle:@"Transfer Error" message:@"There was an error transferring your word list to the server.  Please try again.  If this problem persists, please contact LWD." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
    [statusMsgBox show];
  }
}

- (void)requestWentWrong:(ASIHTTPRequest *)request
{
//  NSError *error = [request error];
  UIAlertView *baseAlert = [[UIAlertView alloc] initWithTitle:@"Transfer Error" message:@"There was an error transferring your word list to the server.  Please try again.  If this problem persists, please contact LWD." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
  [baseAlert show];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) return NO;
  else return YES;
}

*/


- (void)dealloc
{
  [tag release]; 
//  [queue release];
  [cards release];
  [activityIndicator release];
//  [statusMsgBox release];
  [super dealloc];
}

@end

