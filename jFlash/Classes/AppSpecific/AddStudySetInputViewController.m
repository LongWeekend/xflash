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

- (id) init
{
  self = [super init];
  if (self) 
  {
    self.defaultCardId = 0;
  }
  return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
  [super viewDidLoad];
  [setNameTextfield becomeFirstResponder];
  setNameTextfield.returnKeyType = UIReturnKeyDone;
  setNameTextfield.placeholder = NSLocalizedString(@"Type set name here",@"AddStudySetInputViewController.TypeNewSetName");
  setNameTextfield.autocapitalizationType = UITextAutocapitalizationTypeWords;
  
  UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewControllerAnimated:)];
  self.navigationItem.leftBarButtonItem = cancelButton;
  [cancelButton release];
}


- (void)viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.tintColor = [[ThemeManager sharedThemeManager] currentThemeTintColor];
  setNameTextfield.backgroundColor = [UIColor whiteColor];
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:TABLEVIEW_BACKGROUND_IMAGE]];
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
  if([theTextField.text length] == 0)
  {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter Set Name",@"AddStudySetInputViewController.AlertViewTitle")
                                                  message:NSLocalizedString(@"Please enter a new set name or click 'Cancel'.",@"AddStudySetInputViewController.AlertViewMessage")
                                                  delegate:self cancelButtonTitle:NSLocalizedString(@"OK",@"Global.OK") otherButtonTitles:nil];
    [alertView show];
    [alertView release];
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
