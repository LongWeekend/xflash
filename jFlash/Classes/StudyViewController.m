//
//  StudyViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//
#import "StudyViewController.h"

@implementation StudyViewController

@synthesize cardSetProgressLabel0, cardSetProgressLabel1, cardSetProgressLabel2, cardSetProgressLabel3, cardSetProgressLabel4, cardSetProgressLabel5;
@synthesize currentCard, currentCardSet, cardHeadwordLabel, cardReadingLabel, meaningWebView;

@synthesize nextCardBtn, prevCardBtn, addBtn, rightBtn, wrongBtn, buryCardBtn, readingVisible, percentCorrectVisible, meaningMoreIconVisible, readingMoreIconVisible;
@synthesize cardReadingLabelScrollContainer, cardHeadwordLabelScrollContainer, toggleReadingBtn, showProgressModalBtn, progressModalBtn;
@synthesize showReadingBtnHiddenByUser, cardMeaningBtn, cardMeaningBtnHint, cardMeaningBtnHintMini;

@synthesize progressModalView, progressModalBorder, progressModalCloseBtn, progressModalCurrentStudySetLabel, progressModalMotivationLabel;
@synthesize percentCorrectLabel, numRight, numWrong, numViewed, cardSetLabel, isBrowseMode, stats, meaningRevealed, hhAnimationView;

@synthesize startTouchPosition, practiceBgImage, progressBarView, totalWordsLabel, currentRightStreak, currentWrongStreak, moodIcon;
@synthesize cardReadingLabelScrollContainerYPosInXib, cardHeadwordLabelHeightInXib, toggleReadingBtnYPosInXib, cardHeadwordLabelYPosInXib;


- (id) init
{
  if (self = [super init])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"13-target.png"];
    self.title = @"Practice";
  }
  else{
    LWE_LOG(@"Didn't pass super init for StudyViewController");
  }
  return self;
}


- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  // Show a UIAlert if this is the first time the user has launched the app.
  CurrentState *appSettings = [CurrentState sharedCurrentState];
  if (appSettings.isFirstLoad)
  {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Welcome to Japanese Flash!" message:@"To get you started, we've loaded our favorite words as an example set.   To study other sets, tap the 'Study Sets' icon below." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    appSettings.isFirstLoad = NO;
  }
}

- (void) viewDidLoad
{
  LWE_LOG(@"START Study View");
  [super viewDidLoad];
  // This is called before drawing the view
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"setWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"settingsWereChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetHeadword) name:@"directionWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"userWasChanged" object:nil];
  
  // Create a default mood icon object
  [self setMoodIcon:[[MoodIcon alloc] init]];
  [[self moodIcon] setMoodIconBtn:moodIconBtn];
  [[self moodIcon] setPercentCorrectLabel:percentCorrectLabel];
  
  // Set view default states
	[self setReadingVisible: NO];
  [self setPercentCorrectVisible: YES];
  [self setShowReadingBtnHiddenByUser: NO];
  [self setMeaningMoreIconVisible: NO];
  [self setReadingMoreIconVisible: YES];

  // Get values from XIB on first load
  CGRect tmpFrame;
  tmpFrame = cardReadingLabelScrollContainer.frame;
  cardReadingLabelScrollContainerYPosInXib = tmpFrame.origin.y;
  tmpFrame = cardHeadwordLabel.frame;
  cardHeadwordLabelHeightInXib = tmpFrame.size.height;
  tmpFrame = toggleReadingBtn.frame;
  toggleReadingBtnYPosInXib = tmpFrame.origin.y;
  tmpFrame = cardHeadwordLabelScrollContainer.frame;
  cardHeadwordLabelYPosInXib = tmpFrame.origin.y;

  // Reset child views
  LWE_LOG(@"CALLING resetStudySet from viewDidLoad");
	[self resetStudySet];
  LWE_LOG(@"END Study View");
}

