//
//  LWEAudioQueue.h
//  jFlash
//
//  Created by Rendy Pranata on 8/11/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

enum LWEAudioQueueInterruptionFlag {
	LWEAudioQueueInterruptionShouldResume = 1,
  LWEAudioQueueInterruptionShouldStop,
  LWEAudioQueueInterruptionBeingDeallocated
};
typedef enum LWEAudioQueueInterruptionFlag LWEAudioQueueInterruptionFlag;

@class LWEAudioQueue;
@protocol LWEAudioQueueDelegate <NSObject>
@optional
//! This method is called when a URL fed in to the initialisators is not valid or can't be loaded.
- (void)audioQueue:(LWEAudioQueue *)audioQueue didFailLoadingURL:(NSURL *)url error:(NSError *)error;

//! This method is called when a certain URL is failed playing, most likely is decoding issues.
- (void)audioQueue:(LWEAudioQueue *)audioQueue didFailPlayingURL:(NSURL *)url error:(NSError *)error;

//! The notification when the interruption begins.
- (void)audioQueueBeginInterruption:(LWEAudioQueue *)audioQueue;

//! The notification when interruption has finished happening with certain flag, whether it gets diallocated or should resume.
- (void)audioQueueFinishInterruption:(LWEAudioQueue *)audioQueue withFlag:(LWEAudioQueueInterruptionFlag)flag;

//! The notification when the AudioQueue has finished playing the entire items, not being called when get stopped or interrupted.
- (void)audioQueueDidFinishPlaying:(LWEAudioQueue *)audioQueue;

//! The notification when the AudioQueue starts playing, this method is not called when the queue is being paused.
- (void)audioQueueWillStartPlaying:(LWEAudioQueue *)audioQueue;
@end 

/*
 *  \class  This class is prividing a way for a series of sound files (locally) 
 *          playback synchronously, one sound after the other.
 *          It has LWEAudioQueueDelegate for events occured 
 *          when interact or using this instance, such as when this instance has finished playing the entire items, etc.
 */
@interface LWEAudioQueue : NSObject <AVAudioPlayerDelegate>
{
  NSArray *_players;
  NSError *_error;
  AVAudioPlayer *_currentPlayer;
  id<LWEAudioQueueDelegate> _delegate;
  
  BOOL _playing;
  NSUInteger _currentIdx;
}

//! Contains any error if anything happens in this instance
@property (nonatomic, retain, readonly) NSError *error;

//! The delegate of this instance, where to report if any event occurs
@property (nonatomic, assign) id<LWEAudioQueueDelegate> delegate;

//! Boolean indicating whether this queue is playing or not.
@property (readonly, getter=isPlaying) BOOL playing;

//! Current index of the items where it is currently playing.
@property (readonly) NSUInteger currentIdx;

//! Initialisation methods
- (id)initWithItems:(NSArray *)urls;
+ (id)audioQueueWithItems:(NSArray *)urls;

//! Starts playing the Audio Queue
- (void)play;

//! Pause the sound at the current time
- (void)pause;

//! Stop the sound and reset the head of player to the first item
- (void)stop;

//! Stopping while also clearing the delegate to stop receiving any delegates report.
- (void)stopAndClearDelegate;

@end
