//
//  StudyViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//

#import "jFlashAppDelegate.h"
#import "StudySetViewController.h"
#import "StudyViewController.h"
#import "SettingsViewController.h"
#import "LWENetworkUtils.h"
#import "RootViewController.h"
#import "AddTagViewController.h"

@interface StudyViewController()
//private properties
@property (nonatomic, assign, getter=hasfinishedSetAlertShowed) BOOL finishedSetAlertShowed;
@property (nonatomic, assign, getter=hasViewBeenLoadedOnce) BOOL viewHasBeenLoadedOnce;
@property (nonatomic, retain) ProgressDetailsViewController *progressVC;
//private methods
- (void) _notifyUserStudySetHasBeenLearned;
- (void) _applicationDidEnterBackground:(NSNotification*)notification;
- (BOOL) _shouldShowExampleViewForCard:(Card*)card;
- (void) _setupViewWithCard:(Card*)card;
- (void) _setCardViewDelegateBasedOnMode;
- (void) _refreshProgressBarView;
- (void) _tagContentDidChange:(NSNotification*)notification;
- (NSMutableArray*) _getLevelDetails;
- (void) _setupScrollView;
- (void) _setupViewAfterSettingsChange;
- (void) _setupViewAfterUserOrTagChange;
@end

@implementation StudyViewController
@synthesize currentCard, currentCardSet, remainingCardsLabel;
@synthesize progressModalView, progressModalBtn, progressBarViewController, progressBarView;
@synthesize percentCorrectLabel, numRight, numWrong, numViewed, cardSetLabel, hhAnimationView;
@synthesize practiceBgImage, totalWordsLabel, currentRightStreak, currentWrongStreak, moodIcon, cardViewController, cardView;
@synthesize scrollView, pageControl, exampleSentencesViewController, moodIconBtn, percentCorrectTalkBubble, showProgressModalBtn;
@synthesize actionBarController, actionbarView, revealCardBtn, tapForAnswerImage;
@synthesize cardViewControllerDelegate;
@synthesize finishedSetAlertShowed = _finishedSetAlertShowed;
@synthesize viewHasBeenLoadedOnce = _viewHasBeenLoadedOnce;
@synthesize progressVC = _progressVC;

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

    self.finishedSetAlertShowed = NO;
    self.viewHasBeenLoadedOnce = NO;
  }
  return self;
}

#pragma mark - UIView Delegate Methods

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
    
#if defined (LWE_JFLASH)
    [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Welcome to Japanese Flash!",@"StudyViewController.WelcomeAlertViewTitle")
                                       message:NSLocalizedString(@"We've loaded our favorite word set to get you started.\n\nIf you want to study other sets, tap the 'Study Sets' tab below.\n\nIf you like Japanese Flash, also checkout Rikai Browser: Read Japanese on the Web.",@"RootViewController.WelcomeAlertViewMessage")
                                            ok:NSLocalizedString(@"OK", @"StudyViewController.OK")
                                        cancel:NSLocalizedString(@"Get Rikai", @"WebViewController.RikaiAppStore")
                                      delegate:self];
#elif (LWE_CFLASH)
    [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Welcome to Chinese Flash!",@"StudyViewController.WelcomeAlertViewTitle")
                                       message:NSLocalizedString(@"We've loaded our favorite word set to get you started.\n\nIf you want to study other sets, tap the 'Study Sets' tab below.",@"RootViewController.WelcomeAlertViewMessage")
                                            ok:NSLocalizedString(@"OK", @"StudyViewController.OK")
                                        cancel:nil
                                      delegate:self];
#endif
  }
}

/**
 * This method sets up all of the non-nib stuff.
 * Observers are added for settings changes, plugins, etc.
 */
