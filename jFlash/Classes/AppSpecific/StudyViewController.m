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
- (void)_resetStudyView;
- (void)_jumpToPage:(int)page;
- (void)_updateCardViewDelegates;
- (void)_resetExampleSentencesView;
@end

@implementation StudyViewController
@synthesize currentCard, currentCardSet, remainingCardsLabel;
@synthesize progressModalView, progressModalBtn, progressBarViewController, progressBarView;
@synthesize percentCorrectLabel, numRight, numWrong, numViewed, cardSetLabel, percentCorrectVisible, isBrowseMode, hhAnimationView;
@synthesize practiceBgImage, totalWordsLabel, currentRightStreak, currentWrongStreak, moodIcon, cardViewController, cardView;
@synthesize scrollView, pageControl, exampleSentencesViewController;
@synthesize actionBarController, actionbarView, revealCardBtn, tapForAnswerImage;

/** Custom initializer */
- (id) init
{
  if (self = [super init])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"13-target.png"];
    self.title = NSLocalizedString(@"Practice",@"StudyViewController.NavBarTitle");
  }
  else{
    LWE_LOG(@"Didn't pass super init for StudyViewController");
  }
  return self;
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
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetHeadword) name:@"directionWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetHeadword) name:@"themeWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"userWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doCardBtn:) name:@"actionBarButtonWasTapped" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginDidInstall:) name:@"pluginDidInstall" object:nil];
  
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
  LWE_LOG(@"CALLING resetStudySet from viewDidLoad");
	[self resetStudySet];
  LWE_LOG(@"END Study View");
  
  [self setupScrollView];
  
  [self _resetStudyView];
}

#pragma mark Convenience methods

- (void) _resetExampleSentencesView
{
  // Default behavior
  [[self pageControl] setHidden:NO];
  scrollView.pagingEnabled = YES;
  scrollView.scrollEnabled = YES;

  // First, check if they have the plugin installed
  if ([[[CurrentState sharedCurrentState] pluginMgr] pluginIsLoaded:EXAMPLE_DB_KEY])
  {
    // Plugin is installed, check if there are no example sentences on this card (hides page control & locks scrolling)
    if(![[self currentCard] hasExampleSentences])
    {
      [[self pageControl] setHidden:YES];
      scrollView.pagingEnabled = NO;
      scrollView.scrollEnabled = NO;
    }
    [[self exampleSentencesViewController] setup];
  }
}


