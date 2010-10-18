//
//  StudyViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//

#import "jFlashAppDelegate.h"
#import "StudyViewController.h"
#import "SettingsViewController.h"


// declare private methods here
@interface StudyViewController()
- (void)_setupCardView:(BOOL)cardShouldShowExampleView;
- (void)_setupExampleSentencesView:(BOOL)cardShouldShowExampleView;
- (BOOL)_cardShouldShowExampleView:(Card*)card;
- (void)_setCardViewDelegateBasedOnMode;
- (void)_jumpToPage:(int)page;
- (void)_refreshProgressBarView;
- (NSMutableArray*) _getLevelDetails;
- (void)_setupScrollView;
- (void)_setupView;
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

#pragma mark -
#pragma mark UIView Delegate Methods

/**
 * Refresh progress bar when view appears
 * MMA - WHY?? 8/12/2010
 */
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // redraw the progress bar
  [self _refreshProgressBarView];
}

/**
 * On viewDidAppear, show Alert Views if it is first launch OR after 1.0 upgrade
 */
- (void) viewDidAppear:(BOOL)animated
{
  // Show a UIAlert if this is the first time the user has launched the app.  
  CurrentState *state = [CurrentState sharedCurrentState];
  if (state.isFirstLoad && !_alreadyShowedAlertView)
  {
    _alreadyShowedAlertView = YES;
    // CFLASH STRING CUSTOMIZATION
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Welcome to Japanese Flash!",@"StudyViewController.WelcomeAlertViewTitle")
                                       message:NSLocalizedString(@"We've loaded our favorite word set to get you started.\n\nIf you want to study other sets, tap the 'Study Sets' tab below.",@"RootViewController.WelcomeAlertViewMessage")];
  }
  else if (state.isUpdatable && !_alreadyShowedAlertView)
  {
    _alreadyShowedAlertView = YES;
    [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Welcome to JFlash 1.2!",@"StudyViewController.UpdateAlertViewTitle")
                                       message:NSLocalizedString(@"We need 3-5 minutes of your time to update the dictionary. Your study progress will also be transferred.\n\nA WiFi or 3G network connection is required. Do this now?",@"RootViewController.UpdateAlertViewMessage")
                                            ok:NSLocalizedString(@"Now",@"RootViewController.UpdateAlertViewButton_UpdateNow")
                                        cancel:NSLocalizedString(@"Later",@"RootViewController.UpdateAlertViewButton_UpdateLater")
                                      delegate:self];
  }
}

/**
 * This method sets up all of the non-nib stuff.
 * Observers are added for settings changes, plugins, etc.
 */
- (void) viewDidLoad
{
  [super viewDidLoad];
  // This is called before drawing the view
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"setWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"userWasChanged" object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:LWESettingsChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_setupView) name:LWECardSettingsChanged object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doCardBtn:) name:@"actionBarButtonWasTapped" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginDidInstall:) name:LWEPluginDidInstall object:nil];
  
  // Create a default mood icon object
  MoodIcon *tmpMoodIcon = [[MoodIcon alloc] init];
  [self setMoodIcon:tmpMoodIcon];
  [tmpMoodIcon release];
  
  [self.moodIcon setMoodIconBtn:moodIconBtn];
  [self.moodIcon setPercentCorrectLabel:percentCorrectLabel];
  
  // Set view default states
  [self setPercentCorrectVisible: YES];

  // Initialize the progressBarView
	ProgressBarViewController *tmpPBVC = [[ProgressBarViewController alloc] init];
  [self setProgressBarViewController:tmpPBVC];
  [self.progressBarView addSubview:progressBarViewController.view];
	[tmpPBVC release];
  
  // Add the CardView to the View
	CardViewController *tmpCVC = [[CardViewController alloc] init];
  [tmpCVC setCurrentCard:[self currentCard]];
  [self.cardView addSubview: [tmpCVC view]];  
  [self setCardViewController:tmpCVC];
	[tmpCVC release];
  
  // Add the Action Bar to the View
	ActionBarViewController *tmpABVC = [[ActionBarViewController alloc] init];
  [tmpABVC setCurrentCard:[self currentCard]];
  [self.actionbarView addSubview:[tmpABVC view]];
  [self setActionBarController:tmpABVC];
	[tmpABVC release];

  // Initialize the scroll view
  [self _setupScrollView];

  // Load the active study set and be done!!
  [self resetStudySet];
}

#pragma mark UIAlertView delegate method

/**
 * After 1.0 to 1.1 upgrade, the user will be presented with a UIAlertView to upgrade their DB.
 * This is the delegate method to handle the response of what the user taps (do it now or later)
 */
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

