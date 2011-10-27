//
//  LWEChineseSearchBar.h
//  jFlash
//
//  Created by Mark Makdad on 10/18/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LWEChineseSearchBar : UISearchBar

// Call this with a tone button; the tag # should identify which tone
- (IBAction) toneButtonPressed:(id)sender;

@property (nonatomic, readwrite, retain) IBOutlet UIView *inputAccessoryView;
@property (nonatomic, retain) IBOutlet UIView *accessoryKeysBackgroundView;

@end
