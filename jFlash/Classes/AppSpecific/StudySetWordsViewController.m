//
//  StudySetWordsViewController.m
//  jFlash
//
//  Created by Ross Sharrott on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "StudySetWordsViewController.h"
#import "AddTagViewController.h"

/**
 * Grouped UITableViewController subclass - shows all words in a given set
 * Some sets may be large, so this controller will not lock the interface
 * by loading all cards into memory at first.  It will load first and then
 * put the cards onto the screen when loaded.
 */
@implementation StudySetWordsViewController
@synthesize tag, cards, activityIndicator;


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
    if ([initTag isKindOfClass:[Tag class]] && [initTag tagId] >= 0)
    {
      [self setTag:initTag];
      [self performSelectorInBackground:@selector(loadWordListInBackground) withObject:nil];
    }
    self.navigationItem.title = [initTag tagName];
    [self setCards:nil];
    
    UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self setActivityIndicator:av];
    [av release];
  }
  return self;
}

- (void)viewDidLoad
{
  //TODO: If this is a current set list, register to a notification.
  Tag *currentTag = [[CurrentState sharedCurrentState] activeTag];
  if (currentTag.tagId == self.tag.tagId)
  {
    //Only register the notification if this StudySetWordsViewController is editing the active set.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_activeTagContentDidChange:) name:LWEActiveTagContentDidChange object:nil];
  }
  [super viewDidLoad];
}

- (void)_activeTagContentDidChange:(NSNotification *)notification
{
  id obj = [notification object];
  Card *card = nil;
  if ([obj isKindOfClass:[Card class]])
  {
    card = (Card *)obj;
  }
  
  //Check whether the existing local cache still have the card
  //This is to keep the list of cards synched if a card is removed from the AddTagViewController 
  //from the "Action" button in the "StudyViewController"
  NSUInteger index = [self.cards indexOfObject:card];
  if ((card != nil) && (index != NSNotFound))
  {
    //remove the card, reload the table
    [self.cards removeObjectAtIndex:index];
    [self.tableView reloadData];
  }
  
}


/** UIView delegate - sets theme info */
- (void) viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self tableView] setBackgroundColor: [UIColor clearColor]];
}

/** Run in background on init to load the word list */
- (void) loadWordListInBackground
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [self setCards:[CardPeer retrieveCardIdsForTagId:[tag tagId]]];
  [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
  [pool release];
}

#pragma mark - UITableView delegate methods

- (void)tableView:(UITableView *)lclTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *) indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    NSError *error = nil;
    Card *card = [[cards objectAtIndex:indexPath.row] retain];
    BOOL result = [TagPeer cancelMembership:card.cardId tagId:tag.tagId error:&error];
    if (!result)
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
      return;
    }
    
    [cards removeObjectAtIndex:indexPath.row];
    [lclTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationRight];
    
    // If the current study sets content
    // has been changed, notify the StudyViewController
    CurrentState *currentState = [CurrentState sharedCurrentState];
    if (self.tag.tagId == currentState.activeTag.tagId)
    {
      [[NSNotificationCenter defaultCenter] postNotificationName:LWEActiveTagContentDidChange object:card];
    }
    [card release];
  }
}


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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == kWordSetOptionsSection)
  {
    //We dont want user to remove the "Begin studying these" section.
    return NO;
  }
  return YES;
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
        tmpCard = [CardPeer hydrateCardByPK:tmpCard];
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
    AddTagViewController *tagController = [[AddTagViewController alloc] initWithCard:[[self cards] objectAtIndex:indexPath.row]];
    [tagController restrictMembershipChangeForTagId:self.tag.tagId];
    [self.navigationController pushViewController:tagController animated:YES];
    [tagController release];
  }
}

- (void)viewDidUnload
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewDidUnload];
}

//! Standard dealloc
- (void)dealloc
{
  [tag release]; 
  [cards release];
  [activityIndicator release];
  [super dealloc];
}

@end

