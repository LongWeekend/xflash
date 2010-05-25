/*
File: CellTextField.h
Abstract: A simple UITableViewCell that wraps a UITextField object so that you
can edit the text.
Version: 1.7
*/

#import <UIKit/UIKit.h>
#import "EditableTableViewCell.h"

// cell identifier for this custom cell
extern NSString *kCellTextField_ID;

@interface CellTextField : EditableTableViewCell <UITextFieldDelegate>
{
    UITextField *view;
}

@property (nonatomic, retain) UITextField *view;

@end
