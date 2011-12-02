//
//  Plugin.m
//  jFlash
//
//  Created by Mark Makdad on 12/2/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "Plugin.h"

@implementation Plugin

@synthesize name, filePath, pluginId, pluginType, version, fileLocation;

#pragma mark - Initialization/Constructors

+ (id) pluginWithDictionary:(NSDictionary *)dict
{
  id plugin = [[[[self class] alloc] init] autorelease];
  for (NSString *key in dict)
  {
    // KVC-style setters
    id value = [dict valueForKey:key];
    [plugin setValue:value forKey:key];
  }
  return plugin;
}

#pragma mark - NSCoding Support

- (void)encodeWithCoder:(NSCoder *)encoder
{
  // NSObject doesn't conform to NSCoding so we don't have to call super
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.version forKey:@"version"];
  [encoder encodeObject:self.filePath forKey:@"filePath"];
  [encoder encodeObject:self.pluginId forKey:@"pluginId"];
  [encoder encodeObject:self.pluginType forKey:@"pluginType"];
  [encoder encodeInteger:self.fileLocation forKey:@"fileLocation"];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
  // NSObject doesn't conform to NSCoding so we don't have to call super
  self = [super init];
  if (self)
  {
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.version = [aDecoder decodeObjectForKey:@"version"];
    self.filePath = [aDecoder decodeObjectForKey:@"filePath"];
    self.pluginId = [aDecoder decodeObjectForKey:@"pluginId"];
    self.pluginType = [aDecoder decodeObjectForKey:@"pluginType"];
    self.fileLocation = [aDecoder decodeIntegerForKey:@"fileLocation"];
  }
  return self;
}

#pragma mark - Public Methods

- (NSString *) fullPath
{
  NSString *returnVal = nil;
  switch (self.fileLocation)
  {
    case LWEPluginLocationLibrary:
      returnVal = [LWEFile createLibraryPathWithFilename:self.filePath];
      break;
    case LWEPluginLocationDocuments:
      returnVal = [LWEFile createDocumentPathWithFilename:self.filePath];
      break;
    case LWEPluginLocationBundle:
    default:
      returnVal = [LWEFile createBundlePathWithFilename:self.filePath];
      break;
  }
  return returnVal;
}

- (BOOL) isDirectoryPlugin
{
  return YES;
}

- (BOOL) isDatabasePlugin
{
  return YES;
}

- (BOOL) isEqual:(id)object
{
  BOOL returnVal = NO;
  if ([object isKindOfClass:[Plugin class]])
  {
    BOOL sameId = ([self.pluginId isEqualToString:[(Plugin*)object pluginId]]);
    //    BOOL sameVersion = ([self.version isEqualToString:[(Plugin*)object version]]);
    returnVal = sameId; //&& sameVersion;
  }
  return returnVal;
}

#pragma mark - Class Plumbing

- (void) dealloc
{
  [name release];
  [version release];
  [filePath release];
  [pluginType release];
  [pluginId release];
  [super dealloc];
}

@end
