//
//  HelpViewController.h
//  jFlash
//
//  Created by シャロット ロス on 12/28/09.
//  Copyright 2009 LONG WEEKEND INC.. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UITableViewController
{
  NSInteger currentIndex;
}

- (void) navigateToNextHelpPage;

@property (nonatomic, retain) NSArray *sectionTitles;
@property (nonatomic, retain) NSArray *htmlFilenames;

@end