#pragma mark Convenience methods

// a little overly complicated but needed to make the headword switch seemless for the user
- (void) resetHeadword
{
  currentCard = [CardPeer retrieveCardByPK:currentCard.cardId];
  // TODO: this will probably leak.  But if I don't do this the currentCard is unset by the time we get back here
  [currentCard retain];
  LWE_LOG(@"Calling resetKeepingCurrentCard FROM resetHeadword");
  [self resetKeepingCurrentCard];
}

// Almost the same as resetStudySet, but keeps the same session, and visible card
- (void) resetKeepingCurrentCard
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if ([[settings objectForKey:APP_MODE] isEqualToString: SET_MODE_BROWSE])
  {
    self.isBrowseMode = YES;
  }
  else
  {
    self.isBrowseMode = NO;
  }
    
  [self updateTheme];
  [self layoutCardContentForStudyDirection:[settings objectForKey:APP_HEADWORD]]; // TODO: This doesn't need to be called EVERY time!!
  LWE_LOG(@"Calling prepareViewForCard FROM resetKeepingCurrentCard");
	[self prepareViewForCard:currentCard];
}

- (void) resetStudySet
{
  // Get active set/tag
  CurrentState *currentStateSingleton = [CurrentState sharedCurrentState];
  [self setCurrentCardSet: [currentStateSingleton activeTag]];
  
  numRight = 0;
  numWrong = 0;
  numViewed = 0;
  [percentCorrectLabel setText:percentCorrectLabelStartText];
  
  Card* card = [[currentStateSingleton activeTag] getFirstCard];
  [self setCurrentCard:card];
  LWE_LOG(@"Calling resetKeepingCurrentCard FROM resetStudySet");
  [self resetKeepingCurrentCard];
  
  //tells the progress bar to redraw
  [progressBarView setNeedsDisplay];
}


