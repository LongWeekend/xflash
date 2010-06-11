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
 */
- (id) initWithCard:(Card*) card
{
  if (self = [super initWithNibName:@"AddTagView" bundle:nil])
  {
    self.cardId = [card cardId];
    self.currentCard = card;
  }
  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  [self setMyTagArray:[TagPeer retrieveMyTagList]];
  [self setSysTagArray:[TagPeer retrieveSysTagList]];
 
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addStudySet)];
  self.navigationItem.rightBarButtonItem = addButton;
  self.navigationItem.title = NSLocalizedString(@"Add Word To Sets",@"AddTagViewController.NavBarTitle");
  [addButton release];
  // Register listener to reload data if modal added a set
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:@"setAddedToView" object:nil];
}


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


//! Returns the total number of enum values in "Sections" enum
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return NUM_SECTIONS;
}


/** Target action for the Nav Bar "Add" button, launches AddStudySetInputViewController in a modal */
- (void)addStudySet
{
  AddStudySetInputViewController* addStudySetInputViewController = [[AddStudySetInputViewController alloc] initWithDefaultCardId:[self cardId] groupOwnerId:0];
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:addStudySetInputViewController];
	[addStudySetInputViewController release];
  [[self navigationController] presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
}


- (void) reloadTableData
{
  [self setMyTagArray:[TagPeer retrieveMyTagList]];
  [self setMembershipCacheArray:[TagPeer membershipListForCardId:[self cardId]]];
  [[self studySetTable] reloadData];
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
  {
    return NSLocalizedString(@"My Sets",@"AddTagViewController.TableHeader_MySets");
  }
  else if(section == kSystemTagsSection)
  {
    return NSLocalizedString(@"All Sets",@"AddTagViewController.TableHeader_AllSets");
  }
  else
  {
    return currentCard.headword;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
  if(indexPath.section == kEntrySection)
  {
    NSString* text = [NSString stringWithFormat:@"[%@]\n%@", [self getReadingString], [currentCard meaningWithoutMarkup]];
    CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), 20000.0f);
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
    CGFloat height = size.height;

    return height + (CELL_CONTENT_MARGIN * 2);
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
    NSString* text = [NSString stringWithFormat:@"[%@]\n%@", [self getReadingString], [currentCard meaningWithoutMarkup]];
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
    [label setLineBreakMode:UILineBreakModeWordWrap];
    [label setMinimumFontSize:FONT_SIZE];
    [label setNumberOfLines:0];
    [label setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [label setText:text];
    CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), 20000.0f);
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
    [label setFrame:CGRectMake(CELL_CONTENT_MARGIN, CELL_CONTENT_MARGIN, CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), MAX(size.height, 44.0f))];
    
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

// Subscribe or cancel membership!
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
  // Check whether or not we are ADDING or REMOVING from the selected tag
  if ([TagPeer checkMembership:cardId tagId:tmpTag.tagId])
  {
    BOOL remove = YES;
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
        remove = NO;
      }
      // Success - but update counts
      if (remove) [[appSettings activeTag] removeCardFromActiveSet:currentCard];
    }
    // Remove tag
    if (remove)
    {
      [TagPeer cancelMembership:cardId tagId:tmpTag.tagId];
      [self removeFromMembershipCache:tmpTag.tagId];
    }
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
  // TODO Instead of reloading the whole table we should only reload this row
  [tableView reloadData];
  // Tell study set controller to reload its set data stats
  [[NSNotificationCenter defaultCenter] postNotificationName:@"cardAddedToTag" object:self];
}

-(NSString*) getReadingString
{
  NSString *readingStr;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
  {
    // KANA READING
    readingStr = [NSString stringWithFormat:@"%@", currentCard.reading];
  } 
  else if([[settings objectForKey:APP_READING] isEqualToString: SET_READING_ROMAJI])
  {
    // ROMAJI READING
    readingStr = [NSString stringWithFormat:@"%@", currentCard.romaji];
  }
  else
  {
    // BOTH READINGS
    readingStr = [NSString stringWithFormat:@"%@ / %@", currentCard.reading, currentCard.romaji ];
  }
  return readingStr;
}

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