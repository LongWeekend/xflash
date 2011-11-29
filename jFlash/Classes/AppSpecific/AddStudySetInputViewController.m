//
//  AddStudySetInputViewController.m
//  jFlash
//
//  Created by シャロット ロス on 7/2/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

#import "AddStudySetInputViewController.h"
#import "TagPeer.h"
#import <QuartzCore/QuartzCore.h>

@implementation AddStudySetInputViewController

@synthesize ownerId, defaultCard, setNameTextfield, setDescriptionTextView, tag;

NSString * const kSetWasAddedOrUpdated = @"setAddedToView";

/**
 * Custom initializer for AddStudySet modal
 * \param cardId If not 0, this cardId will be added to the membership of the newly-created Tag
 * \param groupOwnerId Specifies which group this Tag will belong to.  For top-level, this is zero.
 */
- (id) initWithDefaultCard:(Card*)card groupOwnerId:(NSInteger)groupOwnerId
{
  // TODO: iPad customization!
  if ((self = [super initWithNibName:@"AddStudySetView" bundle:nil]))
  {
    self.defaultCard = card;
    self.ownerId = groupOwnerId;
  }
  return self;
}

/**
 * Custom init for preexisting studyset to update the info
 */
- (id) initWithTag:(Tag*)aTag
{
  if ((self = [super initWithNibName:@"AddStudySetView" bundle:nil]))
  {
    self.tag = aTag;
  }
  return self;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = NSLocalizedString(@"Create Study Set",@"AddStudySetInputViewController.NavBarTitle");
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(save)];
  self.navigationItem.rightBarButtonItem = doneButton;
  [doneButton release];
  
  if ([self isModal])
  {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
  }
  
  if(self.tag)
  {
    self.title = NSLocalizedString(@"Update Study Set",@"AddStudySetInputViewController.NavBarTitle");
    self.setNameTextfield.text = [tag tagName];
    self.setDescriptionTextView.text = [tag tagDescription];
  }
  
  //Round the corners of the textView
  [self.setDescriptionTextView.layer setBorderColor: [[UIColor grayColor] CGColor]];
  [self.setDescriptionTextView.layer setBorderWidth: 1.0];
  [self.setDescriptionTextView.layer setCornerRadius:8.0f];
  [self.setDescriptionTextView.layer setMasksToBounds:YES];
  
  [self.setNameTextfield becomeFirstResponder];
}


- (void)viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  // TODO: iPad customization!
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}

/**
 * Determines if this viewController was loaded modally or not
 * \return Yes if modally presented. No if not
 */
- (BOOL)isModal 
{ 
  NSArray *viewControllers = [[self navigationController] viewControllers];
  UIViewController *rootViewController = [viewControllers objectAtIndex:0];    
  return rootViewController == self;
}

- (void)dismiss
{
  [self dismissModalViewControllerAnimated:YES];
  [self.navigationController popViewControllerAnimated:YES];
}


- (void)save
{
  if (self.tag == nil) 
  {
    // Create the tag & subscribe the card to it
    Tag *newTag = [TagPeer createTag:self.setNameTextfield.text withOwner:self.ownerId withDescription:self.setDescriptionTextView.text];
    [TagPeer subscribeCard:self.defaultCard toTag:newTag];
  }
  else
  {
    [self.tag setValue:self.setNameTextfield.text forKey:@"tagName"];
    self.tag.tagDescription = self.setDescriptionTextView.text;
    [self.tag save];
  }
    
  [self dismiss];
  [[NSNotificationCenter defaultCenter] postNotificationName:kSetWasAddedOrUpdated object:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
  if (theTextField == self.setNameTextfield && [theTextField.text length] == 0)
  {
    [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Enter Set Name",@"AddStudySetInputViewController.AlertViewTitle")
                                       message:NSLocalizedString(@"Please enter a new set name or click 'Cancel'.",@"AddStudySetInputViewController.AlertViewMessage")];
    return NO;
  }
  else if (theTextField == self.setNameTextfield)
  {
    [self.setDescriptionTextView becomeFirstResponder];
    return NO;
  }
  return YES;
}

- (void) dealloc
{
  [defaultCard release];
  [setDescriptionTextView release];
  [setNameTextfield release];
  [tag release];
  [super dealloc];
}

@end