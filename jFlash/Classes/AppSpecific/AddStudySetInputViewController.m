//
//  AddStudySetInputViewController.m
//  jFlash
//
//  Created by シャロット ロス on 7/2/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "AddStudySetInputViewController.h"
#import "TagPeer.h"

@implementation AddStudySetInputViewController

@synthesize ownerId, defaultCardId, setNameTextfield;

/**
 * Custom initializer for AddStudySet modal
 * \param cardId If not 0, this cardId will be added to the membership of the newly-created Tag
 * \param groupOwnerId Specifies which group this Tag will belong to.  For top-level, this is zero.
 */
- (id) initWithDefaultCardId:(NSInteger)cardId groupOwnerId:(NSInteger)groupOwnerId
{
  // TODO: iPad customization!
  if ((self = [super initWithNibName:@"ModalInputView" bundle:nil]))
  {
    self.defaultCardId = cardId;
    self.ownerId = groupOwnerId;
  }
  return self;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = NSLocalizedString(@"Create Study Set",@"AddStudySetInputViewController.NavBarTitle");

  [setNameTextfield becomeFirstResponder];
  setNameTextfield.returnKeyType = UIReturnKeyDone;
  setNameTextfield.autocapitalizationType = UITextAutocapitalizationTypeWords;
  setNameTextfield.backgroundColor = [UIColor clearColor];
  setNameTextfield.borderStyle = UITextBorderStyleRoundedRect;
  
  UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewControllerAnimated:)];
  self.navigationItem.leftBarButtonItem = cancelButton;
  [cancelButton release];
}


- (void)viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
  if([theTextField.text length] == 0)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Enter Set Name",@"AddStudySetInputViewController.AlertViewTitle")
                                       message:NSLocalizedString(@"Please enter a new set name or click 'Cancel'.",@"AddStudySetInputViewController.AlertViewMessage")];
    return NO;
  }
  
  // TODO: parameter binding?
  // Escape the string for SQLITE-style escapes (cannot use backslash!)
  NSMutableString* newTag = [[NSMutableString alloc] initWithString:theTextField.text];
  [newTag replaceOccurrencesOfString:@"'" withString:@"''" options:NSLiteralSearch range:NSMakeRange(0, [newTag length])];

  // Create the tag
  int lastTagId = [TagPeer createTag:newTag withOwner:self.ownerId];
  [newTag release];
  
  // If there is a default card, subscribe it
  if (lastTagId > 0 && defaultCardId > 0)
  {
    [TagPeer subscribe:defaultCardId tagId:lastTagId];
    LWE_LOG(@"last row: %d",lastTagId);
  }
  
  [[self parentViewController] dismissModalViewControllerAnimated:YES];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"setAddedToView" object:self];
 
  return YES;
}

@end