- (void) viewDidLoad
{
  [super viewDidLoad];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_setupViewAfterUserOrTagChange) name:LWEActiveTagDidChange object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_setupViewAfterUserOrTagChange) name:LWEUserSettingsChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_setupViewAfterSettingsChange) name:LWECardSettingsChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doCardBtn:) name:@"actionBarButtonWasTapped" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginDidInstall:) name:LWEPluginDidInstall object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tagContentDidChange:) name:LWETagContentDidChange object:nil];
  
  // iOS4+ only.  On iOS3, when the app is terminated.
  if (UIApplicationDidEnterBackgroundNotification != NULL)
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
  }
  else
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground:) name:UIApplicationWillTerminateNotification object:nil];
  }
  
  // Create a default mood icon object
  self.moodIcon = [[[MoodIcon alloc] init] autorelease];
  self.moodIcon.moodIconBtn = self.moodIconBtn;
  self.moodIcon.percentCorrectLabel = self.percentCorrectLabel;
  
  // Initialize the progressBarView
	ProgressBarViewController *tmpPBVC = [[ProgressBarViewController alloc] init];
  [self.progressBarView addSubview:tmpPBVC.view];
  self.progressBarViewController = tmpPBVC;
	[tmpPBVC release];
  
  // Add the CardView to the View
	CardViewController *tmpCVC = [[CardViewController alloc] init];
  tmpCVC.currentCard = self.currentCard;
  [self.cardView addSubview:tmpCVC.view];
  self.cardViewController = tmpCVC;
	[tmpCVC release];
  
  // Add the Action Bar to the View
	ActionBarViewController *tmpABVC = [[ActionBarViewController alloc] init];
  tmpABVC.currentCard = self.currentCard;
  [self.actionbarView addSubview:tmpABVC.view];
  self.actionBarController = tmpABVC;
	[tmpABVC release];

  // Initialize the scroll view
  [self _setupScrollView];

  //make sure that this section is only run once. If somehow the memory warning is issued 
  //and this view controller's view gets unloaded and loaded again, please dont messed up with the
  //boolean for the 'finished' alert view.
  if (!self.hasViewBeenLoadedOnce)
  {
    //Comment this out if it is decided to show the 'finished-set' alert when the user run this app.
    self.finishedSetAlertShowed = YES;
    self.viewHasBeenLoadedOnce = YES;
  }
  
  // Load the active study set and be done!!
  [self resetStudySet];
}

#pragma mark - UIAlertView delegate method

// private helper method to launch the app store
-(void) _openLinkshareURL
{
  LWENetworkUtils *tmpNet = [[LWENetworkUtils alloc] init];
  [tmpNet followLinkshareURL:@"http://click.linksynergy.com/fs-bin/stat?id=qGx1VSppku4&offerid=146261&type=3&subid=0&tmpid=1826&RD_PARM1=http%253A%252F%252Fitunes.apple.com%252Fus%252Fapp%252Fid380853144%253Fmt%253D8%2526uo%253D4%2526partnerId%253D30&u1=JFLASH_APP_WELCOME_MESSAGE"];
  [tmpNet release];
}

/**
 * We prompt users to get Rikai if it is JFlash.
 * This is the delegate method to handle the response of what the user taps.
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  NSUInteger tag = [alertView tag];
  if (tag == STUDY_SET_HAS_FINISHED_ALERT_TAG)
  {
    switch (buttonIndex)
    {
      case STUDY_SET_SHOW_BURIED_IDX:
        LWE_LOG(@"Study set show burried has been selected after a study set has been master.");
        break;
      case STUDY_SET_CHANGE_SET_IDX:
        LWE_LOG(@"Study set change set has been decided after a study set has been master.");
        [[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowStudySetView object:self userInfo:nil];
        break;
    }
  }
  else
  {
    switch (buttonIndex)
    {
      case LWE_ALERT_CANCEL_BTN: // not really a cancel button, just button two
        [self _openLinkshareURL];
        break;
    }
  }
}

#pragma mark - Study set has been learnt.

- (void)_notifyUserStudySetHasBeenLearned
{
  if (self.hasfinishedSetAlertShowed == NO)
  {
    UIAlertView *alertView = [[UIAlertView alloc] 
                            initWithTitle:@"Study Set Learned" 
                            message:@"Congratulations! You've already learned this set. We will show cards that would usually be hidden."
                            delegate:self 
                            cancelButtonTitle:@"Change Set"
                            otherButtonTitles:@"OK", nil];
    
    [alertView setTag:STUDY_SET_HAS_FINISHED_ALERT_TAG];
    [alertView show];
    [alertView release];
    self.finishedSetAlertShowed = YES;
  }
}

#pragma mark - Public methods

/**
 * \brief   Changes to a new study set
 * \details Gets the active Tag from the CurrentState singleton and
 *          re-initializes the entire StudyViewController to a fresh set.
 *          Responsible for getting the first card out of the set and
 *          refreshing the views accordingly.
 */
