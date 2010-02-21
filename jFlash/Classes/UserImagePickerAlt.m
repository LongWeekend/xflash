//
//  UserImagePickerAlt.m
//  jFlash
//
//  Created by paul on 2/2/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "UserImagePickerAlt.h"


@implementation UserImagePickerAlt
@synthesize selectedImage;

- (id) init
{
	if (!(self = [super init])) return self;
	if ([UIImagePickerController isSourceTypeAvailable:SOURCETYPE])	self.sourceType = SOURCETYPE;
	self.delegate = self;
//  self.allowsEditing = YES;
	return self;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)editingInfo
{
	UIImage *image = [editingInfo objectForKey:UIImagePickerControllerOriginalImage];

  // We don't need to resize this image here but I'll leave the code in case we do
  CGSize newSize = CGSizeMake(256, 256); // a CGSize that has the size you want
  UIGraphicsBeginImageContext( newSize );
  [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];

  //image is the original UIImage
  UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  // Pass the image off to the main view
  selectedImage = resizedImage;
  [[NSNotificationCenter defaultCenter] postNotificationName:@"newImagePicked" object:self];

  [[self parentViewController]dismissModalViewControllerAnimated:YES];
  [picker release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  //	printf("User cancelled\n");
	[[self parentViewController]dismissModalViewControllerAnimated:YES];
  [picker release];
}

@end
