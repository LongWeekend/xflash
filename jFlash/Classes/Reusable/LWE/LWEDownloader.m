//
//  LWEDownloader.m
//  jFlash
//
//  Created by Mark Makdad on 5/27/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "LWEDownloader.h"

@implementation LWEDownloader

@synthesize targetURL, targetFilename, taskMessage, statusMessage, delegate;

/**
 * Default initializer
 */
- (id) init
{
  if (self = [super init])
  {
    // Default values for URL & metadata dictionary
    [self setTargetURL:nil];
    downloaderState = kDownloaderReady;
    _unzipShouldCancel = NO;
    _remoteFileIsGzipCompressed = NO;
    _compressedFilename = nil;
  }
  return self;
}


/**
 * Default initializer - sets URL download target
 */
- (id) initWithTargetURL: (NSString *) target targetPath:(NSString*)tmpTargetFilename
{
  if (self = [self init])
  {
    if ([target isKindOfClass:[NSString class]])
    {
      [self setTargetURL:[NSURL URLWithString:target]];
      LWE_LOG(@"Relative path: %@",[[self targetURL] relativePath]);
      if ([[[[self targetURL] relativePath] pathExtension] isEqualToString:@"gz"])
      {
        _remoteFileIsGzipCompressed = YES;
        _compressedFilename = [[LWEFile createDocumentPathWithFilename:[[[self targetURL] relativePath] lastPathComponent]] retain];
        LWE_LOG(@"Will save compressed file to: %@",_compressedFilename);
      }
    }
    else
    {
      // Should throw exception.  We have no file to download to
      [NSException raise:@"Invalid target URL passed to LWEDownloader" format:@"Was passed object: %@",target];
    }


    if ([tmpTargetFilename isKindOfClass:[NSString class]])
    {
      [self setTargetFilename:tmpTargetFilename];
      LWE_LOG(@"Will save uncompressed downloaded file to: %@",tmpTargetFilename);
    } 
    else
    {
      // Should throw exception.  We have no file to download to
      [NSException raise:@"Invalid target filename passed to LWEDownloader" format:@"Was passed object: %@",tmpTargetFilename];
    }

  }
  return self;
}

#pragma mark -
#pragma mark Getters & Setters

/**
 * Sets progress complete (delegate from ASIHTTPRequest)
 */
- (void) setProgress:(float)tmpProgress
{
  // Set and then fire a notification so we know we've updated
  progress = tmpProgress;
  // TODO: incorporate info into the userInfo as opposed to relying on the PULL from the observer?
  [[NSNotificationCenter defaultCenter] postNotificationName:@"LWEDownloaderProgressUpdated" object:self];
}


/**
 * setProgressFromBackgroundThread - convenience so we can use performSelectorOnMAinThread
 */
- (void) setProgressFromBackgroundThread:(NSNumber*)tmpNum
{
  return ([self setProgress:[tmpNum floatValue]]);
}


/**
 * Getter for progress
 */
- (float) progress
{
  return progress;
}


/**
 * Changes internal state of Downloader class while also firing a notification as such, returns YES on success
 */
- (BOOL) _updateInternalState:(NSInteger)nextState
{
  // TODO: turn this into a proper state machine instead of relying on caller code
  downloaderState = nextState;
  [[NSNotificationCenter defaultCenter] postNotificationName:@"LWEDownloaderStateUpdated" object:self];
  return YES;
}


/**
 * Updates task message, then fires _updateInternalState: nextState
 */
- (BOOL) _updateInternalState:(NSInteger)nextState withTaskMessage:(NSString*)taskMsg
{
  [self setTaskMessage:taskMsg];
  return [self _updateInternalState:nextState];
}


#pragma mark -
#pragma mark View delegates - tells view controller if OK to do certain actions

/**
 * Allows us to hide/show buttons in the view based on the current state
 * Delegated from ModalTaskViewController
 */
