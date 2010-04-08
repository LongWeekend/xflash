//
//  CustomCellBackgroundView.h
//
//  Created by Users on Stackoverflow
//

#import <UIKit/UIKit.h>
#define ROUND_SIZE 10.0f
#define BORDER_SIZE 1

typedef enum {
  CustomCellBackgroundViewPositionTop, 
  CustomCellBackgroundViewPositionMiddle, 
  CustomCellBackgroundViewPositionBottom,
  CustomCellBackgroundViewPositionSingle
} CustomCellBackgroundViewPosition;

@interface CustomCellBackgroundView : UIView {
  UIColor *borderColor;
  UIColor *fillColor;
  CustomCellBackgroundViewPosition position;
}

- (void)setCellIndexPath:(NSIndexPath*)indexPath tableLength:(NSInteger)tableLength;

@property(nonatomic, retain) UIColor *borderColor, *fillColor;
@property(nonatomic) CustomCellBackgroundViewPosition position;
@end
