//
//  UserImagePicker.h
//  jFlash
//
//  Created by paul on 2/2/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SOURCETYPE UIImagePickerControllerSourceTypePhotoLibrary

@interface UserImagePicker : UIImagePickerController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
  UIImage* selectedImage;
}

- (UIImage *)cropImage:(UIImage *)image to:(CGRect)cropRect andScaleTo:(CGSize)size translate:(CGFloat)yTrans ;

@property (nonatomic, retain) UIImage* selectedImage;
@end
