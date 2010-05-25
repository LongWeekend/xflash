/*
File: SourceCell.h
Abstract: UITableView utility cell that describes where to find UIView code.
Version: 1.7
*/

#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kSourceCell_ID;

@interface SourceCell : UITableViewCell
{
	UILabel	*sourceLabel;
}

@property (nonatomic, retain) UILabel *sourceLabel;

@end