// Prepare the view for the current card
- (void) prepareViewForCard:(Card*)card 
{
  LWE_LOG(@"START prepareViewForCard");
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  // Update data displayed by the card
  meaningRevealed = NO;

	// Show Blank Card
  [meaningWebView loadHTMLString:@"<html><body style='background-color: transparent'></body></html>" baseURL:nil];
	[self setCurrentCard: card];
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J])
  {
    [cardHeadwordLabel setText:[card headword_en]];    
  }
  else
  {
    [cardHeadwordLabel setText:[card headword]];    
  }
  [self updateCardReading];

  // Modify the inline CSS for current theme
  NSString *htmlHeader;
  if([[settings objectForKey:APP_THEME] isEqualToString:SET_THEME_FIRE])
  {
    htmlHeader = [HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:RED_THEME_CSS];    
  }
  else
  {
    htmlHeader = [HTML_HEADER stringByReplacingOccurrencesOfString:@"##THEMECSS##" withString:BLUE_THEME_CSS];    
  }
  
  // Show Card Meaning
  NSString *html;
  if([[settings objectForKey:APP_HEADWORD] isEqualToString: SET_E_TO_J])
  {
    html = [NSString stringWithFormat:@"%@<span class='jpn'>%@</span>%@", htmlHeader, [card headword], HTML_FOOTER];    
  }
  else
  {
    html = [NSString stringWithFormat:@"%@<span>%@</span>%@", htmlHeader, [card meaning], HTML_FOOTER];    
  }

  meaningWebView.backgroundColor = [UIColor clearColor];
  UIScrollView *scrollView = [meaningWebView.subviews objectAtIndex:0];

  SEL aSelector = NSSelectorFromString(@"setAllowsRubberBanding:");
  if([scrollView respondsToSelector:aSelector])
  {
    [scrollView performSelector:aSelector withObject:NO];
  }
  [meaningWebView loadHTMLString:html baseURL:nil]; 

  // Only layout card content after setting the card's data
  
  // Resize text within bounds
  [LWE_Util_Labels autosizeLabelText:cardReadingLabel forScrollView:cardReadingLabelScrollContainer withText:[currentCard reading] minFontSize:READING_MIN_FONTSIZE maxFontSize:READING_MAX_FONTSIZE];
  [LWE_Util_Labels autosizeLabelText:cardHeadwordLabel forScrollView:cardHeadwordLabelScrollContainer withText:[currentCard headword] minFontSize:HEADWORD_MIN_FONTSIZE maxFontSize:HEADWORD_MAX_FONTSIZE];
  
 	[cardSetLabel setText:[NSString stringWithFormat:@"Set: %@",currentCardSet.tagName]];
  
  [rightBtn setHidden:YES];
  [wrongBtn setHidden:YES];
  [buryCardBtn setHidden:YES];
  [addBtn setHidden:YES];

	if(isBrowseMode == YES)
  {
    [meaningWebView setHidden:NO];
		[cardMeaningBtn setHidden:YES];
    [cardMeaningBtnHint setHidden:YES];
    [cardMeaningBtnHintMini setHidden:YES];
    [prevCardBtn setHidden:NO];
		[nextCardBtn setHidden:NO];
    [self doTogglePercentCorrectBtn];
    [toggleReadingBtn setHidden:YES];
    [cardReadingLabelScrollContainer setHidden:NO];
    [cardReadingLabel setHidden:NO];
    readingVisible = YES;
	}
	else
  {
    [meaningWebView setHidden:YES];
		[cardMeaningBtn setHidden:NO];
    [cardMeaningBtnHint setHidden:NO];
    [cardMeaningBtnHintMini setHidden:NO];
		[prevCardBtn setHidden:YES];
		[nextCardBtn setHidden:YES];
	}

  // Show Reading Btn Pressed By User
  if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J] && isBrowseMode == NO)
  {
    [toggleReadingBtn setHidden:YES];
    [cardReadingLabelScrollContainer setHidden:YES];
    [cardReadingLabel setHidden:YES];
    readingVisible = NO;
  }
  else if([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_J_TO_E] || [[settings objectForKey:APP_HEADWORD] isEqualToString:SET_E_TO_J] && isBrowseMode == YES)
  {
    [toggleReadingBtn setHidden:NO];
    if(self.showReadingBtnHiddenByUser == YES){
      [self hideShowReadingBtn];
      [cardReadingLabelScrollContainer setHidden:NO];
      [cardReadingLabel setHidden:NO];
      readingVisible = YES;
    }else{
      [self displayShowReadingBtn];
      [cardReadingLabelScrollContainer setHidden:YES];
      [cardReadingLabel setHidden:YES];
      readingVisible = NO;
    }
  }
  if(!percentCorrectVisible && !self.isBrowseMode){
    [self doTogglePercentCorrectBtn];
  }

  // TODO - this relies on data before that data may not be ready
  [self drawProgressBar];
  [self toggleMoreIconForLabel:cardReadingLabel forScrollView:cardReadingLabelScrollContainer];
  [self toggleMoreIconForLabel:cardHeadwordLabel forScrollView:cardHeadwordLabelScrollContainer];
  LWE_LOG(@"END prepareViewForCard");
}


- (void) updateCardReading
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *combined_reading;

  // Mux the readings according to user preference
  if([[settings objectForKey:APP_READING] isEqualToString:SET_READING_KANA])
  {
    combined_reading = [[NSString alloc] initWithFormat:@"%@", [currentCard reading]];
  } 
  else if([[settings objectForKey:APP_READING] isEqualToString: SET_READING_ROMAJI])
  {
    combined_reading = [[NSString alloc] initWithFormat:@"%@", [currentCard romaji]];
  }
  else
  {
    // Both together
    combined_reading = [[NSString alloc] initWithFormat:@"%@\n%@", [currentCard reading], [currentCard romaji]];
  }
  [cardReadingLabel setText:combined_reading];
  [LWE_Util_Labels resizeLabelWithConstraints:cardReadingLabel minFontSize:READING_MIN_FONTSIZE maxFontSize:READING_MAX_FONTSIZE forParentViewSize:cardReadingLabelScrollContainer.frame.size];
  [combined_reading release];
}

