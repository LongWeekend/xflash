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
- (void)_resetActionMenu;
- (void)_jumpToPage:(int)page;
- (void)_updateCardViewDelegates;
@end

@implementation StudyViewController
@synthesize currentCard, currentCardSet, remainingCardsLabel;
@synthesize progressModalView, progressModalBtn, progressBarViewController, progressBarView;
@synthesize percentCorrectLabel, numRight, numWrong, numViewed, cardSetLabel, percentCorrectVisible, isBrowseMode, hhAnimationView;
@synthesize practiceBgImage, totalWordsLabel, currentRightStreak, currentWrongStreak, moodIcon, cardViewController, cardView;
@synthesize scrollView, pageControl;
@synthesize actionBarController, actionbarView, revealCardBtn, tapForAnswerImage;

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
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"userWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doCardBtn:) name:@"actionBarButtonWasTapped" object:nil];
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(revealCard) name:@"actionBarDidRevealNotification" object:nil];
  
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
  
  [self _resetActionMenu];
  
  [self setupScrollView];
}

#pragma mark Convenience methods

- (void) _resetActionMenu
{
  [[self actionBarController] setCurrentCard:[self currentCard]];
  [actionBarController setup];
  
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
    [[self tapForAnswerImage] setHidden:NO];
    [[self revealCardBtn] setHidden:NO];
    [remainingCardsLabel setText:[NSString stringWithFormat:@"%d / %d", [[[currentCardSet cardLevelCounts] objectAtIndex:0] intValue], [currentCardSet cardCount]]];
    if(!percentCorrectVisible)
    {
      [self doTogglePercentCorrectBtn];
    }
  }
}

// a little overly complicated but needed to make the headword switch seemless for the user
- (void) resetHeadword
{
  [self setCurrentCard:[CardPeer retrieveCardByPK:currentCard.cardId]];
  LWE_LOG(@"Calling resetKeepingCurrentCard FROM resetHeadword");
  [self resetKeepingCurrentCard];
}

- (void) _updateCardViewDelegates {
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

//! Resets the study view without getting a new card
- (void) resetKeepingCurrentCard
{
  [self _updateCardViewDelegates];
    
  [self updateTheme];
  
  LWE_LOG(@"Calling prepareView on cardView FROM resetKeepingCurrentCard");
  [[self cardViewController] setCurrentCard:[self currentCard]];
	[[self cardViewController] setup];
  
  [self _resetActionMenu];
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
  [moodIcon updateMoodIcon:100.0f];
  
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

- (void) revealCard
{
  [[self revealCardBtn] setHidden:YES];
  [[self tapForAnswerImage] setHidden:YES];
  [cardViewController reveal];
  [actionBarController reveal];
}

#pragma mark Transition Methods

//! Basic method to change cards
- (void) doChangeCard: (Card*) card direction:(NSString*)direction
{
  if (card != nil)
  {
    [self setCurrentCard:card];
    [[self cardViewController] setCurrentCard:[self currentCard]];
    LWE_LOG(@"Calling prepareView FROM doChangeCard");
    [[self cardViewController] setup];
    
    [self _resetActionMenu];
    
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

- (void) updateTheme
{
  NSString* pathToBGImage = [[ThemeManager sharedThemeManager] elementWithCurrentTheme:@"practice-bg.png"];
  [practiceBgImage setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:pathToBGImage]]];
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

#pragma mark -
#pragma mark ScrollView

- (void)setupScrollView
{
	scrollView.delegate = self;
  
	[scrollView setCanCancelContentTouches:NO];
	
	scrollView.clipsToBounds = YES;
	scrollView.scrollEnabled = YES;
	scrollView.pagingEnabled = YES;
  
	NSUInteger views = 2;
	CGFloat cx = scrollView.frame.size.width;
  
  // TODO: make this the right view for example sentences
  CardViewController *cfv = [[CardViewController alloc] init];
  [cfv setCurrentCard:[self currentCard]];
  UIView *sentencesView = cfv.view;
			
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

- (IBAction)changePage:(id)sender 
{
	/*
	 *	Change the scroll view
	 */
  CGRect frame = scrollView.frame;
  frame.origin.x = frame.size.width * pageControl.currentPage;
  frame.origin.y = 0;
	
  [scrollView scrollRectToVisible:frame animated:YES];
  
	/*
	 *	When the animated scrolling finishings, scrollViewDidEndDecelerating will turn this off
	 */
  pageControlIsChangingPage = YES;
}

-(void) _jumpToPage:(int)page
{
  [pageControl setCurrentPage: page];
  [self changePage:pageControl];
}

#pragma mark -
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
  
	[super dealloc];
}

@end