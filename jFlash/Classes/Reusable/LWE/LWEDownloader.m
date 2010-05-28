//
//  LWEDownloader.m
//  jFlash
//
//  Created by Mark Makdad on 5/27/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import "LWEDownloader.h"

@implementation LWEDownloader

@synthesize targetURL, taskMessage, statusMessage;

/**
 * Default initializer
 */
- (id) init
{
  if (self = [super init])
  {
    // Default values for URL & metadata dictionary
    [self setTargetURL:nil];
//    [self setMetaData:[[NSMutableDictionary alloc] init]];
    // Do not use setter here because we don't want to post a notification
    downloaderState = kDownloaderInactive;
  }
  return self;
}


/**
 * Default initializer - sets URL download target
 */
- (id) initWithTargetURL: (NSString *) target
{
  if (self = [self init])
  {
    if ([target isKindOfClass:[NSString class]])
    {
      [self setTargetURL:[NSURL URLWithString:target]];
    }
  }
  return self;
}


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


/**
 * Determines whether or not we are in a terminal state (failure, success, etc) or still working (downloading, etc)
 */
- (BOOL) stateIsFinal
{
  if (downloaderState == kDownloaderNetworkFail || downloaderState == kDownloaderSuccess)
    return YES;
  else
    return NO;
}


/**
 * Starts download process based on target URL
 */
- (void) startDownload
{
  // Only download if we have a URL to get
  if ([self targetURL] != nil)
  {
    // Set up request
    _request = [ASIHTTPRequest requestWithURL:[self targetURL]];
    [_request setDelegate:self];
    [_request setDownloadProgressDelegate:self];
    [_request setShowAccurateProgress:YES];
    [_request setDownloadDestinationPath:[LWEFile createDocumentPathWithFilename:@"jFlashDownloadedData"]];

    // Update internal class status
    [self _updateInternalState:kDownloaderRetrievingData withTaskMessage:NSLocalizedString(@"Downloader.downloading",@"Downloading...")];

    // Download in the background
    [_request startAsynchronous];
  }
}


/**
 * Cancels an ongoing download process (if we are in one)
 */
- (void) cancelDownload
{
  // We only need to do something if we're actively downloading
  if (downloaderState == kDownloaderRetrievingData)
  {
    [_request cancel];
    [self _updateInternalState:kDownloaderVerifyFail withTaskMessage:NSLocalizedString(@"Downloader.downloadCancelled",@"Download Cancelled.")];
  }
}


/**
 * Delegate method for ASIHTTPRequest which is called when the response headers come back
 */
- (void)requestReceivedResponseHeaders:(ASIHTTPRequest *)request
{
  NSString *poweredBy = [[request responseHeaders] objectForKey:@"Content-Length"];
}

/**
 * Delegate method for ASIHTTPRequest which handles successful completion of a request
 */
- (void)requestFinished:(ASIHTTPRequest *) request
{
  // We are done!
  [self _updateInternalState:kDownloaderDownloadComplete withTaskMessage:NSLocalizedString(@"Downloader.downloadFinished",@"Verifying.")];
  
  // We don't use this because we are saving direct to a file
  //  NSData *responseData = [request responseData];
  
  // TODO: Should be some verification step here but we have none
  [self _updateInternalState:kDownloaderSuccess withTaskMessage:NSLocalizedString(@"Downloader.downloadSuccess",@"Download Successful")];  
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
      [self _updateInternalState:kDownloaderNetworkFail];
      statusCode = ASIConnectionFailureErrorType;
      break;
    default:
      [self _updateInternalState:kDownloaderNetworkFail];
      statusCode = ASIConnectionFailureErrorType;
      break;
  }
  [self setStatusMessage:[[error userInfo] objectForKey:NSLocalizedDescriptionKey]];
  
  /* Reference from ASIHTTPRequest:
  typedef enum _ASINetworkErrorType {
    ASIConnectionFailureErrorType = 1,
    ASIRequestTimedOutErrorType = 2,
    ASIAuthenticationErrorType = 3,
    ASIRequestCancelledErrorType = 4,
    ASIUnableToCreateRequestErrorType = 5,
    ASIInternalErrorWhileBuildingRequestType  = 6,
    ASIInternalErrorWhileApplyingCredentialsType  = 7,
    ASIFileManagementError = 8,
    ASITooMuchRedirectionErrorType = 9,
    ASIUnhandledExceptionError = 10    
  } ASINetworkErrorType;*/
  
}

@end