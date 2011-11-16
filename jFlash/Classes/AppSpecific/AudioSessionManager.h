//
//  AudioSessionManager.h
//  phone
//
//  Created by Mark Makdad on 2/14/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>

@interface AudioSessionManager : NSObject <AVAudioSessionDelegate>
{
  BOOL _routingToSpeaker;
}

+ (AudioSessionManager *)sharedAudioSessionManager;

- (BOOL) headsetIsPluggedIn;
- (BOOL) routeAudioToSpeakerIgnoringHeadset:(BOOL)ignoreHeadset;
- (BOOL) restoreDefaultAudioRouting;
- (void) shouldDuckOtherAudio:(BOOL)duck;
- (void) setSessionActive:(BOOL)active;

- (NSString*) category;
- (NSString*) currentRoute;
- (BOOL) setSessionCategory:(NSString*)category;
- (BOOL) canRecord;
- (BOOL) canRecordAndPlay;
- (BOOL) otherAudioIsPlaying;

@property (readonly) BOOL isRoutedToSpeaker;

@end
