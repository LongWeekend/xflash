/*
File: EditableTableViewCell.m
Abstract: Abstract base class for editable table cells.
Also declares the protocol for delegates.
Version: 1.7
*/

#import "EditableTableViewCell.h"

@implementation EditableTableViewCell

// Instruct the compiler to create accessor methods for the property.
// It will use the internal variable with the same name for storage.
@synthesize delegate;
@synthesize isInlineEditing;

// To be implemented by subclasses. 
- (void)stopEditing
{}

@end
