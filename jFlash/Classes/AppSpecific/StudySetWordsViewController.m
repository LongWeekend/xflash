//
//  StudySetWordsViewController.m
//  jFlash
//
//  Created by Ross Sharrott on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "StudySetWordsViewController.h"
#import "AddTagViewController.h"

@interface StudySetWordsViewController ()
- (void) _loadWordListInBackground;
- (void) _tagContentDidChange:(NSNotification*)notification;
@end

/**
 * Grouped UITableViewController subclass - shows all words in a given set
 * Some sets may be large, so this controller will not lock the interface
 * by loading all cards into memory at first.  It will load first and then
 * put the cards onto the screen when loaded.
 */
@implementation StudySetWordsViewController

@synthesize tag, cards, activityIndicator;

#pragma mark - Initializer

/**
 * Customized initializer taking a Tag as a single parameter
 * Sets the title of the nav bar to the tag name
 * Also kicks off loadWordListInBackground selector in.. background
 */ 
- (id) initWithTag:(Tag*)initTag
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (self)
  {
    if (initTag.tagId >= 0)
    {
      self.tag = initTag;
      [self performSelectorInBackground:@selector(_loadWordListInBackground) withObject:nil];
    }
    self.navigationItem.title = [initTag tagName];
    
    UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator = av;
    [av release];
  }
  return self;
}

#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Ideally, I could set the object: to self.tag, but there's no guarantee that the MEMORY ADDY of
  // the self.tag is the same as the memory address of the tag object sending the notification, even
  // if they have the same tagId ... sadface. (MMA - 18.10.2011) ... Or is this OK?  Think about it.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_tagContentDidChange:)
                                               name:LWETagContentDidChange
                                             object:nil];
}

/** UIView delegate - sets theme info */
- (void) viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)viewDidUnload
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewDidUnload];
}

#pragma mark - Private Methods

- (void) _tagContentDidChange:(NSNotification*)notification
{
  // First, quick return if this tagId isn't relevant to us.
  if ([self.tag isEqual:(Tag*)notification.object] == NO)
  {
    return;
  }
  
  // Next, make sure we have a card.
  Card *theCard = [notification.userInfo objectForKey:LWETagContentDidChangeCardKey];
  if (theCard == nil)
  {
    return;
  }
  
  // OK, now determine what type of update it is - if we don't know, do nothing
  NSString *changeType = [notification.userInfo objectForKey:LWETagContentDidChangeTypeKey];
  if ([changeType isEqualToString:LWETagContentCardAdded])
  {
    [self.cards addObject:theCard];
  }
  else if ([changeType isEqualToString:LWETagContentCardRemoved])
  {
    NSInteger index = [self.cards indexOfObject:theCard];
    if (index != NSNotFound)
    {
      //remove the card, reload the table
      [self.cards removeObjectAtIndex:index];
    }
  }
  
  // In any case, reload the table.
  [self.tableView reloadData];
}

/** Run in background on init to load the word list */
- (void) _loadWordListInBackground
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  self.cards = [[[CardPeer retrieveCardIdsForTagId:tag.tagId] mutableCopy] autorelease];
  [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
  [pool release];
}

#pragma mark - UITableViewDataSource Methods

/** Returns the number of enums in wordsSections enum */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return wordsSectionsLength;
}

/**
 * If we are in "header" section with "start this set" button, return 1
 * If we are in the cards section, return # cards, or 1 if still loading
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  int returnCount = 0;
  if (section == kWordSetListSections)
  {
    if ([self cards])
    {
      // Show cards & stop the animator
      [activityIndicator stopAnimating];
      returnCount = [cards count];
    }
    else
    {
      // No cards yet, show "loading" cell
      returnCount = 1;
    }
  }
  else
  {
    // Show one top button
    returnCount = 1;
  }
  return returnCount;
}

/** Customize the appearance of table view cells */
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
      cell.textLabel.text = NSLocalizedString(@"Loading words...",@"StudySetWordsViewController.LoadingWords");
      cell.accessoryView = activityIndicator;
      [activityIndicator startAnimating];
    }
    else
    {
      cell = [LWEUITableUtils reuseCellForIdentifier:CellIdentifier onTable:tableView usingStyle:UITableViewCellStyleSubtitle];
      cell.selectionStyle = 0;
      Card* tmpCard = [[self cards] objectAtIndex:indexPath.row];
      if ([tmpCard headword] == nil)
      {
        tmpCard = [CardPeer retrieveCardByPK:tmpCard.cardId];
        [cards replaceObjectAtIndex:indexPath.row withObject:tmpCard];
      }
      cell.detailTextLabel.text = [tmpCard meaningWithoutMarkup];
      cell.textLabel.text = [tmpCard headword];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
  else
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:HeaderIdentifier onTable:tableView usingStyle:UITableViewCellStyleDefault];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    if (indexPath.row == kWordSetOptionsStart)
    {
      cell.textLabel.text = NSLocalizedString(@"Begin Studying These",@"StudySetWordsViewController.BeginStudyingThese");
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
  return cell;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)lclTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *) indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    NSError *error = nil;
    Card *card = [self.cards objectAtIndex:indexPath.row];
    BOOL result = [TagPeer cancelMembership:card fromTag:self.tag error:&error];
    if (result)
    {
      [self.cards removeObjectAtIndex:indexPath.row];
      [lclTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationRight];
    }
    else
    {
      if ([error code] == kRemoveLastCardOnATagError)
      {
        NSString *errorMessage = [error localizedDescription];
        [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Last Card in Set", @"AddTagViewController.AlertViewLastCardTitle")
                                           message:errorMessage];
      }
      else
      {
        LWE_LOG_ERROR(@"[UNKNOWN ERROR]%@", error);
      }
    } // else error
  } // editing style is delete
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == kWordSetOptionsSection)
  {
    //We dont want user to remove the "Begin studying these" section.
    return NO;
  }
  return YES;
}


/** If the user selected the "header" row, start the set.  If the user selected a card, push an AddTagViewController at them. */
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
      else
      {
        [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"No Words In Set",@"StudySetViewController.NoWords_AlertViewTitle")
                                           message:NSLocalizedString(@"To add words to this set, you can use Search.",@"StudySetViewController.NoWords_AlertViewMessage")];
      }
    }
  }
  // If they pressed a card, show the add to set list
  else if (indexPath.section == kWordSetListSections)
  {
    AddTagViewController *tmpVC = [[AddTagViewController alloc] initWithCard:[self.cards objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:tmpVC animated:YES];
    [tmpVC release];
  }
}

#pragma mark - Class Plumbing

//! Standard dealloc
- (void)dealloc
{
  [tag release]; 
  [cards release];
  [activityIndicator release];
  [super dealloc];
}

@end

