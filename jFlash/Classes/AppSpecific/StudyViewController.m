//
//  StudyViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.
//

#import "jFlashAppDelegate.h"
#import "CurrentState.h"
#import "SettingsViewController.h"
#import "StudyViewController.h"
#import "LWENetworkUtils.h"
#import "RootViewController.h"
#import "AddTagViewController.h"

@interface StudyViewController()
//private properties
@property (nonatomic, retain) ProgressDetailsViewController *progressVC;
//private methods
- (void) _applicationDidEnterBackground:(NSNotification*)notification;
- (BOOL) _shouldShowExampleViewForCard:(Card*)card;
- (BOOL) _shouldShowSampleAudioButtonForCard:(Card*)card;
- (void) _tagContentDidChange:(NSNotification*)notification;
- (NSMutableArray*) _getLevelDetails;
- (void) _setupScrollView;
- (void)_setupPageControl:(NSInteger)page;
- (void) _setupSubviewsForStudyMode:(NSString*)studyMode;
- (void) _enablePronounceButton:(BOOL)enabled;
- (Card*) _getNextCard:(NSString*)directionOrNil;
- (Card*) _getFirstCardWithError;
@end

@implementation StudyViewController
@synthesize delegate;
@synthesize currentCard, currentCardSet, remainingCardsLabel;
@synthesize progressModalView, progressModalBtn, progressBarViewController, progressBarView;
@synthesize numRight, numWrong, numViewed, cardSetLabel;
@synthesize practiceBgImage, totalWordsLabel, currentRightStreak, currentWrongStreak, cardViewController, cardView;
@synthesize scrollView, pageControl, exampleSentencesViewController, showProgressModalBtn;
@synthesize actionBarController, actionbarView, revealCardBtn, tapForAnswerImage;
@synthesize progressVC = _progressVC;
@synthesize pronounceBtn = pronounceBtn;

#define LWE_EX_SENTENCE_INSTALLER_VIEW_TAG 69

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

#pragma mark - LWEAudioQueue Delegate Methods

- (void)audioQueue:(LWEAudioQueue *)audioQueue didFailLoadingURL:(NSURL *)url error:(NSError *)error
{
  
}

- (void)audioQueue:(LWEAudioQueue *)audioQueue didFailPlayingURL:(NSURL *)url error:(NSError *)error
{
  
}

- (void)audioQueueBeginInterruption:(LWEAudioQueue *)audioQueue
{
  [audioQueue pause];
  [self _enablePronounceButton:YES];
}

- (void)audioQueueFinishInterruption:(LWEAudioQueue *)audioQueue withFlag:(LWEAudioQueueInterruptionFlag)flag
{
  //if the reason of interruption is whether the audio get deallocated
  //or something else happen besides the phone call/other trivia thing which
  //is better to get the audio play again
  if (flag == LWEAudioQueueInterruptionShouldResume)
  {
    [audioQueue play];
    [self _enablePronounceButton:NO];
  }
  else
  {
    [self _enablePronounceButton:YES];
  }
}

- (void)audioQueueDidFinishPlaying:(LWEAudioQueue *)audioQueue
{
  [self _enablePronounceButton:YES];
}

- (void)audioQueueWillStartPlaying:(LWEAudioQueue *)audioQueue
{
  [self _enablePronounceButton:NO];
}

#pragma mark - UIView Delegate Methods

/**
 * On viewDidAppear, show Alert Views if it is first launch
 */
- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  // Show a UIAlert if this is the first time the user has launched the app.  
  CurrentState *state = [CurrentState sharedCurrentState];
  if (state.isFirstLoad && !_alreadyShowedAlertView)
  {
    _alreadyShowedAlertView = YES;
#if defined (LWE_JFLASH)
    [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Welcome to Japanese Flash!",@"StudyViewController.WelcomeAlertViewTitle")
                                       message:NSLocalizedString(@"We've loaded our favorite word set to get you started.\n\nTo study other sets, tap the 'Study Sets' tab below.\n\nLike Japanese Flash? Checkout Rikai Browser: Reading Japanese on your iPhone just got easier!",@"RootViewController.WelcomeAlertViewMessage")
                                            ok:NSLocalizedString(@"Later", @"StudyViewController.Later")
                                        cancel:NSLocalizedString(@"Get Rikai", @"WebViewController.RikaiAppStore")
                                      delegate:self];
#elif (LWE_CFLASH)
    [LWEUIAlertView confirmationAlertWithTitle:NSLocalizedString(@"Welcome to Chinese Flash!",@"StudyViewController.WelcomeAlertViewTitle")
                                       message:NSLocalizedString(@"We've loaded our favorite word set to get you started.\n\nIf you want to study other sets, tap the 'Study Sets' tab below.",@"RootViewController.WelcomeAlertViewMessage")
                                            ok:NSLocalizedString(@"OK", @"StudyViewController.OK")
                                        cancel:nil
                                      delegate:nil];
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
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  __block StudyViewController *blockSelf = self;

  void (^setupViewAfterChangeBlock)(NSNotification*) = ^(NSNotification *notification)
  {
    // TODO: We can get the new tag out of the notification, eliminating a use of a global state singleton (yay) MMA 11.16.2011
    [blockSelf changeStudySetToTag:[[CurrentState sharedCurrentState] activeTag]];
  };

  // Setup block callback for when active tag changes or the user settings changed - resets study set
  [center addObserverForName:LWEActiveTagDidChange object:nil queue:nil usingBlock:setupViewAfterChangeBlock];
  [center addObserverForName:LWEUserSettingsChanged object:nil queue:nil usingBlock:setupViewAfterChangeBlock];
  
  // Reset the current view (but nothing else) if the card settings changed (reading type, et al)
  [center addObserverForName:LWECardSettingsChanged object:nil queue:nil usingBlock:^(NSNotification *notification)
   {
     // Set up background based on theme -- just in case that changed
     // TODO: iPad customization
     NSString *pathToBGImage = [[ThemeManager sharedThemeManager] elementWithCurrentTheme:@"practice-bg.jpg"];
     blockSelf.practiceBgImage.image = [UIImage imageNamed:pathToBGImage];
     
     // TODO: Change this to a separate notification -- when mode changes
     NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
     NSString *studyMode = [settings objectForKey:APP_MODE];
     [blockSelf _setupSubviewsForStudyMode:studyMode];
     
     // Passing nil forgoes any animation and just reloads the card
     [blockSelf doChangeCard:self.currentCard direction:nil];
   }];
  
  [center addObserver:self selector:@selector(doCardBtn:) name:LWEActionBarButtonWasTapped object:nil];
  [center addObserver:self selector:@selector(pluginDidInstall:) name:LWEPluginDidInstall object:nil];
  [center addObserver:self selector:@selector(_tagContentDidChange:) name:LWETagContentDidChange object:nil];
  [center addObserver:self selector:@selector(_applicationDidEnterBackground:) name:UIApplicationWillTerminateNotification object:nil];
  
  // Initialize the progressBarView
	ProgressBarViewController *tmpPBVC = [[ProgressBarViewController alloc] init];
  [self.progressBarView addSubview:tmpPBVC.view];
  self.progressBarViewController = tmpPBVC;
	[tmpPBVC release];

  // Initialize the scroll view
  [self _setupScrollView];
  
  // Choose the background based on the current theme
  // TODO: iPad customization
  NSString *pathToBGImage = [[ThemeManager sharedThemeManager] elementWithCurrentTheme:@"practice-bg.jpg"];
  self.practiceBgImage.image = [UIImage imageNamed:pathToBGImage];
  
  // Load the active study set and be done!!
  [self changeStudySetToTag:[[CurrentState sharedCurrentState] activeTag]];
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
  switch (buttonIndex)
  {
    case LWE_ALERT_CANCEL_BTN: // not really a cancel button, just button two
      [self _openLinkshareURL];
    break;
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
- (void) changeStudySetToTag:(Tag *)newTag
{
  // Initialize all variables
  self.currentRightStreak = 0;
  self.currentWrongStreak = 0;
  self.numRight = 0;
  self.numWrong = 0;
  self.numViewed = 0;
  
  // remove the observer from the previous currentCardSet before getting the new one
  if (self.currentCardSet)
  {
    [self.currentCardSet removeObserver:self forKeyPath:@"tagName"];
  }

  // Get active set/tag & add an observer
  self.currentCardSet = newTag;
  [self.currentCardSet addObserver:self forKeyPath:@"tagName" options:NSKeyValueObservingOptionNew context:NULL];
  
  self.cardSetLabel.text = self.currentCardSet.tagName;
  
  // Change to new card, by passing nil, there is no animation
  Card *nextCard = [self _getFirstCardWithError];
  
  // Use this to set up delegates, show the card, etc
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSString *studyMode = [settings objectForKey:APP_MODE];
  [self _setupSubviewsForStudyMode:studyMode];
  
  // TODO:  Set this class' delegate?  Update the card view controller/action?
  [self doChangeCard:nextCard direction:nil];
}

#pragma mark - KVO Observer Method

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqual:@"tagName"]) 
  {
    self.cardSetLabel.text = [change objectForKey:NSKeyValueChangeNewKey];
  }
  else
  {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)_setupPageControl:(NSInteger)page
{
  if ([self hasExampleSentences] == NO) // can't show the examples if there are none
  {
    page = 0;
    // Page control should be shown when we have example sentences
    self.pageControl.hidden = YES;
    self.scrollView.scrollEnabled = NO;
  }
  else
  {
    self.pageControl.hidden = NO;
    self.scrollView.scrollEnabled = YES;      
  }

  // Show/Hide pronounce button
  if([self hasAudioSample])
  {
    self.pronounceBtn.hidden = NO;
  }
  else
  {
    self.pronounceBtn.hidden = YES;
  }

  self.pageControl.currentPage = page;
  [self changePage:self.pageControl animated:NO];
  _isChangingPage = NO;
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
    // Asks our delegate if it wants to change any of the details of the view (labels, etc)
    // Due to a hack in PracticeModeCardViewDelegate.m, this call MUST be before setupWithCard:.
    LWE_DELEGATE_CALL(@selector(updateStudyViewLabels:), self);

    // Sets up all of the sub-controllers of the study view controller.
    LWE_DELEGATE_CALL(@selector(studyViewWillSetup:),self);
    
    [self.cardViewController setupWithCard:card];
    [self.actionBarController setupWithCard:card];
    [self.exampleSentencesViewController setupWithCard:card];
             
    self.currentCard = card;
    
    [self _setupPageControl:0];
    
    // If no direction, don't animate transition
    if (directionOrNil != nil)
    {
      [LWEViewAnimationUtils doViewTransition:kCATransitionPush direction:directionOrNil duration:0.15f objectToTransition:self];
    }
    
    // Finally, update the progress bar
    self.progressBarViewController.levelDetails = [self _getLevelDetails];
    [self.progressBarViewController drawProgressBar];
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
	switch (action)
  {
    // Browse Mode options
    case NEXT_BTN: 
      direction = kCATransitionFromRight;
      break;
    case PREV_BTN:
      direction = kCATransitionFromLeft;
      break;
      
    case BURY_BTN:
      knewIt = YES;
      
    case RIGHT_BTN:
      self.numRight++;
      self.numViewed++;
      self.currentRightStreak++;
      self.currentWrongStreak = 0;
      [UserHistoryPeer recordResult:lastCard gotItRight:YES knewIt:knewIt];
      direction = kCATransitionFromRight;
      break;
      
    case WRONG_BTN:
      self.numWrong++;
      self.numViewed++;
      self.currentWrongStreak++;
      self.currentRightStreak = 0;
      [UserHistoryPeer recordResult:lastCard gotItRight:NO knewIt:NO];
      direction = kCATransitionFromRight;
      break;      
  }
  nextCard = [self _getNextCard:direction];
  [self doChangeCard:nextCard direction:direction];
  
  // Releases
  [lastCard release];
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
  self.progressVC.cardsRightNow.text = [NSString stringWithFormat:@"%i", self.numRight];
  self.progressVC.cardsWrongNow.text = [NSString stringWithFormat:@"%i", self.numWrong];
  self.progressVC.cardsViewedNow.text = [NSString stringWithFormat:@"%i", self.numViewed];
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
  LWE_DELEGATE_CALL(@selector(studyViewWillReveal:), self);
  
  [self.cardViewController reveal];
  [self.actionBarController reveal];  
}