- (void) resetStudySet
{
  // Initialize all variables
  currentRightStreak = 0;
  currentWrongStreak = 0;
  numRight = 0;
  numWrong = 0;
  numViewed = 0;
  self.percentCorrectLabel.text = percentCorrectLabelStartText;
  [self.moodIcon updateMoodIcon:100.0f];
  
  // Get active set/tag  
  self.currentCardSet = [[CurrentState sharedCurrentState] activeTag];
  self.cardSetLabel.text = self.currentCardSet.tagName;
  
  // Change to new card, by passing nil, there is no animation
  NSError *error = nil;
  Card *nextCard = [self.currentCardSet getFirstCardWithError:&error];
  if ((error.code == kAllBuriedAndHiddenError) && (nextCard.levelId == 5))
  {
    [self _notifyUserStudySetHasBeenLearned];
  }
  else 
  {
    self.finishedSetAlertShowed = NO;
  }
  
  // Use this to set up delegates, show the card, etc
  [self resetViewWithCard:nextCard];
}


/** 
 * \brief Refreshes the study view without getting a new Card or initializing anything
 * \details This is useful when something in the system changes
 * and we need to layout everything again: mode, theme, reading settings,
 * etc etc etc.
 */
- (void) resetViewWithCard:(Card*)card
{
  [self _setCardViewDelegateBasedOnMode];
  
  // Set up background based on theme
  // TODO: iPad customization
  NSString *pathToBGImage = [[ThemeManager sharedThemeManager] elementWithCurrentTheme:@"practice-bg.jpg"];
  self.practiceBgImage.image = [UIImage imageNamed:pathToBGImage];
  
  // Update mood icon (is this necessary to do here??)
  CGFloat tmpRatio = 0;
  if (numViewed > 0)
  {
    tmpRatio = 100*((CGFloat)numRight / (CGFloat)numViewed);
  }
  else
  {
    tmpRatio = 100;
  }
  [self.moodIcon updateMoodIcon:tmpRatio];
  
  // Finally display the card
  [self doChangeCard:card direction:nil];
}


/**
 * \brief Basic method to change cards
 * \param card The Card object to move to
 * \param directionOrNil If direction is a CATransition type, animate
 */
- (void) doChangeCard:(Card*)card direction:(NSString*)directionOrNil
{
  if (card != nil)
  {
    // Update current card here & on CardViewController
    [self _setupViewWithCard:card];
    self.currentCard = card;
    
    // If no direction, don't animate transition
    if (directionOrNil != nil)
    {
      [LWEViewAnimationUtils doViewTransition:kCATransitionPush direction:directionOrNil duration:0.15f objectToTransition:self];
    }
    
    // Finally, update the progress bar
    [self _refreshProgressBarView];
  }
}

- (void) doCardBtn:(NSNotification *)aNotification
{
  NSInteger action = [[aNotification object] intValue];
  
  // Hold on to the last card in a different variable
  Card *lastCard = [self.currentCard retain];
  
  BOOL knewIt = NO;
  
  Card *nextCard = nil;
  NSString *direction = nil;
  NSError *error = nil;
	switch (action)
  {
    // Browse Mode options
    case NEXT_BTN: 
      nextCard = [self.currentCardSet getNextCard];
      direction = kCATransitionFromRight;
      break;
    case PREV_BTN:
      nextCard = [self.currentCardSet getPrevCard];
      direction = kCATransitionFromLeft;
      break;
      
    case BURY_BTN:
      knewIt = YES;
      
    case RIGHT_BTN:
      numRight++;
      numViewed++;
      currentRightStreak++;
      currentWrongStreak = 0;
      [UserHistoryPeer recordResult:lastCard gotItRight:YES knewIt:knewIt];
      nextCard = [self.currentCardSet getRandomCard:self.currentCard.cardId error:&error];
      direction = kCATransitionFromRight;
      if ((nextCard.levelId == 5) && ([error code] == kAllBuriedAndHiddenError))
      {
        [self _notifyUserStudySetHasBeenLearned];
      }
      break;
      
    case WRONG_BTN:
      numWrong++;
      numViewed++;
      currentWrongStreak++;
      currentRightStreak = 0;
      self.finishedSetAlertShowed = NO;
      [UserHistoryPeer recordResult:lastCard gotItRight:NO knewIt:NO];
      nextCard = [self.currentCardSet getRandomCard:self.currentCard.cardId error:&error];
      direction = kCATransitionFromRight;
      break;      
  }
  [self doChangeCard:nextCard direction:direction];
  
  // Update the speech bubble
  float tmpRatio = 100*((float)numRight / (float)numViewed);
  [self.moodIcon updateMoodIcon:tmpRatio];
  
  // Releases
  [lastCard release];
}

