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

@synthesize ownerId, defaultCard, setNameTextfield;

/**
 * Custom initializer for AddStudySet modal
 * \param cardId If not 0, this cardId will be added to the membership of the newly-created Tag
 * \param groupOwnerId Specifies which group this Tag will belong to.  For top-level, this is zero.
 */
- (id) initWithDefaultCard:(Card*)card groupOwnerId:(NSInteger)groupOwnerId
{
  // TODO: iPad customization!
  if ((self = [super initWithNibName:@"ModalInputView" bundle:nil]))
  {
    self.defaultCard = card;
    self.ownerId = groupOwnerId;
  }
  return self;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = NSLocalizedString(@"Create Study Set",@"AddStudySetInputViewController.NavBarTitle");

  [self.setNameTextfield becomeFirstResponder];
  self.setNameTextfield.returnKeyType = UIReturnKeyDone;
  self.setNameTextfield.autocapitalizationType = UITextAutocapitalizationTypeWords;
  self.setNameTextfield.backgroundColor = [UIColor clearColor];
  self.setNameTextfield.borderStyle = UITextBorderStyleRoundedRect;
  
  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewControllerAnimated:)];
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
  if ([theTextField.text length] == 0)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Enter Set Name",@"AddStudySetInputViewController.AlertViewTitle")
                                       message:NSLocalizedString(@"Please enter a new set name or click 'Cancel'.",@"AddStudySetInputViewController.AlertViewMessage")];
    return NO;
  }
  
  // Create the tag & subscribe the card to it
  Tag *newTag = [TagPeer createTag:theTextField.text withOwner:self.ownerId];
  [TagPeer subscribeCard:self.defaultCard toTag:newTag];
  
  [self.parentViewController dismissModalViewControllerAnimated:YES];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"setAddedToView" object:self];
 
  return YES;
}

- (void) dealloc
{
  [defaultCard release];
  [super dealloc];
}

@end