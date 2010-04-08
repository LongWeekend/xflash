//
//  Util.m
//  jFlash
//
//  Created by Mark Makdad on 8/15/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import "Util.h"
#include <netinet/in.h>


@implementation Util

+ (BOOL) connectedToNetwork {
  // Create zero addr
  struct sockaddr_in zeroAddress;
  bzero(&zeroAddress, sizeof(zeroAddress));
  zeroAddress.sin_len = sizeof(zeroAddress);
  zeroAddress.sin_family = AF_INET;
  
  // Reachability flags
  SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL,(struct sockaddr*)&zeroAddress);
  SCNetworkReachabilityFlags flags;
  
  BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability,&flags);
  CFRelease(defaultRouteReachability);
  
  if (!didRetrieveFlags) {
    return 0;
  }
  
  BOOL isReachable = flags & kSCNetworkFlagsReachable;
  BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
  return (isReachable && !needsConnection) ? YES : NO;
}

@end
