//
//  TweetWordViewController.h
//  jFlash
//
//  Created by Rendy Pranata on 19/07/10.
//  Copyright 2010 CRUX. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LWETRequestDelegate.h"
#import "LWETDelegates.h"

#define JFLASH_TWITTER_CONSUMER_KEY	@"BGDlaaZWdjPo3oPudnIUNA"
#define JFLASH_TWITTER_PRIVATE_KEY	@"1rsNXW8Oqomevvdzk4MvQ62sowLqYNKUQNQ9GgWhU"
#define kMaxChars					132

@class LWETwitterEngine;
@class LWETUser;

@interface TweetWordViewController : UIViewController 
<LWETRequestDelegate, UITextViewDelegate>
{
	IBOutlet UITextView *tweetTxt;
	IBOutlet UIButton *tweetBtn;
	IBOutlet UILabel *counterLbl;
	
	UIBarButtonItem *_cancelBtn;
	LWETwitterEngine *_twitterEngine;
	NSString *_tweetWord;
}

@property (nonatomic, retain) IBOutlet UITextView *tweetTxt;
@property (nonatomic, retain) IBOutlet UIButton *tweetBtn;
@property (nonatomic, retain) IBOutlet UILabel *counterLbl;

- (IBAction)tweet;

- (void)_resignTextFieldKeyboard;

- (id)initWithNibName:(NSString *)nibName 
		twitterEngine:(LWETwitterEngine *)twitterEngine 
			tweetWord:(NSString *)tweetWord;

@end
