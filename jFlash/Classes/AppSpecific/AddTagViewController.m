//
//  AddTagViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/28/09.
//  Copyright 2009 LONG WEEKEND LLC. All rights reserved.
//

#import "AddTagViewController.h"
#import "AddStudySetInputViewController.h"
#import "SettingsViewController.h"
#import "TagPeer.h"
#import "ChineseCard.h"

enum AddTagSections
{
  kAddTagEntrySection = 0,
  kAddTagUserSection = 1,
  kAddTagSystemSection = 2,
  kAddTagSectionCount
};

enum EntrySectionRows
{
  kEntrySectionInfoRow = 0,
  kEntrySectionCount
};

// Private methods & properties
@interface AddTagViewController ()
- (void) _reloadTableData;
@property (retain) NSMutableArray *membershipCacheArray;
@end

@implementation AddTagViewController
@synthesize myTagArray,sysTagArray,membershipCacheArray,currentCard;

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
    LWE_ASSERT_EXC((card.isFault == NO), @"Card passed to AddTagViewcontroller should not be a fault!");
    self.currentCard = card;
    self.myTagArray = [TagPeer retrieveUserTagList];
    self.sysTagArray = [TagPeer retrieveSysTagListContainingCard:card];
    
    // Add "add" button to nav bar
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addStudySet)];
    self.navigationItem.rightBarButtonItem = addButton;
    [addButton release];

    // Set nav bar title
    self.navigationItem.title = NSLocalizedString(@"Add Word To Sets",@"AddTagViewController.NavBarTitle");
  }
  return self;
}

#pragma mark - UIViewController methods

- (void) viewDidLoad
{
  [super viewDidLoad];

  // Set up the table view background so we're not looking at cat's pajamas
  self.tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:LWETableBackgroundImage]] autorelease];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];

  // Cache the tag's membership list
  self.membershipCacheArray = [[[TagPeer faultedTagsForCard:self.currentCard] mutableCopy] autorelease];
  
  // For listening for headword direction changes
  [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:APP_HEADWORD_TYPE options:NSKeyValueObservingOptionNew context:NULL];
  [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:APP_THEME options:NSKeyValueObservingOptionNew context:NULL];

  // Register listener to reload data if modal added a set
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagContentDidChange:) name:LWETagContentDidChange object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_reloadTableData) name:kSetWasAddedOrUpdated object:nil];
}

- (void) viewDidUnload
{
  [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:APP_HEADWORD_TYPE];
  [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:APP_THEME];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewDidUnload];
}

#pragma mark - KVO

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:APP_HEADWORD_TYPE])
  {
    [self.tableView reloadData];
  }
  else if ([keyPath isEqualToString:APP_THEME])
  {
    self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  }
  else
  {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark - Tag Content Did Change Methods

- (void) tagContentDidChange:(NSNotification *)notification
{
  // If the card that changed wasn't what we are currently showing, who cares?
  Card *card = [notification.userInfo objectForKey:LWETagContentDidChangeCardKey];
  if ([self.currentCard isEqual:card] == NO)
  {
    return;
  }
  
  // OK, it is our card, update the tag membership.
  Tag *changedTag = (Tag*)notification.object;
  NSString *type = [notification.userInfo objectForKey:LWETagContentDidChangeTypeKey];
  if ([type isEqualToString:LWETagContentCardAdded])
  {
    [self.membershipCacheArray addObject:changedTag];
  }
  else if ([type isEqualToString:LWETagContentCardRemoved])
  {
    [self.membershipCacheArray removeObject:changedTag];
  }
  [self.tableView reloadData];
}

#pragma mark - IBAction Methods

/** Target action for the Nav Bar "Add" button, launches AddStudySetInputViewController in a modal */
- (IBAction) addStudySet
{
  AddStudySetInputViewController *tmpVC = [[AddStudySetInputViewController alloc] initWithDefaultCard:self.currentCard inGroup:nil];
  UINavigationController *modalNavController = [[UINavigationController alloc] initWithRootViewController:tmpVC];
	[tmpVC release];
  [self.navigationController presentModalViewController:modalNavController animated:YES];
  [modalNavController release];
}

#pragma mark - Private Methods

//! Recreates tag membership caches and reloads table view
- (void) _reloadTableData
{
  self.myTagArray = [TagPeer retrieveUserTagList];
  self.membershipCacheArray = [[[TagPeer faultedTagsForCard:self.currentCard] mutableCopy] autorelease];
  [self.tableView reloadData];
}

- (void) _toggleMembershipForTag:(Tag *)tmpTag
{
  // Check whether or not we are ADDING or REMOVING from the selected tag
  if ([self.membershipCacheArray containsObject:tmpTag])
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
    [self.membershipCacheArray removeObject:tmpTag];
  }
  else
  {
    [TagPeer subscribeCard:self.currentCard toTag:tmpTag];
    [self.membershipCacheArray addObject:tmpTag];
  }
}

#pragma mark - UITableViewDataSource Methods

