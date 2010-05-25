//
//  ImagePicker.m
//  Text2Wallpaper
//
//  Created by Brian Stormont on 2/25/09. Copyright 2009 Stormy Productions. All rights reserved.
//  Customizations are copyright to the permissable extent 2010 LONG WEEKEND INC. All rights reserved.
//

#import "UserImagePicker.h"

// C Style Procedural Function (Global!)
CGAffineTransform orientationTransformForImage(UIImage *image, CGSize *newSize) {
  CGImageRef img = [image CGImage];
  CGFloat width = CGImageGetWidth(img);
  CGFloat height = CGImageGetHeight(img);
  CGSize size = CGSizeMake(width, height);
  CGAffineTransform transform = CGAffineTransformIdentity;
  CGFloat origHeight = size.height;
  UIImageOrientation orient = image.imageOrientation;
  
  switch(orient) { /* EXIF 1 to 8 */
    case UIImageOrientationUp:
      break;
    case UIImageOrientationUpMirrored:
      transform = CGAffineTransformMakeTranslation(width, 0.0f);
      transform = CGAffineTransformScale(transform, -1.0f, 1.0f);
      break;
    case UIImageOrientationDown:
      transform = CGAffineTransformMakeTranslation(width, height);
      transform = CGAffineTransformRotate(transform, M_PI);
      break;
    case UIImageOrientationDownMirrored:
      transform = CGAffineTransformMakeTranslation(0.0f, height);
      transform = CGAffineTransformScale(transform, 1.0f, -1.0f);
      break;
    case UIImageOrientationLeftMirrored:
      size.height = size.width;
      size.width = origHeight;
      transform = CGAffineTransformMakeTranslation(height, width);
      transform = CGAffineTransformScale(transform, -1.0f, 1.0f);
      transform = CGAffineTransformRotate(transform, 3.0f * M_PI / 2.0f);
      break;
    case UIImageOrientationLeft:
      size.height = size.width;
      size.width = origHeight;
      transform = CGAffineTransformMakeTranslation(0.0f, width);
      transform = CGAffineTransformRotate(transform, 3.0f * M_PI / 2.0f);
      break;
    case UIImageOrientationRightMirrored:
      size.height = size.width;
      size.width = origHeight;
      transform = CGAffineTransformMakeScale(-1.0f, 1.0f);
      transform = CGAffineTransformRotate(transform, M_PI / 2.0f);
      break;
    case UIImageOrientationRight:
      size.height = size.width;
      size.width = origHeight;
      transform = CGAffineTransformMakeTranslation(height, 0.0f);
      transform = CGAffineTransformRotate(transform, M_PI / 2.0f);
      break;
    default:;
  }
  *newSize = size;
  return transform;
}

