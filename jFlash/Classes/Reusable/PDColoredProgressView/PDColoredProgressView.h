#import <UIKit/UIKit.h>


@interface PDColoredProgressView : UIProgressView {
	UIColor *_tintColor;
  NSMutableArray *_colors;
  NSMutableArray *_lengths;
}

/**
 Set the desired tintColor for this control
 **/
- (void) setTintColor: (UIColor *) aColor;
- (void) setColors: (NSMutableArray *) aArray;
- (void) setLengths: (NSMutableArray *) aArray;

@end