#pragma mark -
#pragma mark Public methods

/**
 * \brief Changes to a new study set
 * \details Gets the active Tag from the CurrentState singleton and
 * re-initializes the entire StudyViewController to a fresh set.
 * Responsible for getting the first card out of the set and
 * refreshing the views accordingly.
 */
- (void) resetStudySet
{
	LWE_LOG(@"In the reset study set");
  // Initialize all variables
  currentRightStreak = 0;
  currentWrongStreak = 0;
  numRight = 0;
  numWrong = 0;
  numViewed = 0;
  [percentCorrectLabel setText:percentCorrectLabelStartText];
  [moodIcon updateMoodIcon:100.0f];
  
  // Get active set/tag
  [self setCurrentCardSet:[[CurrentState sharedCurrentState] activeTag]];
  
  // Set tag & card-specific stuff
  [self.cardSetLabel setText:[NSString stringWithFormat:NSLocalizedString(@"%@",@"StudyViewController.CurrentSetName"),self.currentCardSet.tagName]];
  
  // Use this to set up delegates, etc
  [self refreshCardView];

  // Change to new card, by passing nil, there is no animation
  [self doChangeCard:[[self currentCardSet] getFirstCard] direction:nil];
}


/** 
 * \brief Refreshes the study view without getting a new Card or initializing anything
 * \details This is useful when something in the system changes
 * and we need to layout everything again: mode, theme, reading settings,
 * etc etc etc.
 */
- (void) refreshCardView
{
  [self _setCardViewDelegateBasedOnMode];
  
  // Set up background based on theme
  // TODO: iPad customization
  NSString* pathToBGImage = [[ThemeManager sharedThemeManager] elementWithCurrentTheme:@"practice-bg.png"];
  [practiceBgImage setImage:[UIImage imageNamed:pathToBGImage]];
  
  // Update mood icon (is this necessary to do here??)
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
  
  // Give the card view controller a chance to re-layout the page
	// TODO: Think this again!
	// The refresh call view is called in the "Reset Study Set" method, and the Do Change Card method is called after that, 
	// and this method is called under the doChangeCard as well, shouldnt it be only called once?
	//[[self cardViewController] setup];
  
  // Maybe we need to check if our examples view should be different?
  //BOOL cardShouldShowExampleView = [self _cardShouldShowExampleView:[self currentCard]];
	
	//Why is this run twice? - Rendy 18/8/10
  //[self _setupCardView:cardShouldShowExampleView];
}


/** Shows the meaning/reading */
- (void) revealCard
{
  [[self revealCardBtn] setHidden:YES];
  [[self tapForAnswerImage] setHidden:YES];
  [cardViewController reveal];
  [actionBarController reveal];
  
  // Now update scroll & page control
  scrollView.pagingEnabled = _cardShouldShowExampleViewCached;
  scrollView.scrollEnabled = _cardShouldShowExampleViewCached;
  [[self pageControl] setHidden:!_cardShouldShowExampleViewCached];  
}


/**
 * \brief Basic method to change cards
 * \param card The Card object to move to
 * \param directionOrNil If direction is a CATransition type, animate.  Otherwise 
 */
- (void) doChangeCard: (Card*) card direction:(NSString*)directionOrNil
{
  if (card != nil)
  {
    // Update current card here & on CardViewController
    [self setCurrentCard:card];
    [self.cardViewController setCurrentCard:self.currentCard];
    [self.cardViewController setup];
    
    // Show we show example view here?
		// Save value for when we tap "Reveal".
    _cardShouldShowExampleViewCached = [self _cardShouldShowExampleView:card];
    
    // Now set up the card
    [self _setupCardView:_cardShouldShowExampleViewCached];
    
    // If no direction, don't animate transition
    if (directionOrNil != nil)
    {
      [LWEViewAnimationUtils doViewTransition:(NSString *)kCATransitionPush direction:(NSString *)directionOrNil duration:(float)0.15f objectToTransition:(UIViewController *)self];
    }
    
    // Finally, update the progress bar
    [self _refreshProgressBarView];
  }
}

