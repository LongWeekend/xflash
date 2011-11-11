//
//  LWEAudioQueue.m
//  jFlash
//
//  Created by Rendy Pranata on 8/11/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "LWEAudioQueue.h"
#import "LWEMacros.h"

@interface LWEAudioQueue ()
//! Items
@property (nonatomic, retain) NSArray *players;
//! Error (if any)
@property (nonatomic, retain) NSError *error;
//! Current player which is playing
@property (nonatomic, retain) AVAudioPlayer *currentPlayer;
//! Internal consistencies
@property (getter=isPlaying) BOOL playing;
//! Internal loop counter
@property NSUInteger currentIdx;

//========PRIVATE METHOD========//
- (void)_playThroughTheQueue;
- (void)_resetState;
@end

@implementation LWEAudioQueue
@synthesize players = _players;
@synthesize playing = _playing, currentIdx = _currentIdx, currentPlayer = _currentPlayer;
@synthesize error = _error;
@synthesize delegate = _delegate;

#pragma mark - Public Handy Method

- (void)play
{
  if (!self.isPlaying)
  {
    self.playing = YES;
    LWE_DELEGATE_CALL(@selector(audioQueueWillStartPlaying:), self);
    [self _playThroughTheQueue];
  }
}

#pragma mark - Privates

- (void)_playThroughTheQueue
{
  AVAudioPlayer *p = (AVAudioPlayer *)[self.players objectAtIndex:self.currentIdx];
  self.currentPlayer = p;
  [p prepareToPlay];
  [p play];
}

- (void)_resetState
{
  self.playing = NO;
  self.currentIdx = 0;
  self.currentPlayer = nil;
}

#pragma mark - AVAudioPlayerDelegate

/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
  //Stop the player and actually seek it from zero seconds.
  [player stop];
  [player setCurrentTime:0];
  //Check whether the sound which just finiished playing
  //is the last sound?
  NSUInteger nextIdx = self.currentIdx+1;
  if (nextIdx >= [self.players count])
  {
    //the queue is finished playing, so reset the state
    //and tell the delegate
    [self _resetState];
    LWE_DELEGATE_CALL(@selector(audioQueueDidFinishPlaying:), self); 
  }
  else
  {
    //If there is still item on the queue, plese play it
    self.currentIdx = nextIdx;
    [self _playThroughTheQueue];
  }
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
  if ((self.delegate) && ([self.delegate respondsToSelector:@selector(audioQueue:didFailPlayingURL:error:)]))
  {
    [self.delegate audioQueue:self didFailPlayingURL:player.url error:error];
  }
}

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
  [player pause];
  LWE_DELEGATE_CALL(@selector(audioQueueBeginInterruption:), self);
}

/* audioPlayerEndInterruption:withFlags: is called when the audio session interruption has ended and this player had been interrupted while playing. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags
{
  [player play];
  LWE_DELEGATE_CALL(@selector(audioQueueBeginInterruption:), self);
}

#pragma mark - Class Plumbing

- (void)dealloc
{
  self.error = nil;
  self.currentPlayer = nil;
  self.players = nil;
  [super dealloc];
}

- (id)initWithItems:(NSArray *)theUrls
{
  self = [super init];
  if (self)
  {
    //Get the AVAudioPlayer object
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[theUrls count]];
    [theUrls enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      //Make sure we are only dealing with NSURL object, not the other.
      if ([obj isKindOfClass:[NSURL class]])
      {
        NSURL *url = (NSURL *)obj;
        NSError *error = nil;
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if (!error)
        {
          player.delegate = self;
          //Collect the player instantiated from a URL.
          [array addObject:player];
        }
        else
        {
          //Tell the delegate if the loading of an URL is failing.
          if ((self.delegate) && ([[self delegate] respondsToSelector:@selector(audioQueue:didFailLoadingURL:error:)]))
            [[self delegate] audioQueue:self didFailLoadingURL:url error:error];
        }
      }
    }];
    self.players = [NSArray arrayWithArray:array];
    [array release];
    
    //Another initialisation
    self.error = nil;
    self.playing = NO;
  }
  return self;
}

+ (id)audioQueueWithItems:(NSArray *)theUrls
{
  return [[[self alloc] initWithItems:theUrls] autorelease];
}

@end
