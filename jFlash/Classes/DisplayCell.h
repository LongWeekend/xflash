/*
File: DisplayCell.h
Abstract: UITableView utility cell that holds a UIView.
Version: 1.7
*/

#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kDisplayCell_ID;

@interface DisplayCell : UITableViewCell
{
	UILabel	*nameLabel;
	UIView	*view;
}

@property (nonatomic, retain) UIView *view;
@property (nonatomic, retain) UILabel *nameLabel;

- (void)setView:(UIView *)inView;

@end