# pragma mark IBOutlet Button Actions


// Basic method to change cards
- (void) doChangeCard: (Card*) card direction:(NSString*)direction
{
  if (card != nil)
  {
    LWE_LOG(@"Calling prepareViewForCard FROM doChangeCard");
    [self prepareViewForCard:card];
    [self doCardTransition:(NSString *)kCATransitionPush direction:(NSString*)direction];
  }
}

// Transition between cards after a button has been pressed
- (void) doCardTransition:(NSString *)transition direction:(NSString *)direction
{
	if (isBrowseMode)
  {
    [rightBtn setEnabled: YES];
    [wrongBtn setEnabled: YES];	
    [buryCardBtn setEnabled: YES];	
	}
	else
  {
    [rightBtn setEnabled: NO];
    [wrongBtn setEnabled: NO];
    [buryCardBtn setEnabled: NO];
	}
  // tells the progress bar to redraw
  [progressBarView setNeedsDisplay];
	UIView *theWindow = [self.view superview];
	[UIView beginAnimations:nil context:NULL];

	// set up an animation for the transition between the views
	CATransition *animation = [CATransition animation];
	[animation setDelegate:self];
	[animation setDuration:0.15];
	[animation setType:transition];
	[animation setSubtype:direction];
  [[theWindow layer] addAnimation:animation forKey:kAnimationKey];
	[UIView commitAnimations];
}

- (void) doCardBtn: (int)action
{
  // Hold on to the last card
  Card* lastCard = nil;
  lastCard = self.currentCard;
  [lastCard retain];

  BOOL knewIt = NO;
  
	switch (action)
  {
    // Browse Mode options
    case NEXT_BTN:
      [self doChangeCard: [currentCardSet getNextCard] direction:kCATransitionFromRight];
      break;
    case PREV_BTN:
      [self doChangeCard: [currentCardSet getPrevCard] direction:kCATransitionFromLeft];
      break;
      
    // Quiz mode options
    case SKIP_BTN:
      [self doChangeCard: [currentCardSet getRandomCard:currentCard.cardId] direction:kCATransitionFromRight];
      break;

    case BURY_BTN:
      knewIt = YES;
    
    case RIGHT_BTN:
      numRight++;
      numViewed++;
      currentRightStreak++;
      currentWrongStreak = 0;
      [UserHistoryPeer recordResult:lastCard gotItRight:YES knewIt:knewIt];
      [self doChangeCard: [currentCardSet getRandomCard:currentCard.cardId] direction:kCATransitionFromRight];
      break;
      
    case WRONG_BTN:
      numWrong++;
      numViewed++;
      currentWrongStreak++;
      currentRightStreak = 0;
      [UserHistoryPeer recordResult:lastCard gotItRight:NO knewIt:NO];
      [self doChangeCard: [currentCardSet getRandomCard:currentCard.cardId] direction:kCATransitionFromRight];
      break;      
  }

  // Update the speech bubble
  float tmpRatio = 100*((float)numRight / (float)numViewed);
  [moodIcon updateMoodIcon:tmpRatio];

  // Releases
  [lastCard release];
}

- (IBAction) doNextCardBtn
{
  if (self.isBrowseMode) 
    [self doCardBtn:NEXT_BTN];
  else
    [self doCardBtn:SKIP_BTN];
}

- (IBAction) doPrevCardBtn
{
  if (self.isBrowseMode) 
    [self doCardBtn:PREV_BTN];
  else
    [self doCardBtn:SKIP_BTN];
}

- (IBAction) doBuryCardBtn
{
  [self doCardBtn:BURY_BTN];
}