- (void) _resetStudyView
{
  [[self actionBarController] setCurrentCard:[self currentCard]];
  [actionBarController setup];
  
  [self _resetExampleSentencesView];
  
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


/** a little overly complicated but needed to make the headword switch seemless for the user */
- (void) resetHeadword
{
  [self setCurrentCard:[CardPeer retrieveCardByPK:currentCard.cardId]];
  LWE_LOG(@"Calling resetKeepingCurrentCard FROM resetHeadword");
  [self resetKeepingCurrentCard];
}

- (void) _updateCardViewDelegates
{
  id cardViewControllerDelegate;
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  if ([[settings objectForKey:APP_MODE] isEqualToString: SET_MODE_BROWSE])
  {
    self.isBrowseMode = YES;
    cardViewControllerDelegate = [[BrowseModeCardViewDelegate alloc] init];
  }
  else
  {
    self.isBrowseMode = NO;
    cardViewControllerDelegate = [[PracticeModeCardViewDelegate alloc] init];
  }
  [cardViewController setDelegate:cardViewControllerDelegate];
  [actionBarController setDelegate:cardViewControllerDelegate];
}


/** Resets the study view without getting a new Card */
- (void) resetKeepingCurrentCard
{
  [self _updateCardViewDelegates];
    
  [self updateTheme];
  
  LWE_LOG(@"Calling prepareView on cardView FROM resetKeepingCurrentCard");
  [[self cardViewController] setCurrentCard:[self currentCard]];
	[[self cardViewController] setup];
  
  [self _resetStudyView];
}


/** Changes to a new study set */
- (void) resetStudySet
{
  // Get active set/tag
  CurrentState *currentStateSingleton = [CurrentState sharedCurrentState];
  [self setCurrentCardSet: [currentStateSingleton activeTag]];
  
  numRight = 0;
  numWrong = 0;
  numViewed = 0;
  [percentCorrectLabel setText:percentCorrectLabelStartText];
  [moodIcon updateMoodIcon:100.0f];
  
  [cardSetLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Set: %@",@"StudyViewController.CurrentSetName"),currentCardSet.tagName]];
  
  Card* card = [[currentStateSingleton activeTag] getFirstCard];
  [self setCurrentCard:card];
  
  LWE_LOG(@"Calling resetKeepingCurrentCard FROM resetStudySet");
  [self resetKeepingCurrentCard];
  
  //tells the progress bar to redraw
  [self refreshProgressBarView];
}


/** redraws the progress bar with new level details */
- (void) refreshProgressBarView
{
  [progressBarViewController setLevelDetails: [self getLevelDetails]];
  [[self progressBarViewController] drawProgressBar];
}


/** Shows the meaning/reading */
- (void) revealCard
{
  [[self revealCardBtn] setHidden:YES];
  [[self tapForAnswerImage] setHidden:YES];
  [scrollView setScrollEnabled:YES];
  [cardViewController reveal];
  [actionBarController reveal];
}

#pragma mark Transition Methods

/** Basic method to change cards */
- (void) doChangeCard: (Card*) card direction:(NSString*)direction
{
  if (card != nil)
  {
    [self setCurrentCard:card];
    [[self cardViewController] setCurrentCard:[self currentCard]];
    LWE_LOG(@"Calling prepareView FROM doChangeCard");
    [[self cardViewController] setup];
    
    [self _resetStudyView];
    
    [LWEViewAnimationUtils doViewTransition:(NSString *)kCATransitionPush direction:(NSString *)direction duration:(float)0.15f objectToTransition:(UIViewController *)self];
    
    [self refreshProgressBarView];
    
    //move the scroll view back to the card
    [self _jumpToPage:0];
  }
}

# pragma mark IBOutlet Button Actions

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
    // Get rid of our "please download me" view
    [[[scrollView subviews] objectAtIndex:1] removeFromSuperview];
    [self setupScrollView];
  }
}



#pragma mark -
#pragma mark progressModal

- (IBAction) doShowProgressModalBtn
{
  // Bring up the modal dialog for progress view
	ProgressDetailsViewController *progressView = [[ProgressDetailsViewController alloc] initWithNibName:@"ProgressView" bundle:nil];
  progressView.rightStreak = currentRightStreak;
  progressView.wrongStreak = currentWrongStreak;
  progressView.levelDetails = [self getLevelDetails];
  
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

#pragma mark UI updater convenience methods

/** Changes the background image based on the theme */
- (void) updateTheme
{
  NSString* pathToBGImage = [[ThemeManager sharedThemeManager] elementWithCurrentTheme:@"practice-bg.png"];
  [practiceBgImage setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:pathToBGImage]]];

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
  float seencount;

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
  
	[scrollView setCanCancelContentTouches:NO];
	
	scrollView.clipsToBounds = YES;
	scrollView.pagingEnabled = YES;

	// This stays NO until "reveal" sets it to yes.  Then setupViewForCard will set it to NO again.
  scrollView.scrollEnabled = NO;
  
	NSUInteger views = 2;
	CGFloat cx = scrollView.frame.size.width;
  
  if ([[[CurrentState sharedCurrentState] pluginMgr] pluginIsLoaded:EXAMPLE_DB_KEY])
  {
    [self setExampleSentencesViewController: [[ExampleSentencesViewController alloc] init]];
    [[self exampleSentencesViewController] setDatasource:self];
  }
  else
  {
    // No example sentence plugin loaded, so show "please download me" view instead
    [self setExampleSentencesViewController:[[UIViewController alloc] initWithNibName:@"ExamplesUnavailable" bundle:nil]];
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

#pragma mark UIScrollViewDelegate stuff

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
	/*
	*	Change the scroll view
	*/  
  CGRect frame = scrollView.frame;
  frame.origin.x = frame.size.width * pageControl.currentPage;
  frame.origin.y = 0;
	
  [scrollView scrollRectToVisible:frame animated:animated];
  
	/*
	 *	When the animated scrolling finishings, scrollViewDidEndDecelerating will turn this off
	 */
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
}

#pragma mark -
#pragma mark Class plumbing

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
  
	[super dealloc];
}

@end