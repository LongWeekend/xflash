//
//  LWEFile.m
//  jFlash
//
//  Created by Mark Makdad on 3/13/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "LWEFile.h"


@implementation LWEFile

/**
 * Takes a single filename and returns a full path pointing at that filename in the current app's document directory
 */
+ (NSString*) createDocumentPathWithFilename:(NSString*)filename
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
  return path;
}

@end
