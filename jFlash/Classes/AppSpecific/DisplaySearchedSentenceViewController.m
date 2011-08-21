    //
//  DisplaySearchedSentenceViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/13/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "DisplaySearchedSentenceViewController.h"


/**
 * Basic View Controller that loads a nib and shows a sentence in that display
 */
@implementation DisplaySearchedSentenceViewController

@synthesize sentence, cards;

/**
 * Initializer - automatically loads SentenceView XIB file
 * \param sentence Sentence object to display
 */
- (id) initWithSentence:(ExampleSentence*) initSentence
{
  // TODO: iPad customization!
  if ((self = [super initWithNibName:@"SentenceView" bundle:nil]))
  {
    [self setSentence:initSentence];
    [self setTitle:NSLocalizedString(@"Example Sentence",@"DisplaySearchedSentenceViewController.NavBarTitle")];
    [self setCards:[CardPeer retrieveCardSetForSentenceId:[initSentence sentenceId]]];
  }
  return self;
}


/** Handles theming the nav bar */
- (void)viewWillAppear:(BOOL)animated
{
  // View related stuff
  [super viewWillAppear:animated];
  // TODO: iPad customization!
  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.tableView.backgroundColor = [UIColor clearColor];
}

#pragma mark -
#pragma mark UITableView delegates

//! Hardcoded to 2 - header & card list
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}


//! Returns number based on section - if sentence, hardcode to 1, if cards, count of cards array
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == SECTION_SENTENCE)
    return 1;
  else if (section == SECTION_CARDS)
    return [[self cards] count];
  else
    return 0;
}


//! Returns title based on section - if sentence section, none, if cards, show "Linked Cards" or something similar
-(NSString*) tableView: (UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == SECTION_CARDS)
    return NSLocalizedString(@"Related Cards",@"DisplaySearchedSentenceViewController.TableHeader_RelatedCards");
  else
    return @"";
}


//! Returns custom height for sentence, otherwise fixed for cards (44px)
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
  if (indexPath.section == SECTION_SENTENCE)
  {
    NSString* text = [NSString stringWithFormat:@"%@\n%@", [[self sentence] sentenceJa], [[self sentence] sentenceEn]];
    return [LWEUITableUtils autosizeHeightForCellWithText:text];
  }
  else
  {
    return 44.0f;
  }
}

//! Gets the cells for each section - static cell for sentence section
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  if(indexPath.section == SECTION_SENTENCE)
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"sentence" onTable:tableView usingStyle:UITableViewCellStyleDefault];
  }
  else
  {
    cell = [LWEUITableUtils reuseCellForIdentifier:@"card" onTable:tableView usingStyle:UITableViewCellStyleSubtitle];
  } 
  
  // setup the cell for the full entry
  if(indexPath.section == SECTION_SENTENCE)
  {
    NSString* text = [NSString stringWithFormat:@"%@\n%@", [[self sentence] sentenceJa], [[self sentence] sentenceEn]];
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
    [label setLineBreakMode:UILineBreakModeWordWrap];
    [label setMinimumFontSize:LWE_UITABLE_CELL_FONT_SIZE];
    [label setNumberOfLines:0];
    [label setFont:[UIFont systemFontOfSize:LWE_UITABLE_CELL_FONT_SIZE]];
    [label setText:text];
    [label setFrame:[LWEUILabelUtils makeFrameForText:text fontSize:LWE_UITABLE_CELL_FONT_SIZE cellWidth:LWE_UITABLE_CELL_CONTENT_WIDTH cellMargin:LWE_UITABLE_CELL_CONTENT_MARGIN]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [[cell contentView] addSubview:label];
    [label release];
  }
  // the cells for either tag type look the same
  else
  {
    Card *card;
    card = [[self cards] objectAtIndex:indexPath.row];
    // Is a search result record
    cell.textLabel.text = [card headword];
    cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
    cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    NSString *meaningStr = [card meaningWithoutMarkup];
    NSString *readingStr = [card reading];
    
    if (readingStr.length > 0)
    {
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ [%@]", meaningStr, readingStr];
    }
    else
    {
      cell.detailTextLabel.text = meaningStr;
    }
  }
  return cell;
}


//! Loads AddTagViewController for any card (not sentence)     
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == SECTION_SENTENCE) return; // do nothing for the entry section
  
  // Launch AddTagViewController for this card
  AddTagViewController *tagController = [[AddTagViewController alloc] initWithCard:[[self cards] objectAtIndex:indexPath.row]];
  [[self navigationController] pushViewController:tagController animated:YES];
  [tagController release];  
}

#pragma mark -
#pragma mark Class plumbing


//! Standard dealloc
- (void)dealloc
{
  [self setSentence:nil];
  [self setCards:nil];
  [super dealloc];
}


@end
