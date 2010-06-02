//
//  ReportBadDataViewController.h
//  jFlash
//
//  Created by Mark Makdad on 6/1/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlurryAPI.h"
#import "MoodIcon.h"

//! Holds default text for the userMsgInputBox
extern NSString * const RBDVC_USER_TEXT_BOX_DEFAULT;

@interface ReportBadDataViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate, UIActionSheetDelegate, UITextFieldDelegate>
{
  IBOutlet UITextView *userMsgInputBox;   //! Where the user types details about the issue
  IBOutlet UITextField *issueTypeBox;     //! Where the user taps to bring up the picker to select the issue type
  IBOutlet UITextField *userEmailBox;     //! Where the user types their email address
  IBOutlet UIView *pickerView;            //! Combined picker & toolbar view, hidden offscreen usually
  UIImageView *hotheadImg;                //! Hothead image
  Card *_badCard;                         //! Holds the Card object the user selected as bad
  NSString *_activeTagName;
  NSInteger _activeTagId;
  NSArray *_issueTypeArray;               //! Holds all wrong data issue types
  UIBarButtonItem *_cancelButton;         //! Holds the bar button "cancel" instance
  BOOL _pickerCurrentlyVisible;           //! YES when the picker is on the screen
  BOOL _keyboardCurrentlyVisible;         //! YES when the keyboard is on the screen
  
  NSInteger _userSelectedIssueType;       //! Stores user selection of which issue this is
}

//! Customized initializer that takes a bad Card
- (id) initWithNibName:(NSString*)nibName forBadCard:(Card*)card;
- (IBAction) reportBadDataEventToFlurry;

//! Private method for getting rid of the keyboard for userMsgInputBox
- (void) _resignTextViewKeyboard;
//! IBAction - hides the UIView that has the picker & toolbar
- (IBAction) _hidePickerView;
//! IBAction - brings up the UIView that has the picker & toolbar
- (IBAction) _showPickerView;
//! Delegate methods for UITextField
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;

@property (nonatomic, retain) IBOutlet UIView *pickerView;
@property (nonatomic, retain) IBOutlet UITextView *userMsgInputBox;
@property (nonatomic, retain) IBOutlet UITextField *issueTypeBox;
@property (nonatomic, retain) IBOutlet UITextField *userEmailBox;
@property (nonatomic, retain) UIImageView *hotheadImg;

@end