- (IBAction) doRightBtn
{
  [self doCardBtn:RIGHT_BTN];
}

- (IBAction) doWrongBtn
{
  [self doCardBtn:WRONG_BTN];
}

- (IBAction) doToggleReadingBtn
{
  if (readingVisible)
  { 
    [cardReadingLabelScrollContainer setHidden:YES];
    [cardReadingLabel setHidden:YES];
    [self displayShowReadingBtn];
    showReadingBtnHiddenByUser = NO;
  }
  else
  {
    [cardReadingLabelScrollContainer setHidden:NO];
    [cardReadingLabel setHidden:NO];
    [self hideShowReadingBtn];
    showReadingBtnHiddenByUser = YES;
  }
}

- (IBAction) doAddToSetBtn
{
  // Unavoidably (perhaps?) uses jFlashAppDelegate to launch a modal view (for adding to set)
	jFlashAppDelegate *appDelegate = (jFlashAppDelegate *)[[UIApplication sharedApplication] delegate];

  UIBarButtonItem* doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:[self parentViewController] action:@selector(dismissModalViewControllerAnimated:)];
	AddTagViewController *modalViewController = [[[AddTagViewController alloc] initWithNibName:@"AddTagView" bundle:nil] autorelease];
	modalViewController.cardId = currentCard.cardId;
	modalViewController.navigationItem.leftBarButtonItem = doneBtn;
	modalViewController.navigationItem.title = @"Add Word To Sets";
  modalViewController.currentCard = currentCard;
	UINavigationController *modalNavControl = [[UINavigationController alloc] initWithRootViewController:modalViewController];
  modalNavControl.navigationBar.tintColor = [CurrentState getThemeTintColor];
  [[[appDelegate rootViewController] tabBarController] presentModalViewController:modalNavControl animated:YES];

	[modalNavControl release];
	[doneBtn release];
}

- (IBAction) doRevealMeaningBtn
{
	if (self.isBrowseMode) return;
  meaningRevealed = YES;
  
	[cardMeaningBtn setHidden:YES];
	[cardMeaningBtnHint setHidden:YES];
	[cardMeaningBtnHintMini setHidden:YES];
	[prevCardBtn setHidden:YES];
	[nextCardBtn setHidden:YES];
  
	[rightBtn setHidden:NO];
	[wrongBtn setHidden:NO];
  [addBtn setHidden:NO];
  [buryCardBtn setHidden:NO];
  
  [rightBtn setEnabled: YES];
	[wrongBtn setEnabled: YES];	
  [buryCardBtn setEnabled:YES];
  [addBtn setEnabled:YES];

  [meaningWebView setHidden:NO];

  // Always show reading on reveal
  [self hideShowReadingBtn];
  [cardReadingLabelScrollContainer setHidden:NO];
  [cardReadingLabel setHidden:NO];

  [self toggleMoreIconForLabel:cardReadingLabel forScrollView:cardReadingLabelScrollContainer];
}

- (IBAction) doDismissProgressModalBtn
{
  // Bring up the modal dialog for progress view
  [progressModalView setHidden:YES];
}

- (IBAction) doTogglePercentCorrectBtn
{
  // Hide the percentage talk bubble on click
  if(!percentCorrectVisible && !self.isBrowseMode)
  {
    [percentCorrectTalkBubble setHidden:NO];
    [percentCorrectLabel setHidden:NO];
    percentCorrectVisible = YES;
  }
  else
  {
    [percentCorrectTalkBubble setHidden:YES];
    [percentCorrectLabel setHidden:YES];
    percentCorrectVisible = NO;
  }
}

