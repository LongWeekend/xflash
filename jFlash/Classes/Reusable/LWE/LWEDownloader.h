//
//  LWEDownloader.h
//  jFlash
//
//  Created by Mark Makdad on 5/27/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LWEFile.h"
#import "ASIHTTPRequest.h"

// State machine for the downloader
typedef enum _downloaderStates
{
  kDownloaderInactive,                //! Downloader inactive
  kDownloaderRetrievingMetaData,      //! Retrieving data about to-be-downloaded package
  kDownloaderRetrievingData,          //! Retrieving actual data
  kDownloaderNetworkFail,             //! Network lost/timeout (no data within certain time period)
  kDownloaderDownloadComplete,        //! Download complete (no more data)
  kDownloaderVerifyFail,              //! Downloaded, but verify failed (need to delete download file bf trying again)
  kDownloaderSuccess                  //! Downloaded & verified
} downloaderStates;

@interface LWEDownloader : NSObject <ASIHTTPRequestDelegate>

{
  NSURL *targetURL;
  NSInteger downloaderState;
  
  // "Private" variable holding request instance
  ASIHTTPRequest *_request;
  
  // Status messages et al for observers
  NSString *taskMessage;
  NSString *statusMessage;
  NSInteger statusCode;
  float progress;
  int requestSize;
}

// Psuedo private methods
- (BOOL) _updateInternalState:(NSInteger)nextState;
- (BOOL) _updateInternalState:(NSInteger)nextState withTaskMessage:(NSString*)taskMsg;

// Custom getter & setter for progress
- (float) progress;
- (void) setProgress:(float)progress;

// Class methods
- (id) initWithTargetURL:(NSString*)target;
- (void) startDownload;
- (void) cancelDownload;
- (BOOL) stateIsFinal;

// ASIHTTPRequest delegate methods
//- (void)requestStarted:(ASIHTTPRequest *)request;
- (void)requestReceivedResponseHeaders:(ASIHTTPRequest *)request;
- (void)requestFinished:(ASIHTTPRequest *) request;
- (void)requestFailed:(ASIHTTPRequest *) request;


@property (nonatomic, retain) NSURL *targetURL;
@property (nonatomic, retain) NSString *taskMessage;
@property (nonatomic, retain) NSString *statusMessage;

@property float progress;

@end