- (void) doCardBtn: (NSNotification *)aNotification
{
  NSInteger action = [[aNotification object] intValue];
  
  // Hold on to the last card
  Card *lastCard = nil;
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

/**
 * Turns the % correct button on and off, in case it is in the way of the meaning
 */
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

/**
 * Called when the user tapps the progress bar at the top of the practice view
 * Launches the progress modal view in ProgressDetailsViewController
 */
- (IBAction) doShowProgressModalBtn
{
  // Bring up the modal dialog for progress view
  // TODO: iPad customization!
	ProgressDetailsViewController *progressView = [[ProgressDetailsViewController alloc] initWithNibName:@"ProgressView" bundle:nil];
  progressView.levelDetails = [self _getLevelDetails];
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


/**
 * Target for UIPageControl - allows us to flip between
 * card view and example sentence view
 */
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


//! convenience method for have the animated bool defalut to yes for Interface Builder
- (IBAction)changePage:(id)sender
{
  [self changePage:sender animated:YES];
}

#pragma mark -
#pragma mark Private methods to setup cards (called every transition)

/**
 * Sets up back the view after these condition, if the card settings has changed, or if plugin has installed. 
 * This will set up the User Interface to the initial state, with the user preference theme. 
 *
 */
- (void)_setupView
{
	// This will also reset the cache value for shouldShowExampleView
	[self refreshCardView];
	[self.cardViewController setup];
	
	// Maybe we need to check if our examples view should be different?
	BOOL cardShouldShowExampleView = [self _cardShouldShowExampleView:self.currentCard];
	[self _setupCardView:cardShouldShowExampleView];
}

/**
 * Sets up all of the delegates and sub-controllers of the study view controller.
 * \param cardShouldShowExampleView YES if the scroll view should have 2 pages, and if the page control should be on.
 *  Note that even if this is YES, you may not be able to scroll depending on whether or not the card has been revealed.
 */
- (void) _setupCardView:(BOOL)cardShouldShowExampleView
{
  //reset to the first page
  [self _jumpToPage:0];
  
  [self.actionBarController setCurrentCard:[self currentCard]];
  [actionBarController setup];
  
  [self _setupExampleSentencesView:cardShouldShowExampleView];
  
  // TODO: refactor this out to a StudyViewControllerBrowseModeDelegate
  // update the remaining cards label
  if (isBrowseMode)
  {
		if (percentCorrectVisible)
    {
      [self doTogglePercentCorrectBtn];
    }
    [self.tapForAnswerImage setHidden:YES];
    [self.revealCardBtn setHidden:YES];
    [remainingCardsLabel setText:[NSString stringWithFormat:@"%d / %d",[currentCardSet currentIndex]+1, [currentCardSet cardCount]]];
  }
  else	
  {
    [self.scrollView setScrollEnabled:NO];
    [self.tapForAnswerImage setHidden:NO];
    [self.revealCardBtn setHidden:NO];
    [self.remainingCardsLabel setText:[NSString stringWithFormat:@"%d / %d", [[[currentCardSet cardLevelCounts] objectAtIndex:0] intValue], [currentCardSet cardCount]]];
    if (!percentCorrectVisible)
    {
      [self doTogglePercentCorrectBtn];
    }
  }
}


/**
 * Re-locks the scrolling to NO (before REVEAL) and calls setup on the ExampleSentencesViewController
 * \param cardShouldShowExampleView if YES, the page control will be visible
 */
- (void) _setupExampleSentencesView:(BOOL)cardShouldShowExampleView
{
  // This should always be no because scroll cannot be done when card is not revealed
	// However, if it is a browse mode, it should have all of the scroll view enabled? - Rendy 19/8/10
	if (isBrowseMode)
	{
		scrollView.pagingEnabled = YES;
		scrollView.scrollEnabled = YES;
	}
	else 
	{
		scrollView.pagingEnabled = NO;
		scrollView.scrollEnabled = NO;
	}

  // Page control?
  [self.pageControl setHidden:!cardShouldShowExampleView];

  if ([[self exampleSentencesViewController] respondsToSelector:@selector(setup)])
  {
		ExampleSentencesViewController * exControler = (ExampleSentencesViewController *)self.exampleSentencesViewController;
    [exControler setup];
  }
}


/** 
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

/**
 * Chooses an appropriate delegate class for CardViewController
 * depending on which mode we are in (BROWSE or STUDY).
 */
- (void) _setCardViewDelegateBasedOnMode
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
	//TODO: Cache this so that it does not alloc a new object everytime the user changes set
	id cardViewDelegate = nil;
  if ([[settings objectForKey:APP_MODE] isEqualToString: SET_MODE_BROWSE])
  {
    self.isBrowseMode = YES;
		cardViewDelegate = [[BrowseModeCardViewDelegate alloc] init];
  }
  else
  {
    self.isBrowseMode = NO;
		cardViewDelegate = [[PracticeModeCardViewDelegate alloc] init];
  }
	
	//Not increasing retain count.
	[cardViewController setDelegate:cardViewDelegate];
  [actionBarController setDelegate:cardViewDelegate];
	//Will increase the retain count.
	[self setCardViewControllerDelegate:cardViewDelegate];
	[cardViewDelegate release];
}



/**
 * Returns an array with card counts.  First six elements of the array are the card counts for set levels unseen through 5,
 * the sixth element is the total number of seen cards (levels 1-5)
 */
- (NSMutableArray*) _getLevelDetails
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



/** redraws the progress bar with new level details */
- (void) _refreshProgressBarView
{
  [progressBarViewController setLevelDetails:[self _getLevelDetails]];
  [[self progressBarViewController] drawProgressBar];
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
    // Get rid of the old example sentences guy & re-setup the scroll view
    [[self.exampleSentencesViewController view] removeFromSuperview];
    [self _setupScrollView];
		[self _setupView];
  }
}

