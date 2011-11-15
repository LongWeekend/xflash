//
//  AudioSessionManager.m
//  phone
//
//  Created by Mark Makdad on 2/14/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "AudioSessionManager.h"
#import "LWEDebug.h"

// Private methods & properties
@interface AudioSessionManager ()

//! Detect when the audio route changed
void LWEAudioRouteDidChange(void *inClientData, AudioSessionPropertyID inPropertyId, UInt32 inDataSize, const void *inData);

//! Holds a reference to the last set category
@property (retain) NSString *lastSetCategory;

@end


@implementation AudioSessionManager

@synthesize lastSetCategory, isRoutedToSpeaker = _routingToSpeaker;

/**
 * Returns YES if we are in a category that allows us to record.
 */
- (BOOL) canRecord
{
  return ([self canRecordAndPlay] || [[self category] isEqualToString:AVAudioSessionCategoryRecord]);
}

/**
 * Returns YES if we are in a category that allows us to record & play simultaneously/without changing the category.
 */
- (BOOL) canRecordAndPlay
{
  return ([[self category] isEqualToString:AVAudioSessionCategoryPlayAndRecord]);
}

/**
 * Returns YES if there are other audio is playing other than this application
 */
- (BOOL) otherAudioIsPlaying
{
  UInt32 otherAudioIsPlaying;
  UInt32 propertySize = sizeof(otherAudioIsPlaying);
  AudioSessionGetProperty (kAudioSessionProperty_OtherAudioIsPlaying,
                           &propertySize,
                           &otherAudioIsPlaying);
 
  return otherAudioIsPlaying;
}

/**
 * Returns the name of the current output audio route (receiver, headphones, speaker, etc)
 */
- (NSString*) currentRoute
{
  UInt32 routeSize = sizeof(CFStringRef);
  CFStringRef route = NULL;
  OSStatus error = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &routeSize, &route);
  if (error > 0)
  {
    return nil;
  }
  else
  {
    // Take advantage of toll-free bridging
    return (NSString*)route;
  }
}


/**
 * Tells us if the headphones are currently plugged in
 */
- (BOOL) headsetIsPluggedIn
{
  BOOL returnVal = NO;
  NSString *currentRoute = [self currentRoute];
  if (currentRoute && [currentRoute hasPrefix:@"Head"])
  {
    returnVal = YES;
  }
  return returnVal;
}


/**
 * Route audio through speaker, overriding the default of
 * the earpiece when on PlayAndRecord category.
 */
- (BOOL) routeAudioToSpeakerIgnoringHeadset:(BOOL)ignoreHeadset
{
  // If you are calling this, the category should be PlayAndRecord.
  LWE_ASSERT_EXC([[self category] isEqualToString:AVAudioSessionCategoryPlayAndRecord],@"Cannot call method routeAudioToSpeaker when not in playAndRecord session");
  
  BOOL returnVal = YES;
  if (ignoreHeadset || [self headsetIsPluggedIn] == NO)
  {
    OSStatus err = 0;
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    err = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride),&audioRouteOverride);
    if (err > 0)
    {
      LWE_LOG(@"Error setting audio route over speaker: %d",(NSInteger)err);
      returnVal = NO;
    }
    else
    {
      // Do this so we know to restore this state later.
      _routingToSpeaker = YES;
    }

  }
  return returnVal;
}


/**
 * Call this method to set the default audio route
 */
- (BOOL) restoreDefaultAudioRouting
{
  UInt32 audioRouteRestore = kAudioSessionOverrideAudioRoute_None;
  OSStatus err = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteRestore),&audioRouteRestore);
  if (err > 0)
  {
    LWE_LOG(@"Error restoring default audio routing: %d",(NSInteger)err)
  }
  else
  {
    _routingToSpeaker = NO;
  }
  return (err == 0);
}

/**
 * Duck any other audio if any
 */
- (void) duckOtherAudio:(BOOL)duck
{
  UInt32 allowDucking = (duck) ? true : false;
  OSStatus err = AudioSessionSetProperty (kAudioSessionProperty_OtherMixableAudioShouldDuck, 
                                          sizeof(allowDucking),
                                          &allowDucking);
  if (err > 0)
  {
    LWE_LOG(@"[AudioSessionManager]Error in trying to turn ON/OFF ducking %ld", err);
  }
}

