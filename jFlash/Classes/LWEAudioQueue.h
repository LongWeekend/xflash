//
//  LWEAudioQueue.h
//  jFlash
//
//  Created by Rendy Pranata on 8/11/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class LWEAudioQueue;
@protocol LWEAudioQueueDelegate <NSObject>
@optional
- (void)audioQueue:(LWEAudioQueue *)audioQueue didFailLoadingURL:(NSURL *)url error:(NSError *)error;
- (void)audioQueue:(LWEAudioQueue *)audioQueue didFailPlayingURL:(NSURL *)url error:(NSError *)error;
- (void)audioQueueBeginInterruption:(LWEAudioQueue *)audioQueue;
- (void)audioQueueFinishInterruption:(LWEAudioQueue *)audioQueue;
- (void)audioQueueDidFinishPlaying:(LWEAudioQueue *)audioQueue;
- (void)audioQUeueWillStartPlaying:(LWEAudioQueue *)audioQueue;
@end

@interface LWEAudioQueue : NSObject <AVAudioPlayerDelegate>
{
  NSArray *_players;
  NSError *_error;
  AVAudioPlayer *_currentPlayer;
  id<LWEAudioQueueDelegate> _delegate;
  
  BOOL _playing;
  NSUInteger _currentIdx;
}

@property (nonatomic, retain, readonly) NSArray *players;
@property (nonatomic, retain, readonly) NSError *error;
@property (nonatomic, retain, readonly) AVAudioPlayer *currentPlayer;
@property (nonatomic, assign) id<LWEAudioQueueDelegate> delegate;

@property (readonly, getter=isPlaying) BOOL playing;
@property (readonly) NSUInteger currentIdx;

- (id)initWithItems:(NSArray *)urls;
+ (id)audioQueueWithItems:(NSArray *)urls;

- (void)play;

@end