#pragma mark -
#pragma mark ScrollView Delegate & Page Control stuff

/**
 * Called when a major thing happens (JFlash startup or EX_DB plugin installation)
 * when the fundamental workings of the scroll view may change.
 */
- (void)_setupScrollView
{
	scrollView.delegate = self;
	
  //scrollView.clipsToBounds = YES;
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
		ExampleSentencesViewController *exController = [[ExampleSentencesViewController alloc] init];
		[exController setDatasource:self];
		[self setExampleSentencesViewController: exController];
  }
  else
  {
    // No example sentence plugin loaded, so show "please download me" view instead
    // TODO: iPad customization
    UIViewController *tmpVC = [[UIViewController alloc] initWithNibName:@"ExamplesUnavailable" bundle:nil];
    [self setExampleSentencesViewController:tmpVC];
    [tmpVC release];
  }
  			
  UIView *sentencesView = [self.exampleSentencesViewController view];
	CGRect rect = sentencesView.frame;
	rect.origin.x = ((self.scrollView.frame.size.width - sentencesView.frame.size.width) / 2) + cx;
	rect.origin.y = ((self.scrollView.frame.size.height - sentencesView.frame.size.height) / 2);
	sentencesView.frame = rect;
  
  // add the new view as a subview for the scroll view to handle
	[self.scrollView addSubview:sentencesView];
	
	self.pageControl.numberOfPages = views;
	[self.scrollView setContentSize:CGSizeMake(cx*views, [self.scrollView bounds].size.height)];
}

/** programatically jump the scrollview to a page, does not animate the scroll */
- (void) _jumpToPage:(int)page
{
  [self.pageControl setCurrentPage:page];
  [self changePage:self.pageControl animated:NO];
  pageControlIsChangingPage = NO;
}


/**
 * Called whenever the user scrolls; if it is horizontally,
 * determine if it is 50% across, if so, swap the page
 */
- (void)scrollViewDidScroll:(UIScrollView *)_scrollView
{
  // This will be called if we mess with the page control, but we're only interested in swipes so return here
  if (pageControlIsChangingPage) 
  {
    return;
  }
  
  //	We switch page at 50% across
  CGFloat pageWidth = _scrollView.frame.size.width;
  NSInteger page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
  self.pageControl.currentPage = page;
}

/**
 * Resets the pageControlIsChangingPage property to NO
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView 
{
  pageControlIsChangingPage = NO;
}

#pragma mark -
#pragma mark Class plumbing

- (void) viewDidUnload
{
	LWE_LOG(@"Study View Controller get Unload");
  [super viewDidUnload];
  
  // Create a default mood icon object
	self.moodIcon = nil;
	
	self.progressBarViewController = nil;
	self.cardViewController = nil;
	self.actionBarController = nil;
	
	//RENDY: Is this really important?
	self.scrollView = nil;
	self.pageControl = nil;
	self.cardView = nil;
	self.actionbarView = nil;
	self.exampleSentencesViewController = nil;
	self.cardSetLabel = nil;
	self.totalWordsLabel = nil;
	self.percentCorrectLabel = nil;
	self.revealCardBtn = nil;
	self.tapForAnswerImage = nil;
	self.practiceBgImage = nil;
	self.progressBarView = nil;
	self.hhAnimationView = nil;
	self.progressModalView = nil;
	self.progressModalBtn = nil;
	self.remainingCardsLabel = nil;
	self.cardViewControllerDelegate = nil;
	//self.progressModalCloseBtn = nil;
	//self.percentCorrectTalkBubble = nil;
	//self.moodIconBtn = nil;
	//self.showProgressModalBtn = nil;
	
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
