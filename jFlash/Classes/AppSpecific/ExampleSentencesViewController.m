//
//  ExampleSentencesViewController.m
//  jFlash
//
//  Created by シャロット ロス on 6/5/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "ExampleSentencesViewController.h"

@interface NSObject (ExampleSentencesDelegateSupport)
// setup
- (void)exampleSentencesViewWillSetup:(NSNotification *)aNotification;
- (void)exampleSentencesViewDidSetup:(NSNotification *)aNotification;

@end

//* datasource informal protocol.  Officially you don't have to provide a datasource but the view will be empty if you don't
@interface NSObject (ExampleSentencesDatasourceSupport)
- (Card*) currentCard;
@end


@implementation ExampleSentencesViewController
@synthesize delegate, datasource;
@synthesize sentencesWebView, headwordLabel;

#pragma mark -
#pragma mark Delegate Methods

- (void)_exampleSentencesViewWillSetup
{
  NSNotification *notification = [NSNotification notificationWithName: exampleSentencesViewWillSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(exampleSentencesViewWillSetup:)])
  {
    [[self delegate] exampleSentencesViewWillSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_exampleSentencesViewDidSetup
{
  NSNotification *notification = [NSNotification notificationWithName: exampleSentencesViewDidSetupNotification object:self];
  
  // send the selector to the delegate if it responds
  if([[self delegate] respondsToSelector:@selector(exampleSentencesViewDidSetup:)])
  {
    [[self delegate] exampleSentencesViewDidSetup:notification];
  }
  
  //in case something else cares.  Seems to be the pattern from the book but I don't know if we really need this
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark -
#pragma mark UIView subclass methods

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];

  sentencesWebView.backgroundColor = [UIColor clearColor];
  UIScrollView *scrollView = [sentencesWebView.subviews objectAtIndex:0];
  
  SEL aSelector = NSSelectorFromString(@"setAllowsRubberBanding:");
  if([scrollView respondsToSelector:aSelector])
  {
    [scrollView performSelector:aSelector withObject:NO];
  }
}

#pragma mark -
#pragma mark Core Methods

//* setup the example sentences view with information from the datasource
// TODO : Paul, paint here
- (void) setup
{
  [self _exampleSentencesViewWillSetup];
  // the datasource must implement currentcard or we don't set any data
  if([datasource respondsToSelector: NSSelectorFromString(@"currentCard")])
  {
    NSString* mungedHeadWordWithReading = [[NSString alloc] initWithFormat:@"%@ (%@)", [[datasource currentCard] headword], [[datasource currentCard] combinedReadingForSettings]];
    [[self headwordLabel] setText: mungedHeadWordWithReading];
    
    // TODO : test code for the example sentences model
    NSMutableArray* sentences = [ExampleSentencePeer getExampleSentecesByCardId:1];
  }
  [self _exampleSentencesViewDidSetup];
}

#pragma mark -
#pragma mark Class Plumbing

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [sentencesWebView release];
    [headwordLabel release];
    // we don't release datasources and delegates because we don't retain them (hands off shit you don't own)
    [super dealloc];
}


@end
     
NSString  *exampleSentencesViewWillSetupNotification = @"exampleSentencesViewWillSetupNotification";
NSString  *exampleSentencesViewDidSetupNotification = @"exampleSentencesViewDidSetupNotification";