- (IBAction) pronounceCard:(id)sender
{
  [self.currentCard pronounceWithDelegate:self];
}

- (void) _enablePronounceButton:(BOOL)enabled
{
  self.pronounceBtn.enabled = enabled;
}

#pragma mark - Private methods to setup cards (called every transition)

- (Card*) _getFirstCardWithError
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(getFirstCard:)])
  {
    return [self.delegate getFirstCard:self.currentCardSet];
  }
  return [self.currentCardSet getFirstCardWithError:nil]; // the pattern calls for doing something no matter what
}

- (Card*) _getNextCard:(NSString*)directionOrNil
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(getNextCard:afterCard:direction:)])
  {
    return [self.delegate getNextCard:self.currentCardSet afterCard:self.currentCard direction:(NSString*)directionOrNil];
  }
  return self.currentCard; // just keep the same card if the delegate cannot help us
}

/** 
 * Both page controller visibility setter and scroll view
 * enabler call this.  In the future, we don't want to 
 * hit the DB twice like we are now for the same card.
 */
- (BOOL) _shouldShowExampleViewForCard:(Card*)card
{
  BOOL returnVal = YES;
  if ([CurrentState pluginKeyIsLoaded:EXAMPLE_DB_KEY])
  {
    returnVal = [card hasExampleSentences];
  }
  return returnVal;
}

