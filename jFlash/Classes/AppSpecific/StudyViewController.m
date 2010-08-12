//
//  StudyViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//
#import "StudyViewController.h"

// declare private methods here
@interface StudyViewController()
- (void)_resetStudyView:(BOOL)cardShouldShowExampleView;
- (void)_resetExampleSentencesView:(BOOL)cardShouldShowExampleView;
- (void)_setScrollViewsScrollibility:(BOOL)cardShouldShowExampleView;
- (void)_setPageControlVisibility:(BOOL)cardShouldShowExampleView;
- (BOOL) _cardShouldShowExampleView:(Card*)card;
- (void)_jumpToPage:(int)page;
- (void)_updateCardViewDelegates;
@end

@implementation StudyViewController
@synthesize currentCard, currentCardSet, remainingCardsLabel;
@synthesize progressModalView, progressModalBtn, progressBarViewController, progressBarView;
@synthesize percentCorrectLabel, numRight, numWrong, numViewed, cardSetLabel, percentCorrectVisible, isBrowseMode, hhAnimationView;
@synthesize practiceBgImage, totalWordsLabel, currentRightStreak, currentWrongStreak, moodIcon, cardViewController, cardView;
@synthesize scrollView, pageControl, exampleSentencesViewController;
@synthesize actionBarController, actionbarView, revealCardBtn, tapForAnswerImage;
@synthesize cardViewControllerDelegate;

/** Custom initializer */
- (id) init
{
  self = [super init];
  if (self != nil)
  {
    // Set the tab bar controller image png to the targets
    // TODO: iPad customization?
    self.tabBarItem.image = [UIImage imageNamed:@"13-target.png"];
    self.title = NSLocalizedString(@"Practice",@"StudyViewController.NavBarTitle");
    _alreadyShowedAlertView = NO;
  }
  return self;
}

- (void) viewDidAppear:(BOOL)animated
{
  // Show a UIAlert if this is the first time the user has launched the app.  
  CurrentState *state = [CurrentState sharedCurrentState];
  if (state.isFirstLoad && !_alreadyShowedAlertView)
  {
    _alreadyShowedAlertView = YES;
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Welcome to Japanese Flash!",@"StudyViewController.WelcomeAlertViewTitle")
                                       message:NSLocalizedString(@"We've loaded our favorite word set to get you started.\n\nIf you want to study other sets, tap the 'Study Sets' tab below.",@"RootViewController.WelcomeAlertViewMessage")];
  }
  else if (state.isUpdatable && !_alreadyShowedAlertView)
  {
    _alreadyShowedAlertView = YES;
    [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Welcome to JFlash 1.1!",@"StudyViewController.UpdateAlertViewTitle")
                                       message:NSLocalizedString(@"We need 3-5 minutes of your time to update the dictionary. Your study progress will also be transferred.\n\nA WiFi or 3G network connection is required. Do this now?",@"RootViewController.UpdateAlertViewMessage")
                                            ok:NSLocalizedString(@"Now",@"RootViewController.UpdateAlertViewButton_UpdateNow")
                                        cancel:NSLocalizedString(@"Later",@"RootViewController.UpdateAlertViewButton_UpdateLater")
                                      delegate:self];
  }
}

#pragma mark UIAlertView delegate methods

/** UIAlertView delegate - takes action based on which button was pressed */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex)
  {
    case LWE_ALERT_OK_BTN:
      [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldShowUpdaterModal" object:self userInfo:nil];
      break;
      // Do nothing
    case LWE_ALERT_CANCEL_BTN:
      break;
  }
}

/** Refresh progress bar when view appears */
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // redraw the progress bar
  [self refreshProgressBarView];
}

