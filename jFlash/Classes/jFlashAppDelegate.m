//  jFlashAppDelegate.m
//  jFlash
//
//  Created by シャロット ロス on 5/4/09.
//  Copyright LONG WEEKEND INC 2009. All rights reserved.

#import "jFlashAppDelegate.h"
#import "ApplicationSettings.h"
#import "StudyViewController.h"
#import "RootViewController.h"
#import "Constants.h"
#import "SplashView.h"

#define PROFILE_SQL_STATEMENTS 1
#if (PROFILE_SQL_STATEMENTS)
  #import "LWESQLDebug.h"
#endif

@implementation jFlashAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{  
  // Seed random generator
  srandomdev();
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // Get app settings singleton
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
    
  // Register listener to switch the tab bar controller when the user selects a new set
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToStudyView) name:@"switchToStudyView" object:nil];
  
  // TODO: find a way to get rid of this here?
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  // Init settings
  [appSettings initializeSettings];
  
  if (![appSettings databaseFileExists])
  {
    if ([appSettings openedDatabase])
    {
      // We are OK to go
      #if (PROFILE_SQL_STATEMENTS)
            NSArray* statements = [[NSArray alloc] initWithObjects:
                                   [NSString stringWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = '%d'",199],
                                   [NSString stringWithFormat:@"SELECT card_id FROM card_tag_link WHERE tag_id = '%d'",199],
                                   [NSString stringWithFormat:@"SELECT l.card_id AS card_id,u.card_level as card_level,u.wrong_count as wrong_count,u.right_count as right_count FROM card_tag_link l, user_history u WHERE u.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d'",199,1],
                                   [NSString stringWithFormat:@"SELECT l.card_id AS card_id,u.card_level as card_level FROM card_tag_link l, user_history u WHERE u.card_id = l.card_id AND l.tag_id = '%d' AND u.user_id = '%d'",199,1],
                                   nil
                                   ];
            [LWESQLDebug profileSQLStatements:statements];
      #endif
            
      // Themed Splash Screen
      if ([[settings objectForKey:APP_SPLASH] isEqualToString: SET_SPLASH_ON])
      {
        NSString* tmpStr = [[NSString alloc] initWithFormat:@"/%@theme-cookie-cutters/Default.png",[ApplicationSettings getThemeName]];
        SplashView *mySplash = [[SplashView alloc] initWithImage:[UIImage imageNamed:tmpStr]];
        [tmpStr release];
        mySplash.animation = SplashViewAnimationFade;
        mySplash.delay = 3;
        mySplash.touchAllowed = YES;
        mySplash.delegate = self;        
        [mySplash startSplash];
        [mySplash release];
      }
    }
    else
    {
      // Could not open DB
    }
  }
  else
  {
    // No DB file copied -- just run open and it will do the copy for us
//    DatabaseLoadingView *dbLoad = [[DatabaseLoadingView alloc] init];
//    [dbLoad startView];
  }
  
  rootViewController = [[RootViewController alloc] init];
	[window addSubview:rootViewController.view];
  [window makeKeyAndVisible];
  
   
  // TODO: handle this in study view controller??
  // Set the first card
//  StudyViewController* studyCtl = [tabBarController.viewControllers objectAtIndex:0];
//  [studyCtl setBootCardId:[settings integerForKey:@"card_id"]];
  
  
  //launch the please rate us
  [Appirater appLaunched];
  [pool release];
}

// Switches active view to study view
- (void) switchToStudyView
{
//   [tabBarController setSelectedIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX]; 
}

// Save all changes to the database, then close it.
- (void)applicationWillTerminate:(UIApplication *)application
{
  // Get current card from StudyViewController
//  StudyViewController* studyCtl = [tabBarController.viewControllers objectAtIndex:STUDY_VIEW_CONTROLLER_TAB_INDEX];

  // Save current card, user, and set, update cache
  ApplicationSettings *appSettings = [ApplicationSettings sharedApplicationSettings];
  
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
//  [settings setInteger:studyCtl.currentCard.cardId forKey:@"card_id"];
  [settings setInteger:appSettings.activeSet.tagId forKey:@"tag_id"];
  [settings setInteger:appSettings.activeSet.currentIndex forKey:@"current_index"];
  [settings setInteger:0 forKey:@"first_load"];
  [settings setInteger:0 forKey:@"app_running"];
  [settings synchronize];
  
  [[appSettings activeSet] saveCardCountCache];
}


- (void)dealloc
{
  // Clear the application settings singleton
  ApplicationSettings* appSettings = [ApplicationSettings sharedApplicationSettings];
  [[appSettings dao] release];
  [appSettings release];
	[rootViewController release];
	[window release];
	[super dealloc];
}

@end