- (void) turnPercentCorrectOff
{
  self.percentCorrectTalkBubble.hidden = YES;
  self.percentCorrectLabel.hidden = YES;
}

- (void) turnPercentCorrectOn
{
  self.percentCorrectTalkBubble.hidden = NO;
  self.percentCorrectLabel.hidden = NO;
}

/**
 * Turns the % correct button on and off, in case it is in the way of the meaning
 */
- (IBAction) doTogglePercentCorrectBtn
{
  // Hide the percentage talk bubble on click; use its current state to check which we should do.
  if (self.percentCorrectTalkBubble.hidden == YES)
  {
    [self turnPercentCorrectOn];
  }
  else
  {
    [self turnPercentCorrectOff];
  }
}

/**
 * Called when the user tapps the progress bar at the top of the practice view
 * Launches the progress modal view in ProgressDetailsViewController
 */
- (IBAction)doShowProgressModalBtn
{
  // Bring up the modal dialog for progress view
  // TODO: iPad customization!
  if (!self.progressVC)
  {
    ProgressDetailsViewController *progressView = [[ProgressDetailsViewController alloc] initWithNibName:@"ProgressView" bundle:nil];
    self.progressVC = progressView;
    [progressView release];
  }
  self.progressVC.levelDetails = [self _getLevelDetails];
  self.progressVC.rightStreak = currentRightStreak;
  self.progressVC.wrongStreak = currentWrongStreak;
  self.progressVC.currentStudySet.text = currentCardSet.tagName;
  self.progressVC.cardsRightNow.text = [NSString stringWithFormat:@"%i", numRight];
  self.progressVC.cardsWrongNow.text = [NSString stringWithFormat:@"%i", numWrong];
  self.progressVC.cardsViewedNow.text = [NSString stringWithFormat:@"%i", numViewed];
  self.progressVC.delegate = self;
  
  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.progressVC, @"controller", nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowPopover object:self userInfo:userInfo];
}


/**
 * Target for UIPageControl - allows us to flip between
 * card view and example sentence view
 */
- (IBAction)changePage:(id)sender animated:(BOOL)animated
{
	//	Change the scroll view
  CGRect frame = self.scrollView.frame;
  frame.origin.x = frame.size.width * self.pageControl.currentPage;
  frame.origin.y = 0;
	
  [self.scrollView scrollRectToVisible:frame animated:animated];
  
	// When the animated scrolling finishings, scrollViewDidEndDecelerating will turn this off
  _isChangingPage = YES;
}


//! convenience method for have the animated bool defalut to yes for Interface Builder
- (IBAction)changePage:(id)sender
{
  [self changePage:sender animated:YES];
}


/** Shows the meaning/reading */
- (IBAction) revealCard
{
  self.revealCardBtn.hidden = YES;
  self.tapForAnswerImage.hidden = YES;
  
  [self.cardViewController reveal];
  [self.actionBarController reveal];
  
  // Now update scrollability (page control doesn't change)
  self.scrollView.pagingEnabled = _hasExampleSentences;
  self.scrollView.scrollEnabled = _hasExampleSentences;
}


#pragma mark - Private methods to setup cards (called every transition)

// TODO: PRIME suspect to be converted to a block, this only exists as a notification callback.
- (void) _setupViewAfterSettingsChange
{
	[self resetViewWithCard:self.currentCard];
}

// TODO: PRIME suspect to be converted to a block.
- (void) _setupViewAfterUserOrTagChange
{
  self.finishedSetAlertShowed = NO;
  [self resetStudySet];
}