- (void) viewDidLoad
{
  LWE_LOG(@"START Study View");
  [super viewDidLoad];
  // This is called before drawing the view
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"setWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"settingsWereChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"userWasChanged" object:nil];
  
  // REFACTOR? Responders to only change what is needed, instead of calling the same function for 3 notfications!
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCardView) name:@"directionWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCardView) name:@"themeWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCardView) name:@"readingWasChanged" object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doCardBtn:) name:@"actionBarButtonWasTapped" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginDidInstall:) name:LWEPluginDidInstall object:nil];
  
  // Create a default mood icon object
  [self setMoodIcon:[[MoodIcon alloc] init]];
  [[self moodIcon] setMoodIconBtn:moodIconBtn];
  [[self moodIcon] setPercentCorrectLabel:percentCorrectLabel];
  
  // Set view default states
  [self setPercentCorrectVisible: YES];

  // Initialize the progressBarView
  [self setProgressBarViewController:[[ProgressBarViewController alloc] init]];
  [[self progressBarView] addSubview:progressBarViewController.view];
  
  // Add the CardView to the View
  [self setCardViewController:[[CardViewController alloc] init]];
  [[self cardViewController] setCurrentCard:[self currentCard]];
  [[self cardView] addSubview: [[self cardViewController] view]];  
  
  // Add the Action Bar to the View
  [self setActionBarController:[[ActionBarViewController alloc] init]];
  [[self actionBarController] setCurrentCard:[self currentCard]];
  [[self actionbarView] addSubview:[[self actionBarController] view]];

  // Reset child views
	[self resetStudySet];
  
  [self setupScrollView];
  
  BOOL cardShouldShowExampleView = [self _cardShouldShowExampleView:[self currentCard]];

  // Save value for when we tap "Reveal".
  _cardShouldShowExampleViewCached = cardShouldShowExampleView;

  [self _resetStudyView:cardShouldShowExampleView];
  [self _setPageControlVisibility:cardShouldShowExampleView];
}

#pragma mark -
#pragma mark Convenience methods


/**
 * \brief Changes to a new study set
 * \details Gets the active Tag from the CurrentState singleton and
 * re-initializes the entire StudyViewController to a fresh set.
 * Responsible for getting the first card out of the set and
 * refreshing the views accordingly.
 */
- (void) resetStudySet
{
  // Get active set/tag
  CurrentState *currentStateSingleton = [CurrentState sharedCurrentState];
  [self setCurrentCardSet: [currentStateSingleton activeTag]];
  
  currentRightStreak = 0;
  currentWrongStreak = 0;
  numRight = 0;
  numWrong = 0;
  numViewed = 0;
  
  [percentCorrectLabel setText:percentCorrectLabelStartText];
  [moodIcon updateMoodIcon:100.0f];
  
  [cardSetLabel setText:[NSString stringWithFormat:NSLocalizedString(@"%@",@"StudyViewController.CurrentSetName"),currentCardSet.tagName]];
  
  Card* card = [[currentStateSingleton activeTag] getFirstCard];

  // Would start here with doChangeCard:
  [self setCurrentCard:card];
  
  /* Code from doChangeCard:
            [self setCurrentCard:card];
          [[self cardViewController] setCurrentCard:[self currentCard]];
          [[self cardViewController] setup];
           [[self cardViewController] setCurrentCard:[self currentCard]];
           [[self cardViewController] setup];
  
          BOOL cardShouldShowExampleView = [self _cardShouldShowExampleView:card];
          [self _resetStudyView:cardShouldShowExampleView];
           BOOL cardShouldShowExampleView = [self _cardShouldShowExampleView:[self currentCard]];
           [self _resetStudyView:cardShouldShowExampleView];
  
  // Save value for when we tap "Reveal".
  _cardShouldShowExampleViewCached = cardShouldShowExampleView;
  
          [LWEViewAnimationUtils doViewTransition:(NSString *)kCATransitionPush direction:(NSString *)direction duration:(float)0.15f objectToTransition:(UIViewController *)self];
  
          [self refreshProgressBarView];
  */
  
  /* Refresh Card View 
  [self _updateCardViewDelegates];
  [self updateTheme];
  
  LWE_LOG(@"Calling prepareView on cardView FROM refreshCardView");
  
  */
  
  LWE_LOG(@"Calling refreshCardView FROM resetStudySet");
  [self refreshCardView];
  
  //tells the progress bar to redraw
  [self refreshProgressBarView];
}

/**
 * Sets up all of the delegates and sub-controllers of the study view controller.
 * \param cardShouldShowExampleView YES if the scroll view should have 2 pages, and if the page control should be on.
 *  Note that even if this is YES, you may not be able to scroll depending on whether or not the card has been revealed.
 */