- (void) willUpdateButtonsInView:(id)sender
{
  // If not ready, don't show start button
  if (downloaderState != kDownloaderReady)
  {
    [[sender startButton] setHidden:YES];
  }
  else
  {
    [[sender startButton] setHidden:NO];
  }
  
  // If not failed, don't show retry button (don't count cancellation)
  if (![self isFailureState] && downloaderState != kDownloaderCancelled)
  {
    [[sender retryButton] setHidden:YES];
  }
  else
  {
    [[sender retryButton] setHidden:NO];
  }
  
  // If not active, don't show Pause button (or, if paused)
  if (downloaderState != kDownloaderRetrievingData && downloaderState != kDownloaderDecompressing && downloaderState != kDownloaderPaused)
  {
    [[sender pauseButton] setHidden:YES];
  }
  else
  {
    [[sender pauseButton] setHidden:NO];
  }
}


/**
 * ModalTask delegate - Returns YES if the downloader is actively retrieving data, otherwise returns NO
 */
- (BOOL) canPauseTask
{
  if (downloaderState == kDownloaderRetrievingData || downloaderState == kDownloaderPaused)
    return YES;
  else
    return NO;
}


/**
 * You can cancel at any time! (sign up now!)
 */
- (BOOL) canCancelTask
{
  return YES;
}


/**
 * ModalTask delegate - returns YES if we are in failed state, otherwise NO
 */
- (BOOL) canRetryTask
{
  return [self isFailureState];
}


/**
 * Returns YES if the downloader is ready otherwise NO
 */
- (BOOL) canStartTask
{
  if (downloaderState == kDownloaderReady)
    return YES;
  else
    return NO;
}


#pragma mark -
#pragma mark Actual task delegate methods


/**
 * Starts download process based on target URL
 */
- (void) startTask
{
  // Only download if we have a URL to get
  if ([self targetURL] && (downloaderState == kDownloaderReady))
  {
    // Set up request
    _request = [ASIHTTPRequest requestWithURL:[self targetURL]];
    [_request setDelegate:self];
    [_request setDownloadProgressDelegate:self];
    [_request setShowAccurateProgress:YES];
    [_request setAllowResumeForFileDownloads:YES];
    
    // Handle file differently depending on processing requirements after the fact (unzip)
    if (_remoteFileIsGzipCompressed && _compressedFilename && [self targetFilename])
    {
      [_request setDownloadDestinationPath:_compressedFilename];
    }
    else if ([self targetFilename])
    {
      [_request setDownloadDestinationPath:[self targetFilename]];      
    }
    else
    {
      // Should throw exception.  We have no file to download to
      [NSException raise:@"Invalid target filename passed to LWEDownloader" format:@"Was passed object: %@",[self targetFilename]];
      return;
    }
        
    // Update internal class status
    [self _updateInternalState:kDownloaderRetrievingMetaData withTaskMessage:NSLocalizedString(@"Connecting to server",@"LWEDownloader.connecting")];
    
    // Download in the background
    [_request startAsynchronous];
  }
}


/**
 * Cancels an ongoing process (if we are in one)
 */
- (void) cancelTask
{
  switch (downloaderState)
  {
    case kDownloaderRetrievingData:
      [_request cancel];
      [self _updateInternalState:kDownloaderCancelled withTaskMessage:NSLocalizedString(@"Download cancelled",@"LWEDownloader.cancelled")];
      break;
      
    case kDownloaderDecompressing:
      // Don't update state here because we don't know when it will cancel, allow thread to do that
      _unzipShouldCancel = YES;
      break;
      
    default:
      break;
  }
}


/**
 * Resets the downloader failed status, ready to try again
 */
- (void) resetTask
{
  if ([self isFailureState])
  {
    // Delete all files
    if ([LWEFile fileExists:_compressedFilename])
    {
      [LWEFile deleteFile:_compressedFilename];
    }
    if ([LWEFile fileExists:[self targetFilename]])
    {
      [LWEFile deleteFile:[self targetFilename]];
    }
    
    // Reset state
    [self _updateInternalState:kDownloaderReady withTaskMessage:NSLocalizedString(@"Ready to try again",@"LWEDownloader.reset")];
  }
}