- (void) setSessionActive:(BOOL)active
{
  OSStatus err = AudioSessionSetActiveWithFlags(active, AVAudioSessionSetActiveFlags_NotifyOthersOnDeactivation);
  if (err > 0)
  {
    LWE_LOG(@"[AudioSessionManager]Error in trying to ACTIVATE/DEACTIVATE session %ld", err);
  }
}


/**
 * VERY thin wrapper on category
 */
- (NSString*) category
{
  AVAudioSession *av = [AVAudioSession sharedInstance];
  return [av category];
}


/**
 * Wrapper, sets the category and reports status to the console.
 * \return YES if the category was changed successfully (even if it stays the same this will be YES)
 */
- (BOOL) setSessionCategory:(NSString*)category
{
  BOOL returnVal = NO;
  
  // Check the the audio session is active!
  AVAudioSession *av = [AVAudioSession sharedInstance];
  NSError *error = nil;
  [av setActive:YES error:&error];
  if (error)
  {
    LWE_LOG(@"Unable to start the audio session: %@",error);
    return NO;
  }
  
  // First, if we are already there, no need to change
  if ([category isEqualToString:[self category]])
  {
    return YES;
  }
  
  // Second, determine if someone changed our category from underneath us
  if (self.lastSetCategory && ([self.lastSetCategory isEqualToString:[self category]] == NO))
  {
    LWE_LOG(@"Someone changed the category behind our back.  We thought it was: %@, but now it's %@.",self.lastSetCategory,[self category]);
  }
  
  // Otherwise, do it
  [av setCategory:category error:&error];
  if (error == nil)
  {
    LWE_LOG(@"Switched audio category to: %@",category);
    self.lastSetCategory = category;
    returnVal = YES;
  }
  else
  {
    LWE_LOG(@"ERROR setting audio category: %@",error);
  }
  return returnVal;
}

#pragma mark -
#pragma mark Private Stuff

/**
 * If we detect a change in audio route, it's probably because the user plugged in their 
 * headphones (or unplugged them).. do something about that if necessary
 * This is passed as a function pointer to Audio Session Services; so it has to be a C function.
 */
void LWEAudioRouteDidChange(void *inClientData, AudioSessionPropertyID inPropertyId, UInt32 inDataSize, const void *inData)
{
  // There's no reason this callback would be called with anything else, but check for programmer error
  LWE_ASSERT(inPropertyId == kAudioSessionProperty_AudioRouteChange);
  
  // Get our class object, passed in by the callback caller (we registered this on this class' init method)
  AudioSessionManager *audioSessionManager = (AudioSessionManager*)inClientData;
  NSDictionary *changeReasonHash = (NSDictionary*)inData;
  NSString *changeReasonKey = [NSString stringWithCString:kAudioSession_AudioRouteChangeKey_Reason encoding:NSUTF8StringEncoding];
  NSString *oldRouteKey = [NSString stringWithCString:kAudioSession_AudioRouteChangeKey_OldRoute encoding:NSUTF8StringEncoding];
  
  NSInteger changeReason = [(NSNumber*)[changeReasonHash objectForKey:changeReasonKey] integerValue];
  NSString *oldRoute = (NSString*)[changeReasonHash objectForKey:oldRouteKey];
  NSString *newRoute = [audioSessionManager currentRoute];

  LWE_LOG(@"Audio route changed; was: %@, now %@, reason: %d",oldRoute,newRoute,changeReason);
  
  if (changeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable)
  {
    // This probably means earphones (TODO: could be bluetooth headset too?)
    if ([newRoute hasPrefix:@"Head"])
    {
    }
  }
  else if (changeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable)
  {
    // This means the route we were using disappeared -- probably means someone unplugged the headphones.
    if ([oldRoute hasPrefix:@"Head"])
    {
      if (audioSessionManager.isRoutedToSpeaker)
      {
        [audioSessionManager routeAudioToSpeakerIgnoringHeadset:NO];
      }
    }
  }
  
  /*
   MMA: I've put all the constants here for now, who knwos, we may need more later.
      kAudioSessionRouteChangeReason_Unknown                    = 0,
      kAudioSessionRouteChangeReason_NewDeviceAvailable         = 1,
      kAudioSessionRouteChangeReason_OldDeviceUnavailable       = 2,
      kAudioSessionRouteChangeReason_CategoryChange             = 3,
      kAudioSessionRouteChangeReason_Override                   = 4,
      kAudioSessionRouteChangeReason_WakeFromSleep              = 6,
      kAudioSessionRouteChangeReason_NoSuitableRouteForCategory = 7
  */
}


