//
//  GradientCustomCellBackgroundView.h
//

#import <UIKit/UIKit.h>
#define ROUND_SIZE 10

typedef enum  
{
  CustomCellBackgroundViewPositionTop, 
  CustomCellBackgroundViewPositionMiddle, 
  CustomCellBackgroundViewPositionBottom,
  CustomCellBackgroundViewPositionSingle
} CustomCellBackgroundViewPosition;

@interface GradientCustomCellBackgroundView : UIView 
{
  CustomCellBackgroundViewPosition position;
  CGGradientRef gradient;
}

- (void)setCellIndexPath:(NSIndexPath*)indexPath tableLength:(NSInteger)tableLength;

@property(nonatomic) CustomCellBackgroundViewPosition position;

@end