- (void) _resetStudyView:(BOOL)cardShouldShowExampleView
{
  //reset to the first page just in case
  [self _jumpToPage:0];
  
  [[self actionBarController] setCurrentCard:[self currentCard]];
  [actionBarController setup];
  
  [self _resetExampleSentencesView:cardShouldShowExampleView];
  
  // TODO: refactor this out to a StudyViewControllerBrowseModeDelegate
  // update the remaining cards label
  if(isBrowseMode)
  {
    if(percentCorrectVisible) [self doTogglePercentCorrectBtn];
    [[self tapForAnswerImage] setHidden:YES];
    [[self revealCardBtn] setHidden:YES];
    [remainingCardsLabel setText:[NSString stringWithFormat:@"%d / %d",[currentCardSet currentIndex]+1, [currentCardSet cardCount]]];
  }
  else	
  {
    [scrollView setScrollEnabled:NO];
    [[self tapForAnswerImage] setHidden:NO];
    [[self revealCardBtn] setHidden:NO];
    [remainingCardsLabel setText:[NSString stringWithFormat:@"%d / %d", [[[currentCardSet cardLevelCounts] objectAtIndex:0] intValue], [currentCardSet cardCount]]];
    if(!percentCorrectVisible)
    {
      [self doTogglePercentCorrectBtn];
    }
  }
}


/** 
 * Convenience method
 * Both page controller visibility setter and scroll view
 * enabler call this.  In the future, we don't want to 
 * hit the DB twice like we are now for the same card.
 */
- (BOOL) _cardShouldShowExampleView:(Card*)card
{
  BOOL cardShouldShowExampleView = YES;
  
  // First, check if they have the plugin installed
  if ([[[CurrentState sharedCurrentState] pluginMgr] pluginIsLoaded:EXAMPLE_DB_KEY])
  {
    // Get plugin version
    BOOL isNewVersion = NO;
    PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
    if ([[pm versionForLoadedPlugin:EXAMPLE_DB_KEY] isEqualToString:@"1.2"])
    {
      isNewVersion = YES;
    }
    cardShouldShowExampleView = [card hasExampleSentences:isNewVersion];
  }
  
  return cardShouldShowExampleView;
}

//! Checks if there are no example sentences on this card (hides page control & locks scrolling)
- (void) _setPageControlVisibility:(BOOL)cardShouldShowExampleView
{
  [[self pageControl] setHidden:!cardShouldShowExampleView];
}

//! Controls whether the scroll view should be allowed to scroll or not
- (void) _setScrollViewsScrollibility:(BOOL)cardShouldShowExampleView
{
  scrollView.pagingEnabled = cardShouldShowExampleView;
  scrollView.scrollEnabled = cardShouldShowExampleView;
}

/**
 * Re-locks the scrolling to NO (before REVEAL) and calls setup on the ExampleSentencesViewController
 * \param cardShouldShowExampleView if YES, the page control will be visible
 */
- (void) _resetExampleSentencesView:(BOOL)cardShouldShowExampleView
{
  // This should always be no because scroll cannot be done when card is not revealed
  [self _setScrollViewsScrollibility:NO];
  [self _setPageControlVisibility:cardShouldShowExampleView];
  // TODO: remove the warning in 1.3
  if ([[self exampleSentencesViewController] respondsToSelector:@selector(setup)])
  {
    [[self exampleSentencesViewController] setup];
  }
}

- (void) _updateCardViewDelegates
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  if ([self cardViewControllerDelegate] != nil)
  {
    [self.cardViewControllerDelegate release];
  }
  
  if ([[settings objectForKey:APP_MODE] isEqualToString: SET_MODE_BROWSE])
  {
    self.isBrowseMode = YES;
    [self setCardViewControllerDelegate:[[BrowseModeCardViewDelegate alloc] init]];
  }
  else
  {
    self.isBrowseMode = NO;
    [self setCardViewControllerDelegate:[[PracticeModeCardViewDelegate alloc] init]];
  }
  [cardViewController setDelegate:[self cardViewControllerDelegate]];
  [actionBarController setDelegate:[self cardViewControllerDelegate]];
}


/** Resets the study view without getting a new Card */
- (void) refreshCardView
{
  [self _updateCardViewDelegates];
    
  [self updateTheme];
  
  LWE_LOG(@"Calling prepareView on cardView FROM refreshCardView");
  [[self cardViewController] setCurrentCard:[self currentCard]];
	[[self cardViewController] setup];
  
  BOOL cardShouldShowExampleView = [self _cardShouldShowExampleView:[self currentCard]];
  [self _resetStudyView:cardShouldShowExampleView];
}


/** redraws the progress bar with new level details */
- (void) refreshProgressBarView
{
  [progressBarViewController setLevelDetails:[self getLevelDetails]];
  [[self progressBarViewController] drawProgressBar];
}


/** Shows the meaning/reading */
- (void) revealCard
{
  [[self revealCardBtn] setHidden:YES];
  [[self tapForAnswerImage] setHidden:YES];
  [self _setScrollViewsScrollibility:_cardShouldShowExampleViewCached];
  [self _setPageControlVisibility:_cardShouldShowExampleViewCached];
  [cardViewController reveal];
  [actionBarController reveal];
}