- (IBAction) doShowProgressModalBtn
{
  // Bring up the modal dialog for progress view
	ProgressView *progressView = [[ProgressView alloc] init];
  progressView.rightStreak = currentRightStreak;
  progressView.wrongStreak = currentWrongStreak;
  NSMutableArray* levelDetails = [self getLevelDetails];
  progressView.levelDetails = levelDetails;
  
  [self.navigationController pushViewController:progressView animated:NO];
  [self.view addSubview:progressView.view];
  
  progressView.currentStudySet.text = currentCardSet.tagName;
  progressView.cardsRightNow.text = [NSString stringWithFormat:@"%i", numRight];
  progressView.cardsWrongNow.text = [NSString stringWithFormat:@"%i", numWrong];
  progressView.cardsViewedNow.text = [NSString stringWithFormat:@"%i", numViewed];
  
  NSArray* records = [UserHistoryPeer getRightWrongTotalsBySet:currentCardSet.tagId];
  int rightCount = [[records objectAtIndex:0] intValue];
  int wrongCount = [[records objectAtIndex:1] intValue];
  progressView.cardsRightAllTime.text = [NSString stringWithFormat:@"%i", rightCount];
  progressView.cardsWrongAllTime.text = [NSString stringWithFormat:@"%i", wrongCount];
}

- (void) hideShowReadingBtn
{
  readingVisible = YES;
  [toggleReadingBtn setBackgroundImage:NULL forState:UIControlStateNormal];
}

- (void) displayShowReadingBtn
{
  readingVisible = NO;
  [toggleReadingBtn setBackgroundImage:[UIImage imageNamed:@"practice-btn-showreading.png"] forState:UIControlStateNormal];
}


#pragma mark UI updater convenience methods

- (void) layoutCardContentForStudyDirection: (NSString*)studyDirection
{

  // Y-Positions for J_TO_E Mode
  // NB: with UIScrollView objects you have to add the height of itself to it's y-position
  int readingY    = cardReadingLabelScrollContainerYPosInXib;
  int readingBtnY = toggleReadingBtnYPosInXib;
  int headwordY   = cardHeadwordLabelYPosInXib;

  // Text format options for J_TO_E Mode
  UIFont  *readingFont  = [UIFont boldSystemFontOfSize:READING_DEF_FONTSIZE];
  UIColor *readingColor = [UIColor whiteColor];

  CGRect readingFrame = cardReadingLabelScrollContainer.frame;
  CGRect headwordFrame = cardHeadwordLabelScrollContainer.frame;
  CGRect readingBtnFrame = toggleReadingBtn.frame;
  CGRect readingScrollMoreFrame = cardReadingLabelScrollMoreIcon.frame;
  CGRect headwordScrollMoreFrame = cardHeadwordLabelScrollMoreIcon.frame;
  
  // Y-Positions for E_TO_J Mode
  if([studyDirection isEqualToString: SET_E_TO_J])
  {
    // Move headword to reading's Y position
    headwordY = readingY;
    
    // Now redefine val for reading Y
    readingY = readingY + headwordFrame.size.height;//+ (cardReadingLabelScrollContainerYPosInXib -readingFrame.size.height);
    readingBtnY = readingY;

    // Text format options for J_TO_E Mode
    readingFont = [UIFont boldSystemFontOfSize:READING_DEF_FONTSIZE];
    readingColor = [UIColor whiteColor];
  }

  // Set new linebreak modes
  if([studyDirection isEqualToString: SET_E_TO_J])
  {
    cardHeadwordLabel.lineBreakMode = UILineBreakModeWordWrap;
  } else {
    cardHeadwordLabel.lineBreakMode = UILineBreakModeCharacterWrap;
  }

  // Move cardReadingLabel
  readingFrame.origin.y = readingY;
  cardReadingLabelScrollContainer.frame = readingFrame;

  // Move revealReadingBtn
  readingBtnFrame.origin.y = readingBtnY;
  toggleReadingBtn.frame = readingBtnFrame;
  
  // Move cardHeadwordLabelScrollContainer
  headwordFrame.origin.y = headwordY;
  cardHeadwordLabelScrollContainer.frame = headwordFrame;
  
  // Move the headword Scroll More Icon
  headwordScrollMoreFrame.origin.y = headwordY+(headwordFrame.size.height/3);
  cardHeadwordLabelScrollMoreIcon.frame = headwordScrollMoreFrame;
    
  // Move cardReadingLabelScrollMoreIcon
  readingScrollMoreFrame.origin.y = readingBtnY+(CARDCONTENT_PADDING*3);
  cardReadingLabelScrollMoreIcon.frame = readingScrollMoreFrame;
  
  // Adjust cardReaingLabel properties
  cardReadingLabel.textColor = readingColor;
  cardReadingLabel.font = readingFont;

}

