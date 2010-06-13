//
//  AddTagViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "AddTagViewController.h"

enum Sections {
  kEntrySection = 0,
  kMyTagsSection = 1,
  kSystemTagsSection = 2,
  NUM_SECTIONS
};

enum EntrySectionRows
{
  kEntrySectionInfoRow = 0,
  NUM_HEADER_SECTION_ROWS
};

@implementation AddTagViewController
@synthesize cardId,myTagArray,sysTagArray,membershipCacheArray,currentCard,studySetTable;


/**
 * Initializer - automatically loads AddTagView XIB file
 * attaches the Card parameter to the object
 * Also sets up nav bar properties
 */
- (id) initWithCard:(Card*) card
{
  if (self = [super initWithNibName:@"AddTagView" bundle:nil])
  {
    [self setCardId:[card cardId]];
    [self setCurrentCard:card];
    [self setMyTagArray:[TagPeer retrieveMyTagList]];
    [self setSysTagArray:[TagPeer retrieveSysTagList]];

    // Add "add" button to nav bar
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addStudySet)];
    self.navigationItem.rightBarButtonItem = addButton;
    [addButton release];

    // Set nav bar title
    self.navigationItem.title = NSLocalizedString(@"Add Word To Sets",@"AddTagViewController.NavBarTitle");

    // Register listener to reload data if modal added a set
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"setAddedToView" object:nil];
  }
  return self;
}

#pragma mark -
#pragma mark UIViewDelegate methods

/** Handles theming the nav bar, also caches the membershipCacheArray from TagPeer so we know what tags this card is a member of */
- (void)viewWillAppear:(BOOL)animated
{
  // View related stuff
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  [[self studySetTable] setBackgroundColor: [UIColor clearColor]];
  
  // Cache the tag's membership list
  self.membershipCacheArray = [TagPeer membershipListForCardId:cardId];
}

#pragma mark -
#pragma mark Class Methods

/** Target action for the Nav Bar "Add" button, launches AddStudySetInputViewController in a modal */
- (void)addStudySet
{
  AddStudySetInputViewController* addStudySetInputViewController = [[AddStudySetInputViewController alloc] initWithDefaultCardId:[self cardId] groupOwnerId:0];
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:addStudySetInputViewController];
	[addStudySetInputViewController release];
  [[self navigationController] presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
}


/** Recreates tag membership caches and reloads table view */
- (void) reloadTableData
{
  [self setMyTagArray:[TagPeer retrieveMyTagList]];
  [self setMembershipCacheArray:[TagPeer membershipListForCardId:[self cardId]]];
  [[self studySetTable] reloadData];
}


/**
 * If set, stops the user from changing membership for a given set.  Useful for restricting the
 * user against pulling the active card out of the active set, etc.
 */
- (void) restrictMembershipChangeForTagId:(NSInteger) tagId
{
  _restrictedTagId = tagId;
}


/** Checks the membership cache to see if we are in */
- (BOOL) checkMembershipCacheForTagId: (NSInteger)tagId
{
  BOOL returnVal = NO;
  if (self.membershipCacheArray && [self.membershipCacheArray count] > 0)
  {
    for (int i = 0; i < [membershipCacheArray count]; i++)
    {
      if ([[membershipCacheArray objectAtIndex:i] intValue] == tagId)
      {
        // Gotcha!
        return YES;
      }
    }
  }
  else
  {
    // Rebuild cache and fail over to manual function
    self.membershipCacheArray = [TagPeer membershipListForCardId:self.cardId];
    returnVal = [TagPeer checkMembership:self.cardId tagId:tagId];
  }
  return returnVal;
}


/** Remove a card from the membership cache */
- (void) removeFromMembershipCache: (NSInteger) tagId
{
  if (self.membershipCacheArray && [self.membershipCacheArray count] > 0)
  {
    for (int i = 0; i < [membershipCacheArray count]; i++)
    {
      if ([[membershipCacheArray objectAtIndex:i] intValue] == tagId)
      {
        [membershipCacheArray removeObjectAtIndex:i];
        return;
      }
    }
  }
}

#pragma mark -
#pragma mark UITableViewDelegate methods

//! Returns the total number of enum values in "Sections" enum
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSUInteger i;
  if (section == kMyTagsSection)
  {
    i = [myTagArray count];
  }
  else if (section == kSystemTagsSection)
  {
    i = [sysTagArray count];  
  }
  else if (section == kEntrySection)
  {
    i = NUM_HEADER_SECTION_ROWS;
  }
  return i;
}

