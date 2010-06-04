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

/**
 * Just delete the damn thing.
 */
+ (BOOL) deleteFile:(NSString*)filename
{
  // Sanity checks
  if (filename == nil) return NO;
  
  NSError *error;
  NSFileManager *fm = [NSFileManager defaultManager];
  if (![fm removeItemAtPath:filename error:&error])
  {
    LWE_LOG(@"Could not delete file at specified location: %@",filename);
    return NO;
  }
  else
  {
    LWE_LOG(@"File at specified location deleted: %@",filename);
    return YES;
  }
}


/**
 * Check to see if a file exists or not
 */
+ (BOOL) fileExists:(NSString*)filename
{
  // Sanity checks
  if (filename == nil) return NO;

  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:filename])
  {
    LWE_LOG(@"File found at specified location: %@",filename);
    return YES;
  }
  else
  {
    LWE_LOG(@"File not found at specified location: %@",filename);
    return NO;
  }
}


//! Returns total disk space available to the app
+ (NSInteger) getTotalDiskSpaceInBytes
{
  NSInteger totalSpace = 0;
  NSError *error = nil;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
  if (dictionary)
  {
    NSNumber *fileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemSize];
    totalSpace = [fileSystemSizeInBytes intValue];
  }
  else
  {
    LWE_LOG(@"Error Obtaining File System Info: Domain = %@, Code = %@", [error domain], [error code]);
  }
  return totalSpace;
}  

@end