// Toggle "more" icon to indicate the user can scroll meaning down
- (void) toggleMoreIconForLabel:(UILabel *)theLabel forScrollView: (UIScrollView *)scrollViewContainer {

  CGSize theLabelSize = theLabel.frame.size;
  CGSize theParentSize = scrollViewContainer.frame.size;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

  if(theLabel == cardReadingLabel){
    if(theLabelSize.height > theParentSize.height){
      if([[settings objectForKey:APP_HEADWORD] isEqualToString: SET_E_TO_J] && meaningRevealed){
        [cardReadingLabelScrollMoreIcon setHidden:NO];
      }else if(!meaningRevealed){
        [cardReadingLabelScrollMoreIcon setHidden:YES];
      } else {
        [cardReadingLabelScrollMoreIcon setHidden:NO];
      }
    } else {
      [cardReadingLabelScrollMoreIcon setHidden:YES];
    }
  }
  else if(theLabel == cardHeadwordLabel){
    if(theLabelSize.height > theParentSize.height){
      [cardHeadwordLabelScrollMoreIcon setHidden:NO];
    } else {
      [cardHeadwordLabelScrollMoreIcon setHidden:YES];
    }
  }
  
}


- (void) updateTheme
{
  NSString* tmpStr = [NSString stringWithFormat:@"/%@theme-cookie-cutters/practice-bg.png",[CurrentState getThemeName]];
  [practiceBgImage setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:tmpStr]]];
  float tmpRatio;
  if(numViewed == 0)
    tmpRatio = 100.0f;
  else
    tmpRatio = 100*((float)numRight / (float)numViewed);
  [moodIcon updateMoodIcon:tmpRatio];
}


- (NSMutableArray*) getLevelDetails
{
  // This is a convenience method that alloc's and sets to autorelease!
  NSMutableArray* levelDetails = nil;
  NSNumber *countObject;
  int i;
  float seencount;

  // Crash protection in case we don't have the card level counts yet
  if ([[currentCardSet cardLevelCounts] count] == 6)
  {
    levelDetails = [NSMutableArray arrayWithCapacity: 6];
    for (i = 0; i < 6; i++)
    {
      countObject =[[currentCardSet cardLevelCounts] objectAtIndex:i];
      [levelDetails addObject:countObject];
      if(i > 0)
        seencount = seencount + [[levelDetails objectAtIndex:i] floatValue];
    }
    [levelDetails addObject:[NSNumber numberWithInt:[currentCardSet cardCount]]];  
    [levelDetails addObject:[NSNumber numberWithFloat:seencount]];
  }
  return levelDetails;
}