/**
 * Pauses the current download and re-sets the internal state to paused on success
 */
-(void) pauseTask
{
  if (downloaderState == kDownloaderRetrievingData)
  {
    [_request cancel];
    [self _updateInternalState:kDownloaderPaused withTaskMessage:NSLocalizedString(@"Download Paused",@"LWEDownloader.paused")];
  }
}


/**
 * Resumes the current download (only if they are paused)
 */
- (void) resumeTask
{
  if (downloaderState == kDownloaderPaused)
  {
    [_request startAsynchronous];
    [self _updateInternalState:kDownloaderRetrievingData withTaskMessage:NSLocalizedString(@"Downloading",@"LWEDownloader.downloading")];
  }
}



/**
 * Determines whether or not we are in a terminal failure state
 */
- (BOOL) isFailureState
{
  BOOL returnVal = NO;
  switch (downloaderState)
  {
    case kDownloaderCancelled:
    case kDownloaderNetworkFail:
    case kDownloaderDecompressFail:
    case kDownloaderInstallFail:
      returnVal = YES;
      break;
  }
  return returnVal;
}


/**
 * Determines whether or not we are in a terminal success state
 */
- (BOOL) isSuccessState
{
  if (downloaderState == kDownloaderSuccess)
  {
    return YES;
  }
  else 
  {
    return NO;
  }
}


/**
 * Tells the caller WHY we failed; if called in non-failure returns 0
 */
- (int) getFailureState
{
  if ([self isFailureState])
  {
    return downloaderState;
  }
  else
  {
    return 0;
  }
}


/**
 * Unzips the downloaded file (gzip ONLY)
 */
- (BOOL) _unzipDownloadedFile
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  LWE_LOG(@"Unzip for file: %@",_compressedFilename);
  LWE_LOG(@"Target filename: %@",[self targetFilename]);
  
  // TODO: enforce this Do disk size sanity check
  LWE_LOG(@"Free disk space %d",[LWEFile getTotalDiskSpaceInBytes]);
  
  gzFile file = gzopen([_compressedFilename UTF8String], "rb");
  FILE *dest = fopen([[self targetFilename] UTF8String], "w");
  unsigned char buffer[CHUNK];
  int uncompressedLength;
  int totalUncompressed = 0;
  // TODO: this is a hack but I am NO C programmer
  int guessedFilesize = (requestSize * 2.2);
  float decompressionProgress = 0.0f;

  while (uncompressedLength = gzread(file, buffer, CHUNK))
  {
    // Update progress bar
    totalUncompressed = totalUncompressed + CHUNK;
    if (requestSize > 0) decompressionProgress = ((float)totalUncompressed / (float)guessedFilesize);
    [self performSelectorOnMainThread:@selector(setProgressFromBackgroundThread:) withObject:[NSNumber numberWithFloat:decompressionProgress] waitUntilDone:NO];
    
    // Check for cancellation
    if (_unzipShouldCancel)
    {
      LWE_LOG(@"Cancelling unzip");
      [self _updateInternalState:kDownloaderCancelled withTaskMessage:NSLocalizedString(@"Download cancelled",@"LWEDownloader.cancelled")];
      [pool release];
      // TODO: fire a failure method
      return NO;
    }
    if (fwrite(buffer, 1, uncompressedLength, dest) != uncompressedLength || ferror(dest))
    {
      LWE_LOG(@"error writing data");
      [self _updateInternalState:kDownloaderDecompressFail withTaskMessage:NSLocalizedString(@"Failed to decompress file",@"LWEDownloader.decompressFail")];
      [pool release];
      // TODO: fire a failure method
      return NO;
    }
  }
  fclose(dest);
  gzclose(file);
  // TODO: just in case our hack above didn't work
  [self setProgress:1.0];
  
  // Delete the temporary download file
  [LWEFile deleteFile:_compressedFilename];
  
  // Get our main thread involved again on the next step
  [self performSelectorOnMainThread:@selector(_verifyDownload) withObject:nil waitUntilDone:NO];
  [pool release];
  return YES;
}


