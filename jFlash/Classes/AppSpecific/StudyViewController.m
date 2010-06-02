//
//  StudyViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//
#import "StudyViewController.h"

@implementation StudyViewController
@synthesize currentCard, currentCardSet, remainingCardsLabel;

@synthesize nextCardBtn, prevCardBtn, addBtn, rightBtn, wrongBtn, buryCardBtn, percentCorrectVisible, meaningMoreIconVisible, readingMoreIconVisible;
@synthesize cardMeaningBtnHint, cardMeaningBtnHintMini;

@synthesize progressModalView, progressModalBtn, progressBarViewController, progressBarView;
@synthesize percentCorrectLabel, numRight, numWrong, numViewed, cardSetLabel, isBrowseMode, stats, hhAnimationView;
@synthesize startTouchPosition, practiceBgImage, totalWordsLabel, currentRightStreak, currentWrongStreak, moodIcon, cardMeaningBtn, cardViewController, cardView;

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
  
 [self _resetActionMenu];
  
 // redraw the progress bar
 [self refreshProgressBarView];
}

- (void) _resetActionMenu
{
  [rightBtn setHidden:YES];
  [wrongBtn setHidden:YES];
  [buryCardBtn setHidden:YES];
  [addBtn setHidden:YES];
  
	if(isBrowseMode == YES)
  {
    [cardMeaningBtn setHidden:YES];
    [cardMeaningBtnHint setHidden:YES];
    [cardMeaningBtnHintMini setHidden:YES];
    [prevCardBtn setHidden:NO];
    [nextCardBtn setHidden:NO];
    [self doTogglePercentCorrectBtn];
	}
	else
  {
    [cardMeaningBtn setHidden:NO];
    [cardMeaningBtnHint setHidden:NO];
    [cardMeaningBtnHintMini setHidden:NO];
    [prevCardBtn setHidden:YES];
    [nextCardBtn setHidden:YES];
	}
  
  if(!percentCorrectVisible && !self.isBrowseMode){
    [self doTogglePercentCorrectBtn];
  }
  
  // update the remaining cards label
  if(isBrowseMode)
  {
    [remainingCardsLabel setText:[NSString stringWithFormat:@"%d / %d",[currentCardSet currentIndex]+1, [currentCardSet cardCount]]];
  }
  else	
  {
    [remainingCardsLabel setText:[NSString stringWithFormat:@"%d / %d", [[[currentCardSet cardLevelCounts] objectAtIndex:0] intValue], [currentCardSet cardCount]]];
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
  // TODO: refactor to delegate of cardView
  [self setPercentCorrectVisible: YES];
  [self setMeaningMoreIconVisible: NO];
  [self setReadingMoreIconVisible: YES];

  // Initialize the progressBarView
  [self setProgressBarViewController:[[ProgressBarViewController alloc] init]];
  [[self progressBarView] addSubview:progressBarViewController.view];
  
  // Add the CardView to the View
  [self setCardViewController:[[CardViewController alloc] init]];
  [[self cardViewController] setCurrentCard:[self currentCard]];
  [[self cardView] addSubview: [[self cardViewController] view]];  

  // Reset child views
  LWE_LOG(@"CALLING resetStudySet from viewDidLoad");
	[self resetStudySet];
  LWE_LOG(@"END Study View");
}

#pragma mark Convenience methods

// a little overly complicated but needed to make the headword switch seemless for the user
- (void) resetHeadword
{
  [self setCurrentCard:[CardPeer retrieveCardByPK:currentCard.cardId]];
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
    BrowseModeCardViewDelegate *cardViewControllerDelegate = [[BrowseModeCardViewDelegate alloc] init];
    [cardViewController setDelegate:cardViewControllerDelegate];
  }
  else
  {
    self.isBrowseMode = NO;
    PracticeModeCardViewDelegate *cardViewControllerDelegate = [[PracticeModeCardViewDelegate alloc] init];
    [cardViewController setDelegate:cardViewControllerDelegate];
  }
    
  [self updateTheme];
  LWE_LOG(@"Calling prepareView on cardView FROM resetKeepingCurrentCard");
  [[self cardViewController] layoutCardContentForStudyDirection:[settings objectForKey:APP_HEADWORD]];
  [[self cardViewController] setCurrentCard:[self currentCard]];
	[[self cardViewController] prepareView];
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
  
  [cardSetLabel setText:[NSString stringWithFormat:@"Set: %@",currentCardSet.tagName]];
  
  Card* card = [[currentStateSingleton activeTag] getFirstCard];
  [self setCurrentCard:card];
  LWE_LOG(@"Calling resetKeepingCurrentCard FROM resetStudySet");
  [self resetKeepingCurrentCard];
  
  //tells the progress bar to redraw
  [self refreshProgressBarView];
}