#pragma mark Transition Methods

/**
 * \brief Basic method to change cards
 * \param card The Card object to move to
 * \param directionOrNil If direction is a CATransition type, animate.  Otherwise 
 */
- (void) doChangeCard: (Card*) card direction:(NSString*)directionOrNil
{
  if (card != nil)
  {
    [self setCurrentCard:card];
    [[self cardViewController] setCurrentCard:[self currentCard]];
    [[self cardViewController] setup];
    
    BOOL cardShouldShowExampleView = [self _cardShouldShowExampleView:card];
    [self _resetStudyView:cardShouldShowExampleView];

    // Save value for when we tap "Reveal".
    _cardShouldShowExampleViewCached = cardShouldShowExampleView;
    
    // If no direction, don't animate it
    if (directionOrNil != nil)
    {
      [LWEViewAnimationUtils doViewTransition:(NSString *)kCATransitionPush direction:(NSString *)directionOrNil duration:(float)0.15f objectToTransition:(UIViewController *)self];
    }
    
    [self refreshProgressBarView];
    
    //move the scroll view back to the card
    [self _jumpToPage:0];
  }
}

- (void) doCardBtn: (NSNotification *)aNotification
{
  int action = [[aNotification object] intValue];
  
  // Hold on to the last card
  Card* lastCard = nil;
  lastCard = [self currentCard];
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

//! Turns the % correct button on and off, in case it is in the way
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

#pragma mark -
#pragma mark Plugin-Related

/**
 * Connects the "Download Example Sentences" button to actually launch the installer
 * Kind of just a convenience method
 */
- (IBAction) launchExampleInstaller
{
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  NSDictionary *dict = [[pm availablePluginsDictionary] objectForKey:EXAMPLE_DB_KEY];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldShowDownloaderModal" object:self userInfo:dict];
}


/** Called by notification when a plugin is installed - if it is Example sentences, handle that */
- (void)pluginDidInstall:(NSNotification *)aNotification
{
  NSDictionary *dict = [aNotification userInfo];
  if ([[dict objectForKey:@"plugin_key"] isEqualToString:EXAMPLE_DB_KEY])
  {
    // Get rid of the old example sentences guy
    [[[self exampleSentencesViewController] view] removeFromSuperview];
    [self setupScrollView];
    
    // This will also reset the cache value for shouldShowExampleView
    [self refreshCardView];
  }
}



#pragma mark -
#pragma mark progressModal

- (IBAction) doShowProgressModalBtn
{
  // Bring up the modal dialog for progress view
  // TODO: iPad customization!
	ProgressDetailsViewController *progressView = [[ProgressDetailsViewController alloc] initWithNibName:@"ProgressView" bundle:nil];
  progressView.levelDetails = [self getLevelDetails];
  progressView.rightStreak = currentRightStreak;
  progressView.wrongStreak = currentWrongStreak;
  progressView.currentStudySet.text = currentCardSet.tagName;
  progressView.cardsRightNow.text = [NSString stringWithFormat:@"%i", numRight];
  progressView.cardsWrongNow.text = [NSString stringWithFormat:@"%i", numWrong];
  progressView.cardsViewedNow.text = [NSString stringWithFormat:@"%i", numViewed];
  [self.navigationController pushViewController:progressView animated:NO];
  [self.view addSubview:progressView.view];
  // No release here because the progressView releases itself later
  // Not exactly sexy code but it is correct - should be refactored - MMA 8/9/2010
}

#pragma mark UI updater convenience methods

/** Changes the background image based on the theme */
- (void) updateTheme
{
  // TODO: iPad customization
  NSString* pathToBGImage = [[ThemeManager sharedThemeManager] elementWithCurrentTheme:@"practice-bg.png"];
  [practiceBgImage setImage:[UIImage imageNamed:pathToBGImage]];

  // Make sure our little friend is OK
  float tmpRatio;
  if (numViewed > 0)
  {
    tmpRatio = 100*((float)numRight / (float)numViewed);
  }
  else
  {
    tmpRatio = 100;
  }
  [moodIcon updateMoodIcon:tmpRatio];
}


/**
 * Returns an array with card counts.  First six elements of the array are the card counts for set levels unseen through 5,
 * the sixth element is the total number of seen cards (levels 1-5)
 */
- (NSMutableArray*) getLevelDetails
{
  // This is a convenience method that alloc's and sets to autorelease!
  NSMutableArray* levelDetails = nil;
  NSNumber *countObject;
  int i;
  float seencount = 0;

  // Crash protection in case we don't have the card level counts yet
  if ([[currentCardSet cardLevelCounts] count] == 6)
  {
    levelDetails = [NSMutableArray arrayWithCapacity:7];
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

#pragma mark -
#pragma mark ScrollView

- (void)setupScrollView
{
	scrollView.delegate = self;
	
//	scrollView.clipsToBounds = YES;
	scrollView.pagingEnabled = YES;
  scrollView.delaysContentTouches = NO;
  scrollView.directionalLockEnabled = YES;
  scrollView.canCancelContentTouches = YES;

	// This stays NO until "reveal" sets it to yes.  Then setupViewForCard will set it to NO again.
  scrollView.scrollEnabled = NO;
  
	NSUInteger views = 2;
	CGFloat cx = scrollView.frame.size.width;
  
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  if ([pm pluginIsLoaded:EXAMPLE_DB_KEY])
  {
    // We have EX db installed
    [self setExampleSentencesViewController: [[ExampleSentencesViewController alloc] init]];
    if ([[self exampleSentencesViewController] respondsToSelector:@selector(setDatasource:)])
    {
      [[self exampleSentencesViewController] setDatasource:self];
    }
  }
  else
  {
    // No example sentence plugin loaded, so show "please download me" view instead
    // TODO: iPad customization
    UIViewController *tmpVC = [[UIViewController alloc] initWithNibName:@"ExamplesUnavailable" bundle:nil];
    [self setExampleSentencesViewController:tmpVC];
    [tmpVC release];
  }
  			
  UIView *sentencesView = [[self exampleSentencesViewController] view];
	CGRect rect = sentencesView.frame;
	rect.origin.x = ((scrollView.frame.size.width - sentencesView.frame.size.width) / 2) + cx;
	rect.origin.y = ((scrollView.frame.size.height - sentencesView.frame.size.height) / 2);
	sentencesView.frame = rect;
  
  // add the new view as a subview for the scroll view to handle
	[scrollView addSubview:sentencesView];
	
	self.pageControl.numberOfPages = views;
	[scrollView setContentSize:CGSizeMake(cx*views, [scrollView bounds].size.height)];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)_scrollView
{
  if (pageControlIsChangingPage) 
  {
    return;
  }
  
	/*
	 *	We switch page at 50% across
	 */
  CGFloat pageWidth = _scrollView.frame.size.width;
  int page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
  pageControl.currentPage = page;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView 
{
  pageControlIsChangingPage = NO;
}

#pragma mark -
#pragma mark PageControl stuff

- (IBAction)changePage:(id)sender animated:(BOOL) animated
{
	//	Change the scroll view
  CGRect frame = scrollView.frame;
  frame.origin.x = frame.size.width * pageControl.currentPage;
  frame.origin.y = 0;
	
  [scrollView scrollRectToVisible:frame animated:animated];
  
	// When the animated scrolling finishings, scrollViewDidEndDecelerating will turn this off
  pageControlIsChangingPage = YES;
}

//* convenience method for have the animated bool defalut to yes for Interface Builder
- (IBAction)changePage:(id)sender
{
  [self changePage:sender animated:YES];
}

//* programatically jump the scrollview to a page, does not animate the scroll
- (void) _jumpToPage:(int)page
{
  [pageControl setCurrentPage: page];
  [self changePage:pageControl animated:NO];
  pageControlIsChangingPage = NO;
}

#pragma mark -
#pragma mark Class plumbing

- (void) viewDidUnload
{
  [super viewDidUnload];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) dealloc
{
  //theme
  [practiceBgImage release];
  
  //kept on this view for now - refactor this too
  [cardSetLabel release];
  [totalWordsLabel release];
 
  //moodicon
  [percentCorrectLabel release];
  [hhAnimationView release];
  [moodIcon release];
  
  //progress stuff
  [progressBarView release];
  [progressBarViewController release];
  [progressModalView release];
  [progressModalBtn release];
  
  //card view stuff
  [cardViewController release];
  [cardView release];
  
  //action bar
  [actionBarController release];
  [actionbarView release];
  [revealCardBtn release];
  [tapForAnswerImage release];
  
  //state
  [currentCardSet release];
  [currentCard release];
  
  //scrollView
  [scrollView release];
  [pageControl release];
  [exampleSentencesViewController release];
  
  // Get rid of cardviewcontroller delegate
  [self setCardViewControllerDelegate:nil];
  
	[super dealloc];
}

@end