// draws the progress bar
- (void) drawProgressBar
{
  for (UIView *view in progressBarView.subviews)
  {
    [view removeFromSuperview];
  }

  NSMutableArray* levelDetails = [self getLevelDetails];
  if (levelDetails)
  {
    // set the x / total to the current index in browse mode
    if(isBrowseMode)
    {
      [cardSetProgressLabel0 setText:[NSString stringWithFormat:@"%d / %d",[currentCardSet currentIndex]+1, [currentCardSet cardCount]]];
    }
    else
    {
      [cardSetProgressLabel0 setText:[NSString stringWithFormat:@"%d / %d",[[levelDetails objectAtIndex:0]intValue], [currentCardSet cardCount]]];
    }
    [cardSetProgressLabel1 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:1]intValue]]];  
    [cardSetProgressLabel2 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:2]intValue]]];  
    [cardSetProgressLabel3 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:3]intValue]]];  
    [cardSetProgressLabel4 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:4]intValue]]];  
    [cardSetProgressLabel5 setText:[NSString stringWithFormat:@"%d",[[levelDetails objectAtIndex:5]intValue]]];
  }

  NSArray* lineColors = [NSArray arrayWithObjects:[UIColor darkGrayColor],[UIColor redColor],[UIColor lightGrayColor],[UIColor cyanColor],[UIColor orangeColor],[UIColor greenColor], nil];
  int i;
  int pbOrigin = 7;
  float thisCount;

  for (i = 1; i < 6; i++)
  {
    PDColoredProgressView *progressView = [[PDColoredProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
    [progressView setTintColor:[lineColors objectAtIndex: i]];
    if(i == 1)
    {
      thisCount = [[levelDetails objectAtIndex: 7] floatValue];
    }
    else
    {
      thisCount -= [[levelDetails objectAtIndex: i-1] floatValue]; 
    }
    float seencount = [[levelDetails objectAtIndex: 7] floatValue];
    float progress;
    if(seencount == 0)
    {
      progress = 0;
    }
    else
    {
      progress = thisCount / seencount;
    }
    progressView.progress = progress;
    CGRect frame = progressView.frame;
    frame.size.width = 57;
    frame.size.height = 14;
    frame.origin.x = pbOrigin;
    frame.origin.y = 19;

    progressView.frame = frame;
    [progressBarView addSubview:progressView];
    [progressView release];
    
    //move the origin of the next progress bar over
    pbOrigin += frame.size.width + 5;
  }
}


#pragma mark Touch interface methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  startTouchPosition = [touch locationInView:self.view]; 
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  CGPoint currentTouchPosition = [touch locationInView:self.view];
    
  // If the swipe tracks correctly.
  if ((fabsf(startTouchPosition.x - currentTouchPosition.x) >= HORIZ_SWIPE_DRAG_MIN &&
      fabsf(startTouchPosition.y - currentTouchPosition.y) <= VERT_SWIPE_DRAG_MAX) &&
      self.isBrowseMode)
      {
      // It appears to be a swipe.
      if (startTouchPosition.x < currentTouchPosition.x)
        [self doPrevCardBtn];
      else 
        [self doNextCardBtn];
  }
  else
  {
    // Process a non-swipe event.
  }
}


#pragma mark Class plumbing

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release anything that's not essential, such as cached data
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [cardSetLabel release];
  [cardSetProgressLabel0 release];
  [cardSetProgressLabel1 release];
  [cardSetProgressLabel2 release];
  [cardSetProgressLabel3 release];
  [cardSetProgressLabel4 release];
  [cardSetProgressLabel5 release];
  [cardHeadwordLabel release];
  [cardReadingLabel release];
  [percentCorrectLabel release];
  [totalWordsLabel release];
  
  [addBtn release];
  [buryCardBtn release];
  [nextCardBtn release];
  [prevCardBtn release];
  [rightBtn release];
  [wrongBtn release];
  [cardMeaningBtn release];
  [toggleReadingBtn release];
  [showProgressModalBtn release];
  [practiceBgImage release];
  [progressBarView release];
  [cardMeaningBtnHint release];
  [cardMeaningBtnHintMini release];
  [hhAnimationView release];
  
  [progressModalView release];
  [progressModalBorder release];
  [progressModalBtn release];
  [progressModalCloseBtn release];
  [progressModalCurrentStudySetLabel release]; 
  [progressModalMotivationLabel release];
  [meaningWebView release];
  
  [currentCardSet release];
  [currentCard release];
  [stats release];
  
	[super dealloc];
}


@end