/**
 * Sets up all of the delegates and sub-controllers of the study view controller.
 */
- (void) _setupViewWithCard:(Card*)card
{
  [self.cardViewController setupWithCard:card];
  [self.actionBarController setupWithCard:card];
  [self.exampleSentencesViewController setupWithCard:card];

  [self.cardViewController refreshSessionDetailsViews:self];
  [self.cardViewController setupViews:self];
  
  // Page control should be shown when we have example sentences
  self.pageControl.hidden = ([self hasExampleSentences] == NO);
  self.pageControl.currentPage = 0;
  [self changePage:self.pageControl animated:NO];
  _isChangingPage = NO;
}

/** 
 * Both page controller visibility setter and scroll view
 * enabler call this.  In the future, we don't want to 
 * hit the DB twice like we are now for the same card.
 */
- (BOOL) _shouldShowExampleViewForCard:(Card*)card
{
  BOOL returnVal = YES;
  if ([[[CurrentState sharedCurrentState] pluginMgr] pluginIsLoaded:EXAMPLE_DB_KEY])
  {
    returnVal = [card hasExampleSentences];
  }
  return returnVal;
}

/**
 * Chooses an appropriate delegate class for CardViewController
 * depending on which mode we are in (BROWSE or STUDY).
 */
- (void) _setCardViewDelegateBasedOnMode
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
	id<CardViewControllerDelegate, ActionBarViewControllerDelegate> cardViewDelegate = nil;
  if ([[settings objectForKey:APP_MODE] isEqualToString:SET_MODE_BROWSE])
  {
		cardViewDelegate = [[BrowseModeCardViewDelegate alloc] init];
  }
  else
  {
		cardViewDelegate = [[PracticeModeCardViewDelegate alloc] init];
  }
	
	//Not increasing retain count.
  self.cardViewController.delegate = cardViewDelegate;
  self.actionBarController.delegate = cardViewDelegate;
  self.cardViewControllerDelegate = cardViewDelegate;
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
  NSNumber *countObject = nil;
  NSInteger i;
  CGFloat seencount = 0;
  
  // Crash protection in case we don't have the card level counts yet
  if ([[self.currentCardSet cardLevelCounts] count] == 6)
  {
    levelDetails = [NSMutableArray arrayWithCapacity:7];
    for (i = 0; i < 6; i++)
    {
      countObject = [[self.currentCardSet cardLevelCounts] objectAtIndex:i];
      [levelDetails addObject:countObject];
      if(i > 0)
        seencount = seencount + [[levelDetails objectAtIndex:i] floatValue];
    }
    [levelDetails addObject:[NSNumber numberWithInt:[self.currentCardSet cardCount]]];  
    [levelDetails addObject:[NSNumber numberWithFloat:seencount]];
  }
  return levelDetails;
}


/** redraws the progress bar with new level details */
- (void) _refreshProgressBarView
{
  self.progressBarViewController.levelDetails = [self _getLevelDetails];
  [self.progressBarViewController drawProgressBar];
}

- (void) _tagContentDidChange:(NSNotification*)notification
{
  // First of all, we don't care if we're not talking about the active set, so quick return otherwise.
  if ([self.currentCardSet isEqual:(Tag*)notification.object] == NO)
  {
    return;
  }
  
  // Next check that we have a valid card to deal with
  Card *theCard = [notification.userInfo objectForKey:LWETagContentDidChangeCardKey];
  if (theCard == nil)
  {
    return;
  }
  // Unfortunately, this new setup isn't perfect yet.  We have a card, but it does NOT have a
  // levelId associated with it, because we retrieved it in a different, far off place that doesn't
  // care about level Ids.  So we need to re-get the card, sadly.  This should still be faster
  // than any other way around the problem... MMA - 18.Oct.2011
  theCard = [CardPeer retrieveCardByPK:theCard.cardId];
  
  NSString *changeType = [notification.userInfo objectForKey:LWETagContentDidChangeTypeKey];
  if ([changeType isEqualToString:LWETagContentCardAdded])
  {
    [self.currentCardSet addCardToActiveSet:theCard];
    [self.cardViewController refreshSessionDetailsViews:self];
  }
  else if ([changeType isEqualToString:LWETagContentCardRemoved])
  {
    [self.currentCardSet removeCardFromActiveSet:theCard];
    if ([theCard isEqual:self.currentCard])
    {
      //Get a new random card?
      NSError *error = nil;
      Card *nextCard = [self.currentCardSet getRandomCard:self.currentCard.cardId error:&error];
      if ((nextCard.levelId == 5) && ([error code] == kAllBuriedAndHiddenError))
      {
        [self _notifyUserStudySetHasBeenLearned];
      }
      [self resetViewWithCard:nextCard];
    }
    else
    {
      //It is smoother to just update the percentage, rather than the need to update the
      //whole view of the cards (the state will be changed as well like meaning label is hidden, etc)
      [self.cardViewController refreshSessionDetailsViews:self];
    }
  }
}

