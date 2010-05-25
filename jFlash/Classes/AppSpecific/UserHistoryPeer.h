//
//  UserHistoryPeer.h
//  jFlash
//
//  Created by Ross Sharrott on 5/6/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

@interface UserHistoryPeer : NSObject
{
}

+ (void) recordResult: (Card*)card gotItRight:(BOOL) gotItRight knewIt:(BOOL) knewIt;
+ (NSInteger) getNextAfterLevel:(NSInteger) level gotItRight: (BOOL)gotItRight;
+ (NSArray*) getRightWrongTotalsBySet: (int)tagId;

@end