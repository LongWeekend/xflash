//
//  LWEAudioQueue.m
//  jFlash
//
//  Created by Rendy Pranata on 8/11/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "LWEAudioQueue.h"
#import "LWEMacros.h"

#import "AudioSessionManager.h"

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
- (void)_setAudioSessionActive:(BOOL)setActive;
@end

@implementation LWEAudioQueue
@synthesize players = _players;
@synthesize playing = _playing, currentIdx = _currentIdx, currentPlayer = _currentPlayer;
@synthesize error = _error;
@synthesize delegate = _delegate;

#pragma mark - Public Handy Method

- (void) play
{
  // Do nothing if we have nothing to play
  if ([self.players count] == 0)
  {
    return;
  }
  
  if ((self.isPlaying == NO) && (self.currentPlayer == nil))
  {
    //Setting up the states for the queue to be played
    [self _setAudioSessionActive:YES];
    self.playing = YES;
    
    LWE_DELEGATE_CALL(@selector(audioQueueWillStartPlaying:), self);
    [self _playThroughTheQueue];
  }
  else if (self.currentPlayer != nil)
  {
    self.playing = YES;
    [self.currentPlayer play];
  }
}

- (void) pause
{
  [self.currentPlayer pause];
  self.playing = NO;
}

- (void) stop
{
  if (self.isPlaying && self.delegate && [self.delegate respondsToSelector:@selector(audioQueueFinishInterruption:withFlag:)])
  {
    //If its in the middle of the queue playing, report to the delegate so.
    LWE_DELEGATE_CALL(@selector(audioQueueBeginInterruption:), self);
    [self _setAudioSessionActive:NO];
    [self.delegate audioQueueFinishInterruption:self withFlag:LWEAudioQueueInterruptionShouldStop];
  }
  [self pause];
  [self _resetState];
}

- (void) stopAndClearDelegate
{
  self.delegate = nil;
  [self stop];
}

#pragma mark - Privates

- (void) _playThroughTheQueue
{
  AVAudioPlayer *p = (AVAudioPlayer *)[self.players objectAtIndex:self.currentIdx];
  self.currentPlayer = p;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    [p prepareToPlay];
    [p play];
  });
}

- (void) _resetState
{
  //reset back any instance variable which are saving state throughout
  //the queue being played
  self.playing = NO;
  self.currentIdx = 0;
  self.currentPlayer = nil;
  
  //Get the audio session to make its session inactive
  //this will allow any other audio to play in background
  [self _setAudioSessionActive:NO];
}

- (void)_setAudioSessionActive:(BOOL)setActive
{
  [[AudioSessionManager sharedAudioSessionManager] setSessionActive:setActive];
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
  //TODO: This method has not been tested, what will happen to the internal state of the queue?
  if ((self.delegate) && ([self.delegate respondsToSelector:@selector(audioQueue:didFailPlayingURL:error:)]))
  {
    [self.delegate audioQueue:self didFailPlayingURL:player.url error:error];
  }
}

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
  [player pause];
  self.playing = NO;
  LWE_DELEGATE_CALL(@selector(audioQueueBeginInterruption:), self);
}

/**
 *
 * \details   audioPlayerEndInterruption:withFlags: is called when the audio session interruption has ended and this player had been interrupted while playing.
 *            Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume.
 *            NOTE: This method doesnt not make the current player continue playing. (this behaviour is similar to what CoreAudio behaves as well)
 */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags
{
  LWEAudioQueueInterruptionFlag newFlag = 0;
  if (flags == AVAudioSessionInterruptionFlags_ShouldResume)
  {
    newFlag = LWEAudioQueueInterruptionShouldResume;
  }
  
  if ((self.delegate) && ([self.delegate respondsToSelector:@selector(audioQueueFinishInterruption:withFlag:)]))
  {
    [self.delegate audioQueueFinishInterruption:self withFlag:newFlag];
  }
}

#pragma mark - Class Plumbing

- (void)dealloc
{
  if (self.isPlaying)
  {
    //Stop the player
    [self.currentPlayer stop];
    //But also tell the delegate if we are in the middle of playing
    //the queue but got interrupted
    if ((self.delegate) && ([self.delegate respondsToSelector:@selector(audioQueueFinishInterruption:withFlag:)]))
    {
      LWE_DELEGATE_CALL(@selector(audioQueueBeginInterruption:), self);
      [self _setAudioSessionActive:NO];
      [self.delegate audioQueueFinishInterruption:self withFlag:LWEAudioQueueInterruptionBeingDeallocated];
    }
  }
  
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
    NSMutableArray *playerArray = [NSMutableArray arrayWithCapacity:[theUrls count]];
    for (NSURL *url in theUrls)
    {
      LWE_ASSERT_EXC([url isKindOfClass:[NSURL class]], @"You must pass this method an array of NSURL objs");
      NSError *error = nil;
      AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
      if (!error)
      {
        player.delegate = self;
        [playerArray addObject:player];
      }
      else
      {
        //Tell the delegate if the loading of an URL is failing.
        if ((self.delegate) && ([self.delegate respondsToSelector:@selector(audioQueue:didFailLoadingURL:error:)]))
        {
          [self.delegate audioQueue:self didFailLoadingURL:url error:error];
        }
      }
      [player release];
    }
    self.players = (NSArray *)playerArray;
    
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