-(NSString*) tableView: (UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == kMyTagsSection)
    return NSLocalizedString(@"My Sets",@"AddTagViewController.TableHeader_MySets");
  else if (section == kSystemTagsSection)
    return NSLocalizedString(@"All Sets",@"AddTagViewController.TableHeader_AllSets");
  else
    return currentCard.headword;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
  if (indexPath.section == kEntrySection)
  {
    NSString* text = [NSString stringWithFormat:@"[%@]\n%@", [currentCard combinedReadingForSettings], [currentCard meaningWithoutMarkup]];
    return [LWEUITableUtils autosizeHeightForCellWithText:text];
  }
  else 
  {
    return 44.0f;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  if(indexPath.section == kEntrySection)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"entry" onTable:tableView usingStyle:UITableViewCellStyleDefault];
  }
  else 
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"cell" onTable:tableView usingStyle:UITableViewCellStyleDefault];
  } 

  // setup the cell for the full entry
  if(indexPath.section == kEntrySection)
  {
    NSString* text = [NSString stringWithFormat:@"[%@]\n%@", [currentCard combinedReadingForSettings], [currentCard meaningWithoutMarkup]];
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
    [label setLineBreakMode:UILineBreakModeWordWrap];
    [label setMinimumFontSize:FONT_SIZE];
    [label setNumberOfLines:0];
    [label setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [label setText:text];

    CGRect rect = [LWEUILabelUtils makeFrameForText:text fontSize:FONT_SIZE cellWidth:LWE_UITABLE_CELL_CONTENT_WIDTH cellMargin:LWE_UITABLE_CELL_CONTENT_MARGIN];
    [label setFrame:rect];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [[cell contentView] addSubview:label];
    [label release];
  }
  // the cells for either tag type look the same
  else
  {        
    // Get the tag arrays
    Tag* tmpTag;
    if (indexPath.section == kMyTagsSection)
      tmpTag = [myTagArray objectAtIndex:indexPath.row];
    else if (indexPath.section == kSystemTagsSection)
      tmpTag = [sysTagArray objectAtIndex:indexPath.row];
    
    // Set up the cell
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.textLabel.text = [tmpTag tagName];
    
    if ([self checkMembershipCacheForTagId:tmpTag.tagId])
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
      cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

/**
 * Called when the user selects one of the table rows containing a tag name
 * Calls subscribe or cancel set membership accordingly, also checks 
 * _restrictedTagId to make sure it is allowed to remove/add the card to the set
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(indexPath.section == kEntrySection) return; // do nothing for the entry section
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  Tag* tmpTag;
  if (indexPath.section == kMyTagsSection)
  {
    tmpTag = [myTagArray objectAtIndex:indexPath.row];
  }
  else
  {
    tmpTag = [sysTagArray objectAtIndex:indexPath.row];
  }

  // First, determine if we are restricted
  if (_restrictedTagId == tmpTag.tagId)
  {
    UIAlertView *msgBox = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Apologies",@"AddTagViewController.Restricted_AlertViewTitle")
                                               message:NSLocalizedString(@"To remove this card from this set, navigate back to the previous screen.  Swipe from left to right on any entry to remove it.",@"AddTagViewController.Restricted_AlertViewMessage")
                                               delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK",@"Global.OK"),nil];
    [msgBox show];
    [msgBox release];
    return;
  }
  
  // Check whether or not we are ADDING or REMOVING from the selected tag
  if ([TagPeer checkMembership:cardId tagId:tmpTag.tagId])
  {
    // We have special things to check if we are modifying the existing active set
    if (tmpTag.tagId == [[appSettings activeTag] tagId])
    {
      LWE_LOG(@"Editing current set tags");
      // Is it the last tag in this set?
      int tmpInt = [[appSettings activeTag] cardCount];
      LWE_LOG(@"Num cards: %d",tmpInt);
      if (tmpInt <= 1)
      {
        LWE_LOG(@"Last card in set");
        UIAlertView* statusMsgBox = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Last Card in Set",@"AddTagViewController.AlertViewLastCardTitle")
                                                         message:NSLocalizedString(@"This set only contains the card you are currently studying.  To delete a set entirely, please change to a different set first.",@"AddTagViewController.AlertViewLastCardMessage")
                                                         delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK",@"Global.OK"),nil];
        [statusMsgBox show];
        [statusMsgBox release];
        return;
      }
      // Success - but update counts
      [[appSettings activeTag] removeCardFromActiveSet:currentCard];
    }
    // Remove tag
    [TagPeer cancelMembership:cardId tagId:tmpTag.tagId];
    [self removeFromMembershipCache:tmpTag.tagId];
  }
  else
  {
    if (tmpTag.tagId == [[appSettings activeTag] tagId])
    {
      LWE_LOG(@"Editing current set tags");
      [[appSettings activeTag] addCardToActiveSet:currentCard];
    }
    [TagPeer subscribe:cardId tagId:tmpTag.tagId];
    [self.membershipCacheArray addObject:[NSNumber numberWithInt:tmpTag.tagId]];
  }
  [tableView reloadData];
  // Tell study set controller to reload its set data stats
  [[NSNotificationCenter defaultCenter] postNotificationName:@"cardAddedToTag" object:self];
}


#pragma mark -
#pragma mark Class plumbing

//! Standard dealloc
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [myTagArray release];
  [sysTagArray release];
  [currentCard release];
  [membershipCacheArray release];
  [super dealloc];
}


@end