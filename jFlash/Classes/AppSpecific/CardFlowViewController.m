//
//  CardFlowViewController.m
//  jFlash
//
//  Created by シャロット ロス on 5/25/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "CardFlowViewController.h"

//! Informal protocol defined messages sent to delegate
@interface NSObject (MYBarViewDelegateSupport)

- (void)cardViewDidSetup:(NSNotification *)aNotification;
- (void)cardViewWillSetup:(NSNotification *)aNotification;
- (void)cardViewDidDisplay:(NSNotification *)aNotification;
- (void)cardViewWillDisplay:(NSNotification *)aNotification;

@end

@implementation CardFlowViewController
@synthesize delegate, cardView, moodIcon, practiceBgImage;

- (id) init
{
  if (self = [super init])
  {
    // Set the tab bar controller image png to the targets
    self.tabBarItem.image = [UIImage imageNamed:@"13-target.png"];
    self.title = @"Practice";
  }
  else{
    LWE_LOG(@"Didn't pass super init for CardFlowViewController");
  }
  return self;
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // Show a UIAlert if this is the first time the user has launched the app.
  // TODO - this is not very reusable.
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
  // TODO - do we want these here?
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"setWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"settingsWereChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetHeadword) name:@"directionWasChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStudySet) name:@"userWasChanged" object:nil];
  
  // Create a default mood icon object
  [self setMoodIcon:[[MoodIcon alloc] init]];
  [[self moodIcon] setMoodIconBtn:moodIconBtn];
  [[self moodIcon] setPercentCorrectLabel:percentCorrectLabel];
  
  // Get a new card view which has a default setup
  [self _cardViewWillSetup];
  [self setCardView:[[CardView alloc] init]];
  [self _cardViewDidSetup];
  
  // Setup the action menu
  [self _actionMenuWillAppear];
//  [self setActionMenu:[[CardActionMenu alloc] init]];
  [self _actionMenuDidAppear];
  
  // Setup the progress bar
  
  LWE_LOG(@"END Study View");
}

#pragma mark delegate methods

// Give the delegate a chance to change the card view
- (void)_cardViewWillSetup:(Card*)card
{
  NSNotification *notification;
  
  // add self to the notification so the delegates have access to our stuff
  notification = [NSNotification notificationWithName:CardViewWillSetupNotification object:self];
  
  if([[self delegate] respondsToSelector:@selector(cardViewWillSetup:)])
  {
    [[self delegate] cardViewWillSetup:notification];
  }
  
  // alert the default notification center as well in case something cares
  // got this from the book, not sure if we need to but apparently this is the convention
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

// Give the delegate a chance to change the card view
- (void)_cardViewDidSetup:(Card*)card
{
  NSNotification *notification;
  
  // add self to the notification so the delegates have access to our stuff
  notification = [NSNotification notificationWithName:CardViewDidSetupNotification object:self];
  
  if([[self delegate] respondsToSelector:@selector(cardViewDidSetup:)])
  {
    [[self delegate] cardViewDidSetup:notification];
  }
  
  // alert the default notification center as well in case something cares
  // got this from the book, not sure if we need to but apparently this is the convention
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark theme methods

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


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

NSString  *CardViewDidSetupNotification = @"CardViewDidSetupNotification";
NSString  *CardViewWillSetupNotification = @"CardViewWillSetupNotification";