/** 
 * Show the audio button if there plugin enabled and card has audio sample
 * Cards may have a "pieced together" sample, but Card class will take care of this
 */
- (BOOL) _shouldShowSampleAudioButtonForCard:(Card*)card
{
  BOOL returnVal = NO;
  if ([CurrentState pluginKeyIsLoaded:AUDIO_SAMPLES_KEY])
  {
    returnVal = [card hasAudio];
  }
  return returnVal;
}


/**
 * Returns an array with card counts.  First six elements of the array are the card counts for set levels unseen through 5,
 * the sixth element is the total number of seen cards (levels 1-5)
 */
// REVIEW: Why isn't this method in Tag.m??  Or, the level details I believe are passed to Progress Bar- maybe it should be there?
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
    LWE_DELEGATE_CALL(@selector(updateStudyViewLabels:), self);
  }
  else if ([changeType isEqualToString:LWETagContentCardRemoved])
  {
    [self.currentCardSet removeCardFromActiveSet:theCard];
    if ([theCard isEqual:self.currentCard])
    {
      // Get a new card
      Card *nextCard = [self _getNextCard:nil];
      
      // Change to the new card we just retrieved
      [self doChangeCard:nextCard direction:nil];
    }
    else
    {
      //It is smoother to just update the percentage, rather than the need to update the
      //whole view of the cards (the state will be changed as well like meaning label is hidden, etc)
      LWE_DELEGATE_CALL(@selector(updateStudyViewLabels:), self);
    }
  }
}

