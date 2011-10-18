//
//  AddTagViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "AddTagViewController.h"

enum Sections
{
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

@interface AddTagViewController ()
- (void) _reloadTableData;
- (void) _removeFromMembershipCache:(NSInteger)tagId;
- (BOOL) _checkMembershipCacheForTagId:(NSInteger)tagId;
@property (retain) NSMutableArray *membershipCacheArray;
@end

@implementation AddTagViewController
@synthesize myTagArray,sysTagArray,membershipCacheArray,currentCard,studySetTable;

#pragma mark - Initializer

/**
 * Initializer - automatically loads AddTagView XIB file
 * attaches the Card parameter to the object
 * Also sets up nav bar properties
 */
- (id) initWithCard:(Card*)card
{
  // TODO: iPad customization!
  if ((self = [super initWithNibName:@"AddTagView" bundle:nil]))
  {
    self.currentCard = card;
    self.myTagArray = [TagPeer retrieveMyTagList];
    self.sysTagArray = [TagPeer retrieveSysTagListContainingCard:card];
    
    // set restricted Tag ID to something rediculous so it can't accidentally be a tag id.
    _restrictedTagId = INT_MAX;

    // Add "add" button to nav bar
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addStudySet)];
    self.navigationItem.rightBarButtonItem = addButton;
    [addButton release];

    // Set nav bar title
    self.navigationItem.title = NSLocalizedString(@"Add Word To Sets",@"AddTagViewController.NavBarTitle");

    // Register listener to reload data if modal added a set
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_reloadTableData) name:@"setAddedToView" object:nil];
  }
  return self;
}

#pragma mark - UIViewDelegate methods

/** Handles theming the nav bar, also caches the membershipCacheArray from TagPeer so we know what tags this card is a member of */
- (void)viewWillAppear:(BOOL)animated
{
  // View related stuff
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.studySetTable.backgroundColor = [UIColor clearColor];
  
  // Cache the tag's membership list
  self.membershipCacheArray = [[[TagPeer membershipListForCard:self.currentCard] mutableCopy] autorelease];
}

#pragma mark - Instance Methods

/** Target action for the Nav Bar "Add" button, launches AddStudySetInputViewController in a modal */
- (IBAction) addStudySet
{
  AddStudySetInputViewController *tmpVC = [[AddStudySetInputViewController alloc] initWithDefaultCard:self.currentCard groupOwnerId:0];
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:tmpVC];
	[tmpVC release];
  [self.navigationController presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
}

/**
 * If set, stops the user from changing membership for a given set.  Useful for restricting the
 * user against pulling the active card out of the active set, etc.
 */
- (void) restrictMembershipChangeForTagId:(NSInteger)tagId
{
  _restrictedTagId = tagId;
}


#pragma mark - Private Methods

//! Recreates tag membership caches and reloads table view
- (void) _reloadTableData
{
  self.myTagArray = [TagPeer retrieveMyTagList];
  self.membershipCacheArray = [[[TagPeer membershipListForCard:self.currentCard] mutableCopy] autorelease];
  [self.studySetTable reloadData];
}

/** Checks the membership cache to see if we are in - FYI similar methods are used by SearchViewController as well */
- (BOOL) _checkMembershipCacheForTagId:(NSInteger)tagId
{
  if ([self.membershipCacheArray count] > 0)
  {
    for (NSInteger i = 0; i < [self.membershipCacheArray count]; i++)
    {
      if ([[self.membershipCacheArray objectAtIndex:i] intValue] == tagId)
      {
        // Gotcha!
        return YES;
      }
    }
  }
  return NO;
}


//! Remove a tag from the membership cache
- (void) _removeFromMembershipCache:(NSInteger)tagId
{
  // Usually we don't want to mutate an array we are iterating, but in this case, we return immediately.
  if (self.membershipCacheArray && [self.membershipCacheArray count] > 0)
  {
    for (NSInteger i = 0; i < [self.membershipCacheArray count]; i++)
    {
      if ([[self.membershipCacheArray objectAtIndex:i] intValue] == tagId)
      {
        [self.membershipCacheArray removeObjectAtIndex:i];
        return;
      }
    }
  }
}

#pragma mark - UITableViewDelegate methods

