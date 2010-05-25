/*
File: CellTextView.m
Abstract: A simple UITableViewCell that wraps a UITextView object so that you
can edit the text.
Version: 1.7
*/

#import "CellTextView.h"
#import "Constants.h"

// cell identifier for this custom cell
NSString* kCellTextView_ID = @"CellTextView_ID";

#define kInsertValue	8.0

@implementation CellTextView

@synthesize view;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self)
	{
		// turn off selection use
		self.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	return self;
}

- (void)setView:(UITextView *)inView
{
	view = inView;
	[self.view retain];
	[self.contentView addSubview:inView];
	[self layoutSubviews];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect contentRect = [self.contentView bounds];
	
	// inset the text view within the cell
	if (contentRect.size.width > (kInsertValue*2))	// but not if the width is too small
	{
		self.view.frame  = CGRectMake(contentRect.origin.x + kInsertValue,
									  contentRect.origin.y + kInsertValue,
									  contentRect.size.width - (kInsertValue*2),
									  contentRect.size.height - (kInsertValue*2));
	}
}

- (void)dealloc
{
    [view release];
    [super dealloc];
}

@end
