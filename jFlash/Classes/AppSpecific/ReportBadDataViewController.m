//
//  ReportBadDataViewController.m
//  jFlash
//
//  Created by Mark Makdad on 6/1/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//
#import "ReportBadDataViewController.h"

// TODO: localize this
NSString * const RBDVC_USER_TEXT_BOX_DEFAULT = @"How can we make it Awesome? Ex: \"Change the first kanji to X\"";

/**
 * Allows user to report bad data in the cards to LWE via Flurry event handling
 */
@implementation ReportBadDataViewController

@synthesize issueTypeBox, userMsgInputBox, userEmailBox, pickerView, hotheadImg;

/**
 * Customized initializer to set the card on init
 */
- (id) initWithNibName:(NSString*)nibName forBadCard:(Card*)card
{
  if (self = [super initWithNibName:nibName bundle:nil])
  {
    // Set internal variables
    _badCard = card;
    _pickerCurrentlyVisible = NO;
    _keyboardCurrentlyVisible = NO;
    
    // Current tag is?
    Tag *tmpTag = [[CurrentState sharedCurrentState] activeTag];
    _activeTagName = tmpTag.tagName;
    _activeTagId = tmpTag.tagId;
    
    // Initialize issue type array
    _userSelectedIssueType = 1;
    _issueTypeArray = [[NSArray alloc] initWithObjects:
                      NSLocalizedString(@"Reading or romaji is wrong",@"ReportBadDataViewController.Reasons_WrongReadingOrRomaji"),
                      NSLocalizedString(@"Kanji is wrong",@"ReportBadDataViewController.Reasons_WrongKanji"),
                      NSLocalizedString(@"Card is a duplicate",@"ReportBadDataViewController.Reasons_Duplicate"),
                      NSLocalizedString(@"Not relevant for this set",@"ReportBadDataViewController.Reasons_NotRelevant"),
                      NSLocalizedString(@"Antiquated or dead word",@"ReportBadDataViewController.Reasons_DeadWord"),
                      NSLocalizedString(@"Something else",@"ReportBadDataViewController.Reasons_Other"),nil];
  }
  return self;
}


/**
 * UIView delegate - View did load, so time time to set up picker, the title nav bar & HH Icon
 */
- (void) viewDidLoad
{
  // Now set up other NIB file
  [[NSBundle mainBundle] loadNibNamed:@"LWEToolbarPicker" owner:self options:nil];

  [super viewDidLoad];
  _cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",@"Global.Cancel") style:UIBarButtonItemStylePlain target:self.parentViewController action:@selector(dismissModalViewControllerAnimated:)];
  self.navigationItem.leftBarButtonItem = _cancelButton;
  self.navigationItem.title = NSLocalizedString(@"What's Wrong?",@"ReportBadDataViewController.NavBarTitle");
  
  // Set UITextView to custom initialized text & "placeholder color"
  self.userMsgInputBox.text = RBDVC_USER_TEXT_BOX_DEFAULT;
  self.userMsgInputBox.textColor = [UIColor lightGrayColor];
  
  // Set up stuff for UIPicker animation - moves the picker to just off the screen
  [LWEViewAnimationUtils translateView:self.pickerView byPoint:CGPointMake(0,480) withInterval:1.0];
  
  // Make HH guy and set him up
  [self setHotheadImg:[MoodIcon makeHappyMoodIconView]];
  self.hotheadImg.frame = CGRectMake(250,270,self.hotheadImg.image.size.width,self.hotheadImg.image.size.height);
  [self.view addSubview:self.hotheadImg];
}


//! UIView delegate - View will appear, so tint the title bar accordingly
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}


//! Sends NSDictionary of all data to Flurry as a "userBadDataReport" event
- (IBAction) reportBadDataEventToFlurry
{
  // Just in case
  if (_badCard == nil)
  {
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    return;
  }
  
  // Move the card to an NSDictionary so we can make it portable
  NSDictionary *tmpCard = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:[_badCard cardId]],@"card_id",
                           [_badCard headword],@"headword",
                           [_badCard meaning],@"meaning",
                           [_badCard reading],@"reading",
                           [_badCard romaji],@"romaji",nil];

  // Generate dictionary of user data to send to Flurry
  NSMutableArray *membership = [TagPeer membershipListForCardId:_badCard.cardId];
  NSString *issue = [_issueTypeArray objectAtIndex:_userSelectedIssueType];
  NSDictionary *dataToSend = [NSDictionary dictionaryWithObjectsAndKeys:
                              tmpCard,@"card",
                              [NSNumber numberWithInt:_activeTagId],@"active_tag_id",
                              _activeTagName,@"active_tag_name",
                              issue,@"issue_type",
                              [[self userMsgInputBox] text],@"user_message",
                              [[self userEmailBox] text],@"user_email",
                              membership,@"tag_membership",nil];
  LWE_LOG(@"Generated data dictionary for Flurry - logging event about cardId %d",[_badCard cardId]);
#if defined(APP_STORE_FINAL)
  [FlurryAPI logEvent:@"userBadDataReport" withParameters:dataToSend];
