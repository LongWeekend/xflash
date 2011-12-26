//
//  StudyViewProtocols.h
//  jFlash
//
//  Created by Mark Makdad on 11/14/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StudyViewController;

/**
 * The action bar and card view controllers should
 * implement this protocol to respond to card changes.
 */
@protocol StudyViewSubcontrollerProtocol <NSObject>
@required
/**
 * This method is called by StudyViewController when a new card.
 */
- (void) setupWithCard:(Card*)card;

/**
 * This method is called whenever the study mode changes (Browse<>Practice).
 */
- (void) studyViewModeDidChange:(StudyViewController*)svc;

- (id) delegate;

@optional
/**
 * This method is called when the user taps the "revealBtn" in StudyViewController.
 */
- (void) reveal;
@end


/**
 * Methods in this protocol should be implemented by the 
 * delegate of the StudyViewController.  SVC has some labels
 * and UI items which it has little knowledge of / control over,
 * this delegate gets around that problem by allowing the 
 * delegate to do the work.
 *
 * NB: In the long term, it may make more sense to move these UI
 * items out of the StudyViewController entirely.
 */
@protocol StudyViewControllerDelegate <NSObject>
@required

/**
 * This method is required.  The delegate needs to provide us with the right view controller for the
 * card area for this study mode.
 */
- (UIViewController<StudyViewSubcontrollerProtocol> *)cardViewControllerForStudyView:(StudyViewController*)svc;

/**
 * This method is required.  The delegate needs to provide us with the right view controller for the
 * action bar area for this study mode.
 */
- (UIViewController<StudyViewSubcontrollerProtocol> *)actionBarViewControllerForStudyView:(StudyViewController*)svc;

/**
 * StudyViewController calls this delegate method when an event
 * happens that would require its labels to be re-set.
 * For example, changing the active tag, or adding/removing cards
 * from the active tag.
 */
- (void)updateStudyViewLabels:(StudyViewController*)svc;

/**
 * This method determines "how" a new card is selected. Ask the delegate to get the next card based on the transition direction.
 * Pass "nil" to currentCard to get the first card.
 */
- (Card*) getNextCard:(Tag*)cardSet afterCard:(Card*)currentCard direction:(NSString*)directionOrNil;

@optional
/**
 * This method is called before cardViewWillSetup: is called.
 * This gives a delegate an opportunity to change any of the 
 * scroll-view related items, as well as tap-for-answer, which
 * are both located in StudyViewController.
 */
- (void)studyViewWillSetup:(StudyViewController*)svc;
/**
 * This method is called before cardViewWillReveal: is called.
 * This gives a delegate an opportunity to change any of the 
 * scroll-view related items, as well as tap-for-answer, which
 * are both located in StudyViewController.
 */
- (void)studyViewWillReveal:(StudyViewController*)svc;
@end