#pragma mark - Plugin-Related

- (BOOL) hasExampleSentences
{
  return [self _shouldShowExampleViewForCard:self.currentCard];
}

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
    [self.exampleSentencesViewController.view removeFromSuperview];
    [self _setupScrollView];
		[self _setupViewAfterSettingsChange];
  }
}

#pragma mark - ProgressDetailsViewDelegate

- (void)progressDetailsViewControllerShouldDismissView:(id)progressDetailsViewController
{
  self.progressVC = nil;
}

#pragma mark - ScrollView Delegate & Page Control stuff

/**
 * Called when a major thing happens (JFlash startup or EX_DB plugin installation)
 * when the fundamental workings of the scroll view may change.
 */
- (void) _setupScrollView
{
  UIViewController *vc = nil;
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  if ([pm pluginIsLoaded:EXAMPLE_DB_KEY])
  {
    // We have EX db installed
    self.exampleSentencesViewController = [[[ExampleSentencesViewController alloc] init] autorelease];
    vc = self.exampleSentencesViewController;
  }
  else
  {
    // No example sentence plugin loaded, so show "please download me" view instead
    // TODO: iPad customization
    vc = [[[UIViewController alloc] initWithNibName:@"ExamplesUnavailable" bundle:nil] autorelease];
  }
  
  // Resize our second view to match our first one
	CGRect rect = vc.view.frame;
	CGFloat cx = self.scrollView.frame.size.width;
	rect.origin.x = ((self.scrollView.frame.size.width - rect.size.width) / 2) + cx;
	rect.origin.y = ((self.scrollView.frame.size.height - rect.size.height) / 2);
	vc.view.frame = rect;
  
  // Set the content size for the width * the number of views
	NSInteger views = 2;
	self.pageControl.numberOfPages = views;
  self.scrollView.contentSize = CGSizeMake(cx * views, self.scrollView.bounds.size.height);
  
  // add the new view as a subview for the scroll view to handle
	[self.scrollView addSubview:vc.view];
}


/**
 * Called whenever the user scrolls; if it is horizontally,
 * determine if it is 50% across, if so, swap the page
 */
- (void)scrollViewDidScroll:(UIScrollView *)_scrollView
{
  // This will be called if we mess with the page control, but we're only interested in swipes so return here
  if (_isChangingPage) 
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
  _isChangingPage = NO;
}

#pragma mark - Class plumbing

/*
* We ask Tag to freeze its current state to a plist so if the app is killed
* while in the background, we can get it back!
*/
- (void) _applicationDidEnterBackground:(NSNotification*)notification
{
  // Only freeze if we have a database
  if ([[[LWEDatabase sharedLWEDatabase] dao] goodConnection])
  {
    // Save current card, user, and set, update cache - study view controller also does some settings stuff independently
    CurrentState *state = [CurrentState sharedCurrentState];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setInteger:self.currentCard.cardId forKey:@"card_id"];
    [settings setInteger:state.activeTag.tagId forKey:@"tag_id"];
    [settings setInteger:state.activeTag.currentIndex forKey:@"current_index"];
    [settings synchronize];
    [[state activeTag] freezeCardIds];
  }
}

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
	self.percentCorrectTalkBubble = nil;
	self.moodIconBtn = nil;
	self.showProgressModalBtn = nil;
	//self.progressModalCloseBtn = nil;
	
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) dealloc
{
  if (self.progressVC)
  {
    [_progressVC release];
  }
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