#endif
  [self.parentViewController dismissModalViewControllerAnimated:YES];
}


//! Hides picker by moving it off the screen
-(IBAction) _hidePickerView
{
  [LWEViewAnimationUtils translateView:self.pickerView byPoint:CGPointMake(0,480) withInterval:0.5f];
  _pickerCurrentlyVisible = NO;
}


//! Shows picker by bringing it in from off the screen
-(IBAction) _showPickerView
{	
  if (_keyboardCurrentlyVisible == NO)
  {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, 180);
    pickerView.transform = transform;
    [self.view addSubview:pickerView];
    [UIView commitAnimations];
    _pickerCurrentlyVisible = YES;
  }
}


# pragma mark Delegate methods for UITextField

/** Should edit - if it's the email, say yes, if it's the reason, say no */
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
  if (textField == [self userEmailBox]) return YES;
  else
  {
    // If the user is editing the text user message, and they tap here, get them out
    if (_keyboardCurrentlyVisible)
    {
      [self _resignTextViewKeyboard];
      [self _showPickerView];
    }
    return NO;
  }
}


/** Did edit - if it's the email, scroll the view so we can see the box */
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
  if (textField == [self userEmailBox])
  {
    // Hide the cancel button
    self.navigationItem.leftBarButtonItem = nil;
    // Move the view up so the keyboard doesn't block the input
    [LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,-130) withInterval:0.5f];
    // Let everyone know the keyboard is showing
    _keyboardCurrentlyVisible = YES;
  }
}


/** Should return - hides the keyboard for email */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if (textField == [self userEmailBox])
  {
    [textField resignFirstResponder];
    // Put the cancel button back
    self.navigationItem.leftBarButtonItem = _cancelButton;
    // Now translate the view back
    [LWEViewAnimationUtils translateView:self.view byPoint:CGPointMake(0,0) withInterval:0.5f];
    _keyboardCurrentlyVisible = NO;
  }
  return YES;
}

#pragma mark UITextViewDelegate methods

/** Detects a touch outside of the UITextView to resign the keyboard */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{  
  UITouch *touch = [[event allTouches] anyObject];
  if ([userMsgInputBox isFirstResponder] && [touch view] != userMsgInputBox)
  {
    [self _resignTextViewKeyboard];
  }
  [super touchesBegan:touches withEvent:event];
}


/** Delegate for text view - stops the user from editing when picker is showing */
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
  if (_pickerCurrentlyVisible || _keyboardCurrentlyVisible)
  {
    return NO;
  }
  else
  {
    return YES;
  }
}


/** Delegate for text view - installs a cancel button to cancel the keyboard in the title nav bar */
- (void)textViewDidBeginEditing:(UITextView *)textView
{
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done",@"Global.Done") style:UIBarButtonItemStyleDone target:self action:@selector(_resignTextViewKeyboard)];
  self.navigationItem.rightBarButtonItem = doneButton;
  // Get rid of the cancel button, you can't dismiss the whole view w/ the keyboard still up!
  self.navigationItem.leftBarButtonItem = nil;

  // Mimic placeholder behavior
  if ([textView.text isEqualToString:RBDVC_USER_TEXT_BOX_DEFAULT])
  {
    textView.text = @"";
    textView.textColor = [UIColor blackColor];
  }
  
  // Stop you from showing the picker
  _keyboardCurrentlyVisible = YES;
}


/** Hides text editing keyboard and kills "done" button from title */
- (void) _resignTextViewKeyboard
{
  [userMsgInputBox resignFirstResponder];
  self.navigationItem.rightBarButtonItem = nil;
  // Bring back the cancel button since we killed it
  self.navigationItem.leftBarButtonItem = _cancelButton;

  // Also, mimic placeholder behavior in case text is empty
  if ([self.userMsgInputBox.text isEqualToString:@""])
  {
    self.userMsgInputBox.text = RBDVC_USER_TEXT_BOX_DEFAULT;
    self.userMsgInputBox.textColor = [UIColor lightGrayColor];
  }
  // Allow you to use the picker again
  _keyboardCurrentlyVisible = NO;
}


#pragma mark UIPickerViewDataSource

/** UIPickerView delegate - gets the title of each row from _issueTypeArray */
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
  return [_issueTypeArray objectAtIndex:row];
}


/** UIPickerView delegate - called when the user chooses one item */
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
  _userSelectedIssueType = row;
  self.issueTypeBox.text = [_issueTypeArray objectAtIndex:row];
}


/** UIPickerView delegate - number of pickers - hardcoded to return 1 (issue type) */
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}


/** UIPickerView delegate - what is the width of the picker - hardcoded to 300px */
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
  return 300.0f;
}


/** UIPickerView delegate - what is the height of each row - hardcoded to 40px */
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}


/** UIPickerView delegate - how many rows are in the picker (sourced from _issueTypeArray) */
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
  return [_issueTypeArray count];
}


//! standard dealloc
- (void)dealloc
{
  [super dealloc];
}

@end