/**
 * Verify by installing plugin
 */ 
- (void) _verifyDownload
{
  if ([self installPluginWithPath:[self targetFilename]])
  {
    [self _updateInternalState:kDownloaderSuccess withTaskMessage:NSLocalizedString(@"Download complete",@"LWEDownloader.downloadSuccess")];
  }
  else
  {
    // Fail and update state
    [self _updateInternalState:kDownloaderInstallFail withTaskMessage:NSLocalizedString(@"Installation failed",@"LWEDownloader.installFailed")];
  }
}


#pragma mark Calls Delegate Method

/**
 * Delegate install plugin bit to delegates if necessary
 */
- (BOOL) installPluginWithPath:(NSString *)filename
{
  // send the selector to the delegate if it responds
  if ([[self delegate] respondsToSelector:@selector(installPluginWithPath:)])
  {
    return [[self delegate] installPluginWithPath:filename];
  }
  else
  {
    // Easy to verify - nothing to do!
    return YES;
  }
}


# pragma mark ASIHTTPRequest Delegate methods

/**
 * Delegate method for ASIHTTPRequest which is called when the response headers come back
 * We extract "content length" to determine the number of bytes to be downloaded
 */
- (void)requestReceivedResponseHeaders:(ASIHTTPRequest *)request
{
  NSString *contentLength = [[request responseHeaders] objectForKey:@"Content-Length"];
  if (contentLength)
  {
    requestSize = [contentLength intValue];
    [self _updateInternalState:kDownloaderRetrievingData withTaskMessage:NSLocalizedString(@"Downloading",@"LWEDownloader.downloading")];
  }
  else
  {
    [self _updateInternalState:kDownloaderNetworkFail withTaskMessage:NSLocalizedString(@"Network connection failed",@"LWEDownloader.networkFailure")];
  }

}


/**
 * Delegate method for ASIHTTPRequest which handles successful completion of a request
 */
- (void)requestFinished:(ASIHTTPRequest *) request
{
  // We are done!
  [self _updateInternalState:kDownloaderDownloadComplete withTaskMessage:NSLocalizedString(@"Verifying downloaded file",@"LWEDownloader.downloadFinished")];
  
  // Unzip it in the background
  if (_remoteFileIsGzipCompressed)
  {
    [self _updateInternalState:kDownloaderDecompressing withTaskMessage:NSLocalizedString(@"Decompressing downloaded file",@"LWEDownloader.downloadDecompressing")];
    // Repurpose progress bar for unzipping action
    [self setProgress:0.0f];
    [self performSelectorInBackground:@selector(_unzipDownloadedFile) withObject:nil];
  }
  else
  {
    [self _verifyDownload];
  }
}


/**
 * Delegate method for ASIHTTPRequest which handles request failure
 */
- (void)requestFailed:(ASIHTTPRequest *) request
{
  // TODO: add more error handling here
  NSError *error = [request error];
  switch ([error code])
  {
    ASIConnectionFailureErrorType:
      [self _updateInternalState:kDownloaderNetworkFail withTaskMessage:NSLocalizedString(@"Network connection failed",@"LWEDownloader.networkFailure")];
      statusCode = ASIConnectionFailureErrorType;
      break;
      //TODO: add more here?
    default:
      [self _updateInternalState:kDownloaderNetworkFail withTaskMessage:NSLocalizedString(@"Network connection failed",@"LWEDownloader.networkFailure")];
      statusCode = ASIConnectionFailureErrorType;
      break;
  }
  [self setStatusMessage:[[error userInfo] objectForKey:NSLocalizedDescriptionKey]];
  
  
}

-(void) dealloc
{
  [super dealloc];
  [_compressedFilename release];
}

@end