//! redraws the progress bar with new level details
- (void) refreshProgressBarView
{
  [progressBarViewController setLevelDetails: [self getLevelDetails]];
  [[self progressBarViewController] drawProgressBar];
}

#pragma mark Generic Transition Methods

//! Basic method to change cards
- (void) doChangeCard: (Card*) card direction:(NSString*)direction
{
  if (card != nil)
  {
    [self setCurrentCard:card];
    [[self cardViewController] setCurrentCard:[self currentCard]];
    LWE_LOG(@"Calling prepareView FROM doChangeCard");
    [[self cardViewController] prepareView];
    [self _resetActionMenu];
    [self doCardTransition:(NSString *)kCATransitionPush direction:(NSString*)direction];
    [self refreshProgressBarView];
  }
}

// Transition between cards after a button has been pressed
- (void) doCardTransition:(NSString *)transition direction:(NSString *)direction
{
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

# pragma mark IBOutlet Button Actions

- (void) doCardBtn: (int)action
{
  // Hold on to the last card
  Card* lastCard = nil;
  lastCard = [self currentCard];
  [lastCard retain];

  BOOL knewIt = NO;
  numViewed++;
  
	switch (action)
  {
    // Browse Mode options
    case NEXT_BTN: 
      [self doChangeCard: [currentCardSet getNextCard] direction:kCATransitionFromRight];
      break;
    case PREV_BTN:
      [self doChangeCard: [currentCardSet getPrevCard] direction:kCATransitionFromLeft];
      break;

    case BURY_BTN:
      knewIt = YES;
    
    case RIGHT_BTN:
      numRight++;
      currentRightStreak++;
      currentWrongStreak = 0;
      [UserHistoryPeer recordResult:lastCard gotItRight:YES knewIt:knewIt];
      [self doChangeCard: [currentCardSet getRandomCard:currentCard.cardId] direction:kCATransitionFromRight];
      break;
      
    case WRONG_BTN:
      numWrong++;
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
  [self doCardBtn:NEXT_BTN];
}

- (IBAction) doPrevCardBtn
{
  [self doCardBtn:PREV_BTN];
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
  modalNavControl.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  [[[appDelegate rootViewController] tabBarController] presentModalViewController:modalNavControl animated:YES];

	[modalNavControl release];
	[doneBtn release];
}

//! Hides the "Tap Here For Answer" overlays and reveals the actionBar
- (IBAction) doRevealMeaningBtn
{
	[cardMeaningBtn setHidden:YES];
	[cardMeaningBtnHint setHidden:YES];
	[cardMeaningBtnHintMini setHidden:YES];
  
	[rightBtn setHidden:NO];
	[wrongBtn setHidden:NO];
  [addBtn setHidden:NO];
  [buryCardBtn setHidden:NO];
  
  [rightBtn setEnabled: YES];
	[wrongBtn setEnabled: YES];	
  [buryCardBtn setEnabled:YES];
  [addBtn setEnabled:YES];

  [[[self cardViewController] delegate] setMeaningRevealed:YES];
  [[self cardViewController] displayMeaningWebView];
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

#pragma mark progressModal

- (IBAction) doShowProgressModalBtn
{
  // Bring up the modal dialog for progress view
	ProgressDetailsViewController *progressView = [[ProgressDetailsViewController alloc] initWithNibName:@"ProgressView" bundle:nil];
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

- (IBAction) doDismissProgressModalBtn
{
  // Bring up the modal dialog for progress view
  [progressModalView setHidden:YES];
}

#pragma mark UI updater convenience methods

- (void) updateTheme
{
  NSString* tmpStr = [NSString stringWithFormat:@"/%@theme-cookie-cutters/practice-bg.png",[[ThemeManager sharedThemeManager] currentThemeFileName]];
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

#pragma mark Touch interface methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  startTouchPosition = [touch locationInView:self.view]; 
}

// TODO: make this a delegate method so we know what to do with a swipe
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
  //theme
  [practiceBgImage release];
  
  //kept on this view for now - refactor this too
  [cardSetLabel release];
  [totalWordsLabel release];
 
  //moodicon
  [percentCorrectLabel release];
  [hhAnimationView release];
  [moodIcon release];
  
  // refactor out of here - actionMenu
  [addBtn release];
  [buryCardBtn release];
  [nextCardBtn release];
  [prevCardBtn release];
  [rightBtn release];
  [wrongBtn release];
  
  //progress stuff
  [progressBarView release];
  [progressBarViewController release];
  [progressModalView release];
  [progressModalBtn release];
  [stats release];
  
  //card view stuff
  [cardMeaningBtnHint release];
  [cardMeaningBtnHintMini release];
  [cardViewController release];
  [cardView release];
  
  //state
  [currentCardSet release];
  [currentCard release];
  
	[super dealloc];
}

@end