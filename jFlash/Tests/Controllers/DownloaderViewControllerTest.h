//
//  DownloaderViewControllerTest.h
//  jFlash
//
//  Created by Mark Makdad on 5/26/10.
//  Copyright 2010 Long Weekend Inc. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
#import "DownloaderViewController.h"

@interface DownloaderViewControllerTest : SenTestCase
{
  DownloaderViewController *vc;
}

- (void) setUp;
- (void) tearDown;
- (void) testDownloaderViewControllerLoad;
- (void) testDownloaderViewControllerUpdateStatus;
- (void) testDownloaderViewControllerUpdateTask;
- (void) testDownloaderViewControllerUpdateProgressView;

@property (retain, nonatomic) DownloaderViewController *vc;

@end
