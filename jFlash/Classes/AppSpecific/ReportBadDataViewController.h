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

@interface ReportBadDataViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate, UIActionSheetDelegate, UITextFieldDelegate>
{
  IBOutlet UITextView *userMsgInputBox;
  IBOutlet UITextField *issueTypeBox;
  IBOutlet UITextField *userEmailBox;
  IBOutlet UIView *pickerView;
  UIImageView *hotheadImg;
  Card *_badCard;
  NSString *_activeTagName;
  NSInteger _activeTagId;
  NSArray *_issueTypeArray;
  UIBarButtonItem *_cancelButton;
  
  //! Stores user selection of which issue this is
  NSInteger _userSelectedIssueType;
}

- (id) initWithNibName:(NSString*)nibName forBadCard:(Card*)card;
- (IBAction) reportBadDataEventToFlurry;

//! Private method for getting rid of the keyboard for userMsgInputBox
- (void) _resignTextViewKeyboard;
- (IBAction) _hidePickerView;
- (IBAction) _showPickerView;

//! Delegate methods for UITextField
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;

@property (nonatomic, retain) IBOutlet UIView *pickerView;
@property (nonatomic, retain) IBOutlet UITextView *userMsgInputBox;
@property (nonatomic, retain) IBOutlet UITextField *issueTypeBox;
@property (nonatomic, retain) IBOutlet UITextField *userEmailBox;
@property (nonatomic, retain) UIImageView *hotheadImg;

@end