//! Returns the total number of enum values in "Sections" enum
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return kAddTagSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger i = 0;
  if (section == kAddTagUserSection)
  {
    i = [self.myTagArray count];
  }
  else if (section == kAddTagSystemSection)
  {
    i = [self.sysTagArray count];  
  }
  else if (section == kAddTagEntrySection)
  {
    i = kEntrySectionCount;
  }
  return i;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  if (indexPath.section == kAddTagEntrySection)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"entry" onTable:tableView usingStyle:UITableViewCellStyleDefault];
  }
  else 
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"cell" onTable:tableView usingStyle:UITableViewCellStyleDefault];
  } 
  
  // setup the cell for the full entry
  if (indexPath.section == kAddTagEntrySection)
  {
    // Don't re-add the same label
    UILabel *label = (UILabel*)[cell.contentView viewWithTag:101];
    if (label == nil)
    {
      label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
      label.tag = 101;
      [cell.contentView addSubview:label];
    }
    
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.minimumFontSize = FONT_SIZE_ADD_TAG_VC;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:FONT_SIZE_ADD_TAG_VC];
    
    NSString *reading = nil;
#if defined(LWE_CFLASH)
    reading = [(ChineseCard *)currentCard pinyinReading];
#else
    reading = [self.currentCard reading];
#endif  
    label.text = [NSString stringWithFormat:@"[%@]\n%@", reading, [self.currentCard meaningWithoutMarkup]];
    [label adjustFrameWithFontSize:FONT_SIZE_ADD_TAG_VC
                         cellWidth:LWE_UITABLE_CELL_CONTENT_WIDTH
                        cellMargin:LWE_UITABLE_CELL_CONTENT_MARGIN];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  // the cells for either tag type look the same
  else
  {        
    // Get the tag arrays
    Tag *tmpTag = nil;
    if (indexPath.section == kAddTagUserSection)
    {
      tmpTag = [self.myTagArray objectAtIndex:indexPath.row];
      cell.selectionStyle = UITableViewCellSelectionStyleGray;
      if ([self.membershipCacheArray containsObject:tmpTag])
      {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
      }
      else
      {
        cell.accessoryType = UITableViewCellAccessoryNone;
      }
    }
    else if (indexPath.section == kAddTagSystemSection)
    {
      tmpTag = [self.sysTagArray objectAtIndex:indexPath.row];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.textLabel.text = tmpTag.tagName;
  }
  
  return cell;
}


#pragma mark - UITableViewDelegate methods

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  if (section == kAddTagEntrySection)
  {
    UIView *containingView = [[[UIView alloc] init] autorelease];
    containingView.autoresizesSubviews = NO;
    UILabel *headword = [[[UILabel alloc] initWithFrame:CGRectMake(15, 5, 300, 50)] autorelease];
    headword.text = [self.currentCard headwordIgnoringMode:YES];
    headword.backgroundColor = [UIColor clearColor];
    headword.shadowColor = [UIColor whiteColor];
    headword.shadowOffset = CGSizeMake(0.5f,1.0f);
    headword.textColor = [UIColor colorWithRed:0.3f green:0.3f blue:0.4f alpha:1.0f];
    headword.font = [UIFont boldSystemFontOfSize:24];
#if defined (LWE_CFLASH)
    headword.font = [ChineseCard configureFontForLabel:headword];
#endif
    [containingView addSubview:headword];
    return containingView;
  }
  else
  {
    // Use the method below and let UI kit do the hard work
    return nil;
  }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  if (section == kAddTagEntrySection)
  {
    return 50.0f;
  }
  else
  {
    return 44.0f;
  }
}

-(NSString*) tableView: (UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == kAddTagUserSection)
  {
    return NSLocalizedString(@"My Sets",@"AddTagViewController.TableHeader_MySets");
  }
  else if (section == kAddTagSystemSection && ([self.sysTagArray count] > 0))
  {
    return NSLocalizedString(@"Other Sets with this Card",@"AddTagViewController.TableHeader_AllSets");
  }
  else
  {
    return nil;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
  if (indexPath.section == kAddTagEntrySection)
  {
    NSString *text = [NSString stringWithFormat:@"[%@]\n%@", [self.currentCard reading], [self.currentCard meaningWithoutMarkup]];
    return [LWEUITableUtils autosizeHeightForCellWithText:text];
  }
  else 
  {
    return 44.0f;
  }
}


/**
 * Called when the user selects one of the table rows containing a tag name
 * Calls subscribe or cancel set membership accordingly
 */
- (void)tableView:(UITableView *)lclTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [lclTableView deselectRowAtIndexPath:indexPath animated:NO];
  
  // do nothing for the entry section or system tags
  if (indexPath.section == kAddTagEntrySection || indexPath.section == kAddTagSystemSection)
  {
    return;
  }

  Tag *tmpTag = [self.myTagArray objectAtIndex:indexPath.row];
  [self _toggleMembershipForTag:tmpTag];
  
  // MMA: TODO: we shouldn't reload the whole table, that's really lazy-- weshould change the row
  [lclTableView reloadData];
}


#pragma mark - Class plumbing

//! Standard dealloc
- (void)dealloc
{
  [myTagArray release];
  [sysTagArray release];
  [currentCard release];
  [membershipCacheArray release];
  [super dealloc];
}


@end