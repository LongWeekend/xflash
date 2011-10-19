//
//  TweetWordViewController.h
//  jFlash
//
//  Created by Rendy Pranata on 19/07/10.
//  Copyright 2010 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LWETRequestDelegate.h"
#import "LWETDelegates.h"
#import "LWELoadingView.h"

#define JFLASH_TWITTER_CONSUMER_KEY	@"BGDlaaZWdjPo3oPudnIUNA"
#define JFLASH_TWITTER_PRIVATE_KEY	@"1rsNXW8Oqomevvdzk4MvQ62sowLqYNKUQNQ9GgWhU"
#define kMaxChars					132

@class LWETwitterEngine;
@class LWETUser;

/**
 * This View Controller acts like a model, for user to change and have a say of what they are going to
 * tweet in the twitter. Once a model with a root view controller as this view controller shows, it
 * means that the user should already been authenticated. If a user has not been authenticated,
 * whoever calls this will have to go through authentication phase first.
 *
 * It also conforms to LWETRequestDelegate because after all the twitter related request 
 * (Not the authentication phase request) has done (whether it fails, or success) it will report
 * back to this view controller.
 */
@interface TweetWordViewController : UIViewController <LWETRequestDelegate, UITextViewDelegate>
{
	IBOutlet UITextView *tweetTxt;
	IBOutlet UIButton *tweetBtn;
	IBOutlet UILabel *counterLbl;
@private
  LWELoadingView *_loadingView;
	UIBarButtonItem *_cancelBtn;
	UIBarButtonItem *_signOutBtn;
	UIBarButtonItem *_doneBtn;
	LWETwitterEngine *_twitterEngine;
	NSString *_tweetWord;
}

@property (nonatomic, retain) IBOutlet UITextView *tweetTxt;
@property (nonatomic, retain) IBOutlet UIButton *tweetBtn;
@property (nonatomic, retain) IBOutlet UILabel *counterLbl;
@property (nonatomic, retain) LWETwitterEngine *_twitterEngine;
@property (nonatomic, retain) NSString *_tweetWord;

/**
 * Tweet method is an IBAction fired with the "authentication" button
 * and this method will send a tweet request with the twitter engine.
 */
- (IBAction)tweet;

//! Signs the user out of Twitter so they can sign in as a different user.
- (IBAction) signUserOutOfTwitter:(id)sender;
- (void)_resignTextFieldKeyboard;

/**
 * This is the designated initializer, and it asks for nib name for the view, twiter engine that
 * already has a logged on user (authenticated) and what is the initial word to be tweeted.
 */
- (id)initWithNibName:(NSString *)nibName 
		twitterEngine:(LWETwitterEngine *)twitterEngine 
			tweetWord:(NSString *)tweetWord;

@end