// C Style Procedural Function (Global!)
UIImage *rotateImage(UIImage *image) {
  CGImageRef img = [image CGImage];
  CGFloat width = CGImageGetWidth(img);
  CGFloat height = CGImageGetHeight(img);
  CGRect bounds = CGRectMake(0, 0, width, height);
  CGSize size = bounds.size;
	CGFloat scale = size.width/width;
  CGAffineTransform transform = orientationTransformForImage(image, &size);
  
  UIGraphicsBeginImageContext(size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  /* Flip */
  UIImageOrientation orientation = [image imageOrientation];
  
  if (orientation == UIImageOrientationRight || orientation == UIImageOrientationLeft) {
    CGContextScaleCTM(context, -scale, scale);
    CGContextTranslateCTM(context, -height, 0);
  }
  else {
    CGContextScaleCTM(context, scale, -scale);
    CGContextTranslateCTM(context, 0, -height);
  }
  
  CGContextConcatCTM(context, transform);
  CGContextDrawImage(context, bounds, img);
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

@implementation UserImagePicker
@synthesize selectedImage;

- (id) init
{
	if (!(self = [super init])) return self;
	if ([UIImagePickerController isSourceTypeAvailable:SOURCETYPE])	self.sourceType = SOURCETYPE;
//	self.allowsEditing = YES;
	self.delegate = self;
	
	return self;
}

- (void)viewDidLoad {
	self.navigationBar.tintColor = [UIColor blackColor];
}

- (UIImage *)cropImage:(UIImage *)image to:(CGRect)cropRect andScaleTo:(CGSize)size translate:(CGFloat) yTrans{
	CGFloat virtualScale = cropRect.size.width / 320.0f;
	image = rotateImage(image);	
	
	UIGraphicsBeginImageContext(size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGImageRef subImage = CGImageCreateWithImageInRect([image CGImage], cropRect);
  
	// make the background black
	//CGContextSetRGBFillColor (context, 0, 0, 0, 1);
  //CGContextFillRect (context, CGRectMake(0.0f, 0.0f, size.width, size.height));
  
	CGRect myRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	CGFloat xScale, yScale;
	
	xScale = 1.0f;
	yScale = cropRect.size.height/460.0f/virtualScale;
	
  CGContextScaleCTM(context, xScale, -yScale);
  CGContextTranslateCTM(context, 0.0f, -size.height + (yTrans/yScale/virtualScale));
  CGContextDrawImage(context, myRect, subImage);
  UIImage* croppedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  CGImageRelease(subImage);
  return croppedImage;
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)editingInfo
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CGRect origRect, newRect;
  
	[[editingInfo objectForKey:UIImagePickerControllerCropRect] getValue:&origRect];
	UIImage *origImage = [editingInfo objectForKey:UIImagePickerControllerOriginalImage];
	
	// The crop rectangle returned has been scaled relative to the image being 480x640 regardless of the real image dimensions.
	// And, to make matters worse, it's a virtual 320x320 square centered on the screen rather than being the whole screen.
	// This is a known issue per discussions on the official Apple iPhone developer forum.  
	// So, we need to rescale the crop rectangle so it matches the original image resolution and so it's the full screen.
	
	CGSize origImageSize = origImage.size;

  LWE_LOG(@"origImageSize.width %d", origImageSize.width);
  LWE_LOG(@"origImageSize.height %d", origImageSize.height);
	
	CGFloat xBase = 640.0f;
	CGFloat yBase = 640.0f;
	if ((origImageSize.width < xBase) || (origImageSize.height < yBase)){
		xBase = origImageSize.width;
		yBase = origImageSize.height;
	}

  LWE_LOG(@"yBase %d", yBase);
  LWE_LOG(@"yBase %d", yBase);
	
	CGFloat scaleX = origImageSize.width/xBase;	
	CGFloat scaleY = origImageSize.height/yBase;
	CGFloat scale = (scaleX > scaleY)?scaleX:scaleY; // decide dimension's scale is widest

  LWE_LOG(@"scaleX %d", scaleX);
  LWE_LOG(@"scaleY %d", scaleY);
  LWE_LOG(@"scale %d",  scale);

	if (origRect.size.width >= 640.0f || origRect.size.width > origImageSize.width){ // reset scale if cropping rect is bigger
		scale = origImageSize.width / origRect.size.width;
	}
	// create new cropping rect??
	newRect.origin.x = origRect.origin.x * scale;
	newRect.origin.y = origRect.origin.y * scale;
	newRect.size.width = origRect.size.width * scale;
	newRect.size.height = origRect.size.height * scale;
  
  LWE_LOG(@"origRect.origin ",  origRect.origin);
  LWE_LOG(@"newRect.origin ",  newRect.origin);

	// Make the crop rectangle cover the whole screen rather than a virtual 320x320 square in the center
	CGFloat virtualScale = newRect.size.width / 320.0f;
	CGFloat yShift = 70 * virtualScale;   // We use the width because with the Move and Scale action, you can never make an image narrower than the view, 
                                        // but you can make the image shorter than the view.  So, the width is always relative to the maximum 320 width of the screen.
	CGFloat yRectDisplacement = newRect.size.width - newRect.size.height;
	CGFloat origImageYDisplacement = origImageSize.height - newRect.size.height;
	CGFloat yTrans = 0.0f;
	CGSize canvasSize;
	
	newRect.origin.y -= yShift;   
	if (newRect.origin.y <0) {
		yTrans = newRect.origin.y;
		newRect.origin.y = 0;
	}
	newRect.size.height += yShift * 2.0f + yRectDisplacement;  
	canvasSize.width = newRect.size.width;
	canvasSize.height = newRect.size.height;
	if (newRect.size.height > (origImageSize.height - newRect.origin.y)) {
		newRect.size.height =  (origImageSize.height - newRect.origin.y);
		//canvasSize.height = (origSize.height);
		//yTrans += yShift / 2.0f + 20.0f * virtualScale;
	}
  
	// Figure out where image should be centered.
	if (origRect.origin.y != 0){
    // ...
	}else{
		// TODO: need to handle case of image shifted up
		
		// If y was zero, but the rect height was smaller than virtual 320, then the image was shifted down
		if (yRectDisplacement){
			// If image was shorter than it was wide
			if (newRect.size.width > newRect.size.height){
				if (origImageYDisplacement){
					yTrans -= (320.0f*virtualScale + (origImageYDisplacement - origImageSize.height));	
				}else{
					yTrans -= yRectDisplacement / 2.0f;	
				}
			}else{			
				yTrans -= (yRectDisplacement);
			}
		}
	}
	//origRect = CGRectIntegral(origRect);
  
	// Scale things down relative to 320 x 480 to conserve memory, since in this example I'm just displaying the final image to the screen
	CGAffineTransform transform = CGAffineTransformMakeScale(320.0f/canvasSize.width, 320.0f/canvasSize.width);
	
	//yTrans *= 480.0f/canvasSize.height;
	//newRect = CGRectApplyAffineTransform(newRect, transform);
	canvasSize = CGSizeApplyAffineTransform(canvasSize, transform);
	
	UIImage *croppedImage = [self cropImage:origImage to:newRect andScaleTo:canvasSize /* CGSizeMake(320.0f, 460.0f)*/ translate:yTrans];
//	UIImage *croppedImage = [self cropImage:origImage to:newRect andScaleTo:CGSizeMake(80.0f, 80.0f) translate:yTrans];
	//??? dunno what this does ???// [imageDescriptor setObject:croppedImage forKey:@"croppedImage"];
	
	// Pop the view controller since we just handed off the edited image
	[[self parentViewController] dismissModalViewControllerAnimated:YES];
  
  // Pass the image off to the main view
  selectedImage = croppedImage;
  [[NSNotificationCenter defaultCenter] postNotificationName:@"newImagePicked" object:self];

	[picker release];
	[pool drain];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[[self parentViewController] dismissModalViewControllerAnimated:YES];
	[picker release];
}

@end