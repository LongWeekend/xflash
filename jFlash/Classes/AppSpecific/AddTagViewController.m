//
//  AddTagViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "AddTagViewController.h"
#import "AddStudySetInputViewController.h"
#import "TagPeer.h"
#import "ChineseCard.h"

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

// Private methods & properties
@interface AddTagViewController ()
- (void) _reloadTableData;
- (void) _removeTagFromMembershipCache:(NSInteger)tagId;
- (BOOL) _tagExistsInMembershipCache:(NSInteger)tagId;
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

#pragma mark - Private Methods

//! Recreates tag membership caches and reloads table view
- (void) _reloadTableData
{
  self.myTagArray = [TagPeer retrieveMyTagList];
  self.membershipCacheArray = [[[TagPeer membershipListForCard:self.currentCard] mutableCopy] autorelease];
  [self.studySetTable reloadData];
}

/** Checks the membership cache to see if we are in - FYI similar methods are used by SearchViewController as well */
- (BOOL) _tagExistsInMembershipCache:(NSInteger)tagId
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
- (void) _removeTagFromMembershipCache:(NSInteger)tagId
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

- (void) _toggleMembershipForTag:(Tag *)tmpTag
{
  // Check whether or not we are ADDING or REMOVING from the selected tag
  if ([self _tagExistsInMembershipCache:tmpTag.tagId])
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
    [self _removeTagFromMembershipCache:tmpTag.tagId];
  }
  else
  {
    [TagPeer subscribeCard:self.currentCard toTag:tmpTag];
    [self.membershipCacheArray addObject:[NSNumber numberWithInt:tmpTag.tagId]];
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
    label.minimumFontSize = FONT_SIZE_ADD_TAG_VC;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:FONT_SIZE_ADD_TAG_VC];
    
    NSString *reading = nil;
#if defined(LWE_CFLASH)
    reading = [(ChineseCard *)currentCard pinyinReading];
#else
    reading = [self.currentCard reading];
#endif  
    label.text = [NSString stringWithFormat:@"[%@]\n%@", reading, [self.currentCard meaningWithoutMarkup]];
    label.frame = [LWEUILabelUtils makeFrameForText:label.text
                                           fontSize:FONT_SIZE_ADD_TAG_VC
                                          cellWidth:LWE_UITABLE_CELL_CONTENT_WIDTH
                                         cellMargin:LWE_UITABLE_CELL_CONTENT_MARGIN];
    
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
      if ([self _tagExistsInMembershipCache:tmpTag.tagId])
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
 * Calls subscribe or cancel set membership accordingly
 */
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  
  // do nothing for the entry section or system tags
  if (indexPath.section == kEntrySection || indexPath.section == kSystemTagsSection)
  {
    return;
  }

  Tag *tmpTag = [self.myTagArray objectAtIndex:indexPath.row];
  [self _toggleMembershipForTag:tmpTag];
  [lclTableView reloadData];
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