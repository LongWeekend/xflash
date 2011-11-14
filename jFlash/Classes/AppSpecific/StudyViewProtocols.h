//
//  StudyViewProtocols.h
//  jFlash
//
//  Created by Mark Makdad on 11/14/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StudyViewController;

@protocol StudyViewSubcontrollerDelegate <NSObject>
@required
- (void) setupWithCard:(Card*)card;
- (void) studyViewModeDidChange:(StudyViewController*)svc;
@optional
- (void) reveal;
@end

@protocol StudyViewControllerDelegate <NSObject>
@required
- (void)updateStudyViewLabels:(StudyViewController*)svc;
@optional
- (void)studyViewWillSetup:(StudyViewController*)svc;
@end
