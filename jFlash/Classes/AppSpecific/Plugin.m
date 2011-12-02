//
//  Plugin.m
//  jFlash
//
//  Created by Mark Makdad on 12/2/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "Plugin.h"

@implementation Plugin

@synthesize name, details, htmlString, targetURL, filePath, pluginId, pluginType, version, fileLocation;

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

- (void) setValue:(id)value forUndefinedKey:(NSString*)key
{
  // Ignore non-matching KVC properties
  return;
}

#pragma mark - NSCoding Support

- (void)encodeWithCoder:(NSCoder *)encoder
{
  // NSObject doesn't conform to NSCoding so we don't have to call super
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.details forKey:@"details"];
  [encoder encodeObject:self.version forKey:@"version"];
  [encoder encodeObject:self.targetURL forKey:@"targetURL"];
  [encoder encodeObject:self.htmlString forKey:@"htmlString"];
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
    self.details = [aDecoder decodeObjectForKey:@"details"];
    self.version = [aDecoder decodeObjectForKey:@"version"];
    self.filePath = [aDecoder decodeObjectForKey:@"filePath"];
    self.targetURL = [aDecoder decodeObjectForKey:@"targetURL"];
    self.htmlString = [aDecoder decodeObjectForKey:@"htmlString"];
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

- (BOOL) isNewVersionOfPlugin:(Plugin *)plugin
{
  BOOL returnVal = NO;
  double pluginVersion = [plugin.version doubleValue];
  double myVersion = [self.version doubleValue];
  // Note that "isNewVersion" is being asked about self, not the parameter -- so this logic seems backward but isn't
  if (pluginVersion < myVersion)
  {
    returnVal = YES;
  }
  return returnVal;
}

- (BOOL) isDirectoryPlugin
{
  return [self.pluginType isEqualToString:@"directory"];
}

- (BOOL) isDatabasePlugin
{
  return [self.pluginType isEqualToString:@"database"];
}

- (LWEPackage *) downloadPackage
{
  LWEPackage *pluginPackage = [LWEPackage packageWithUrl:[NSURL URLWithString:self.targetURL]
                                     destinationFilepath:[[self fullPath] stringByAppendingString:@".zip"]];
  return pluginPackage;
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
  [details release];
  [version release];
  [htmlString release];
  [targetURL release];
  [filePath release];
  [pluginType release];
  [pluginId release];
  [super dealloc];
}

@end