//! Returns the total number of enum values in "Sections" enum
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger i = 0;
  if (section == kMyTagsSection)
  {
    i = [self.myTagArray count];
  }
  else if (section == kSystemTagsSection)
  {
    i = [self.sysTagArray count];  
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
  {
    return NSLocalizedString(@"My Sets",@"AddTagViewController.TableHeader_MySets");
  }
  else if (section == kSystemTagsSection)
  {
    return NSLocalizedString(@"Other Sets with this Card",@"AddTagViewController.TableHeader_AllSets");
  }
  else
  {
    return self.currentCard.headword;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
  if (indexPath.section == kEntrySection)
  {
    NSString *text = [NSString stringWithFormat:@"[%@]\n%@", [self.currentCard reading], [self.currentCard meaningWithoutMarkup]];
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
  if (indexPath.section == kEntrySection)
  {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.minimumFontSize = FONT_SIZE;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:FONT_SIZE];
    
    NSString *reading = nil;
#if defined(LWE_CFLASH)
    reading = [(ChineseCard *)currentCard pinyinReading];
#else
    reading = [self.currentCard reading];
#endif  
    label.text = [NSString stringWithFormat:@"[%@]\n%@", reading, [self.currentCard meaningWithoutMarkup]];
    label.frame = [LWEUILabelUtils makeFrameForText:label.text fontSize:FONT_SIZE cellWidth:LWE_UITABLE_CELL_CONTENT_WIDTH cellMargin:LWE_UITABLE_CELL_CONTENT_MARGIN];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.contentView addSubview:label];
    [label release];
  }
  // the cells for either tag type look the same
  else
  {        
    // Get the tag arrays
    Tag *tmpTag = nil;
    if (indexPath.section == kMyTagsSection)
    {
      tmpTag = [self.myTagArray objectAtIndex:indexPath.row];
      cell.selectionStyle = UITableViewCellSelectionStyleGray;
      if ([self _checkMembershipCacheForTagId:tmpTag.tagId])
      {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
      }
      else
      {
        cell.accessoryType = UITableViewCellAccessoryNone;
      }
    }
    else if (indexPath.section == kSystemTagsSection)
    {
      tmpTag = [self.sysTagArray objectAtIndex:indexPath.row];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // Set up the cell
    cell.textLabel.text = tmpTag.tagName;
  }
  
  return cell;
}

/**
 * Called when the user selects one of the table rows containing a tag name
 * Calls subscribe or cancel set membership accordingly, also checks 
 * _restrictedTagId to make sure it is allowed to remove/add the card to the set
 */
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  
  // do nothing for the entry section or system tags
  if (indexPath.section == kEntrySection || indexPath.section == kSystemTagsSection)
  {
    return;
  }

  CurrentState *currentState = [CurrentState sharedCurrentState];
  Tag *tmpTag = [self.myTagArray objectAtIndex:indexPath.row];

  // First, determine if we are restricted 
  // (set by the StudySetsWordsViewController if this is an active set)
  if (_restrictedTagId == tmpTag.tagId)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Apologies",@"AddTagViewController.Restricted_AlertViewTitle")
                                       message:NSLocalizedString(@"To remove this card from this set, navigate back to the previous screen.  Swipe from left to right on any entry to remove it.",@"AddTagViewController.Restricted_AlertViewMessage")];
    return;
  }
  
  // Check whether or not we are ADDING or REMOVING from the selected tag
  //TODO: Isnt it a local cache to check whether the card is a member of which tag? Cant we just use that? --Rendy 19/07/11
  if ([TagPeer card:self.currentCard isMemberOfTag:tmpTag])
  {
    // Remove tag
    NSError *error = nil;
    BOOL result = [TagPeer cancelMembership:self.currentCard fromTag:tmpTag error:&error];
    if (!result)
    {
      //something wrong, check whether it is the last card.
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

    //this section will only be run if the cancel membership operation is successful.
    [self _removeFromMembershipCache:tmpTag.tagId];
  }
  else
  {
    [TagPeer subscribeCard:self.currentCard toTag:tmpTag];
    [self.membershipCacheArray addObject:[NSNumber numberWithInt:tmpTag.tagId]];
    if (tmpTag.tagId == currentState.activeTag.tagId)
    {
      LWE_LOG(@"Editing current set tags");
      [currentState.activeTag addCardToActiveSet:self.currentCard]; // maybe fuck off?
    }
  }
  
  [lclTableView reloadData];
  
  // Tell study set controller to reload its set data stats
  [[NSNotificationCenter defaultCenter] postNotificationName:@"cardAddedToTag" object:self];
  
  // If the current study sets content
  // has been changed, notify the StudyViewController
  if (tmpTag.tagId == currentState.activeTag.tagId)
  {
    
    //this is a little bit strange, if this list is shown from the StudySetViewController workflow
    //it wont ever go here as the current set is set as "_restrictedTagId".
    //HOWEVER, if the user ARE in the current set and go here by tapping "Actions"->"Add To Study Set"
    //it will go here if the user tries to remove this card (obviously from the current set) =( --Rendy
    [[NSNotificationCenter defaultCenter] postNotificationName:LWEActiveTagContentDidChange object:self.currentCard];
  }
}


#pragma mark - Class plumbing

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