- (void) _appDidBecomeActive
{
  if ((self.lastSetCategory) && (![self.lastSetCategory isEqualToString:[self category]]))
  {
    LWE_LOG(@"App did become active, last set category: %@. current category %@", self.lastSetCategory, [[AVAudioSession sharedInstance] category]);
    [self setSessionCategory:self.lastSetCategory];

    if ([self.lastSetCategory isEqualToString:AVAudioSessionCategoryPlayAndRecord] && self.isRoutedToSpeaker)
    {
      [self routeAudioToSpeakerIgnoringHeadset:NO];
    }
  }
}

#pragma mark - AVAudioSessionDelegate
#pragma mark Interruption Handling

- (void)beginInterruption 
{
  LWE_LOG(@"[AudioSessionManager]beginInterruption message");
  OSStatus err = AudioSessionSetActive(false);
  if (err > 0)
  {
    LWE_LOG(@"[AudioSessionManager]Error in DEACTIVATING audio session %ld", err);
  }
}

- (void)endInterruption 
{
  LWE_LOG(@"[AudioSessionManager]endInterruption message");
  OSStatus err = AudioSessionSetActive(true);
  if (err > 0)
  {
    LWE_LOG(@"[AudioSessionManager]Error in ACTIVATING audio session %ld", err);
  }
}

#pragma mark - AVAudioSession KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ((object == [AVAudioSession sharedInstance]) && ([change objectForKey:@"new"]!=self))
  {
    LWE_LOG(@"[AudioSessionManager]Someone tried to change the delegate of the AVAudioSession singleton and it is not advisable to do that. Ignoring the change...");
    [[AVAudioSession sharedInstance] setDelegate:self];
  }
}


#pragma mark -
#pragma mark Singleton Stuff

static AudioSessionManager *sharedAudioSessionManager = nil;

- (id) init
{
  if ((self = [super init]))
  {
    // Set the listener for the audio route
    OSStatus err = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, LWEAudioRouteDidChange, self);
    if (err > 0)
    {
      LWE_LOG(@"[AudioSessionManager]Could not add listener to route change property; error code: %ld", err);
    }
    
    //Setting the delegate to self for any interruption handling of the AudioSession.
    [[AVAudioSession sharedInstance] setDelegate:self];
    [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"delegate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:NULL];
    
    _routingToSpeaker = NO;
    self.lastSetCategory = nil;
  }
  return self;
}

+ (AudioSessionManager *)sharedAudioSessionManager
{ 
  @synchronized(self) 
  { 
    if (sharedAudioSessionManager == nil) 
    { 
      sharedAudioSessionManager = [[self alloc] init];
      
      // Now register with notifications - losing "focus" & gaining "focus"
      [[NSNotificationCenter defaultCenter] addObserver:sharedAudioSessionManager selector:@selector(_appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
  }
  return sharedAudioSessionManager; 
} 

+ (id)allocWithZone:(NSZone *)zone
{
  @synchronized(self) 
  {
    if (sharedAudioSessionManager == nil) 
    { 
      sharedAudioSessionManager = [super allocWithZone:zone]; 
      return sharedAudioSessionManager; 
    } 
  } 
  return nil; 
} 

- (id)copyWithZone:(NSZone *)zone 
{
  return self; 
} 

- (id)retain 
{
  return self; 
}

- (NSUInteger)retainCount 
{
  return NSUIntegerMax; 
}

- (void)release
{
}

- (id)autorelease 
{ 
  return self; 
}

#pragma mark -
#pragma mark Class Plumbing

- (void) dealloc
{
  [lastSetCategory release];
  [super dealloc];
}

@end