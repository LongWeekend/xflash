//
//  UserHistoryPeer.h
//  jFlash
//
//  Created by Ross Sharrott on 5/6/09.
//  Copyright 2009 LONG WEEKEND INC. All rights reserved.
//

@interface UserHistoryPeer : NSObject

+ (void) buryCard:(Card *)card inTag:(Tag *)tag;
+ (void) recordCorrectForCard:(Card *)card inTag:(Tag *)tag;
+ (void) recordWrongForCard:(Card *)card inTag:(Tag *)tag;

+ (NSArray *) userHistoriesForUserId:(NSInteger)userId;

@end