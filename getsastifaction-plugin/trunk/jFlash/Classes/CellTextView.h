/*

File: CellTextView.h
Abstract: A simple UITableViewCell that wraps a UITextView object so that you
can edit the text.

Version: 1.7

*/

#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kCellTextView_ID;

@interface CellTextView : UITableViewCell
{
    UITextView *view;
}

@property (nonatomic, retain) UITextView *view;

@end
