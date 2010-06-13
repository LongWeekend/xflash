//
//  UserImagePickerAlt.h
//  jFlash
//
//  Created by paul on 2/2/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SOURCETYPE UIImagePickerControllerSourceTypePhotoLibrary

@interface UserImagePickerAlt : UIImagePickerController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
  UIImage* selectedImage;
}

@property (nonatomic, retain) UIImage* selectedImage;
@end