- (void) _setupSubviewsForStudyMode:(NSString*)studyMode
{
  // TODO: Ideally this code wouldn't be part of the SVC, then it wouldn't need to (a) retain
  // its delegate, or (b) have specific knowledge of the name of every class/mode that it could be in.
  //=====================================
  // Set up our delegate based on mode
  if ([studyMode isEqualToString:SET_MODE_BROWSE])
  {
		self.delegate = [[[BrowseModeCardViewDelegate alloc] init] autorelease];
  }
  else
  {
		self.delegate = [[[PracticeModeCardViewDelegate alloc] init] autorelease];
  }
  //=====================================
  
  // Add the CardView to the View -- ask the delegate what controller we want
  if (self.delegate && [self.delegate respondsToSelector:@selector(cardViewControllerForStudyView:)])
  {
    // Remove any old view before setting a new one
    if (self.cardViewController)
    {
      [self.cardViewController.view removeFromSuperview];
    }
    
    // Set the new VC
    UIViewController<StudyViewSubcontrollerDelegate> *cardVC = [self.delegate cardViewControllerForStudyView:self];
    [self.cardView addSubview:cardVC.view];
    self.cardViewController = cardVC;
  }
  
  // Add the Action Bar View -- ask the delegate what controller we want
  if (self.delegate && [self.delegate respondsToSelector:@selector(actionBarViewControllerForStudyView:)])
  {
    if (self.actionBarController)
    {
      [self.actionBarController.view removeFromSuperview];
    }
    
    UIViewController<StudyViewSubcontrollerDelegate> *actionVC = [self.delegate actionBarViewControllerForStudyView:self];
    [self.actionbarView addSubview:actionVC.view];
    self.actionBarController = actionVC;
  }
  
  // Now send our new subcontrollers a message telling it we are using it
  [self.cardViewController studyViewModeDidChange:self];
  [self.actionBarController studyViewModeDidChange:self];  
}


#pragma mark - Plugin-Related

- (BOOL) hasExampleSentences
{
#if defined (LWE_JFLASH)
  // JFlash is currently the only code base with example sentences
  return [self _shouldShowExampleViewForCard:self.currentCard];
#else
  return NO;
#endif
}

- (BOOL) hasAudioSample
{
#if defined (LWE_JFLASH)
  // JFlash currently does not have sample audio implemented
  return NO;
#else
  return [self _shouldShowSampleAudioButtonForCard:self.currentCard];
#endif
}


/**
 * Connects the "Download Example Sentences" button to actually launch the installer
 * Kind of just a convenience method
 */
- (IBAction) launchExampleInstaller
{
  PluginManager *pm = [[CurrentState sharedCurrentState] pluginMgr];
  Plugin *exPlugin = [pm.availableForDownloadPlugins objectForKey:EXAMPLE_DB_KEY];
  [[NSNotificationCenter defaultCenter] postNotificationName:LWEShouldShowDownloadModal object:exPlugin userInfo:nil];
}


/** Called by notification when a plugin is installed - if it is Example sentences, handle that */
- (void)pluginDidInstall:(NSNotification *)aNotification
{
  NSDictionary *dict = [aNotification userInfo];
  if ([[dict objectForKey:@"plugin_key"] isEqualToString:EXAMPLE_DB_KEY])
  {
    // Get rid of the old example sentences guy & re-setup the scroll view
    [[self.scrollView viewWithTag:LWE_EX_SENTENCE_INSTALLER_VIEW_TAG] removeFromSuperview];
    [self _setupScrollView];
    
    // Reset the page control (this will automatically call the code to determine if this card has ex sentences)
    [self _setupPageControl:1];
    [self.exampleSentencesViewController setupWithCard:self.currentCard]; // finally setup the example view for the current card
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
  if ([CurrentState pluginKeyIsLoaded:EXAMPLE_DB_KEY])
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
    vc.view.tag = LWE_EX_SENTENCE_INSTALLER_VIEW_TAG;
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
  [super viewDidUnload];
  
	self.progressBarViewController = nil;
	self.cardViewController = nil;
	self.actionBarController = nil;
	self.scrollView = nil;
	self.pageControl = nil;
	self.cardView = nil;
	self.actionbarView = nil;
	self.exampleSentencesViewController = nil;
	self.cardSetLabel = nil;
	self.totalWordsLabel = nil;
	self.revealCardBtn = nil;
	self.tapForAnswerImage = nil;
	self.practiceBgImage = nil;
	self.progressBarView = nil;
	self.progressModalView = nil;
	self.progressModalBtn = nil;
	self.remainingCardsLabel = nil;
	self.showProgressModalBtn = nil;
  self.pronounceBtn = nil;

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.currentCardSet removeObserver:self forKeyPath:@"tagName"];
}

- (void) dealloc
{
  [pronounceBtn release];
  
  if (self.progressVC)
  {
    [_progressVC release];
  }
  //theme
  [practiceBgImage release];
  
  //kept on this view for now - refactor this too
  [cardSetLabel release];
  [totalWordsLabel release];
  
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