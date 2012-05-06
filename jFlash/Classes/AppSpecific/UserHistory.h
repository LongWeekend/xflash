//
//  UserHistory.h
//  xFlash
//
//  Created by Mark Makdad on 5/6/12.
//  Copyright (c) 2012 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMResultSet.h"

@interface UserHistory : NSObject <NSCoding>

+(UserHistory *)userHistoryWithResultSet:(FMResultSet *)rs;
- (BOOL) saveToUserId:(NSInteger)userId;

@property (assign, nonatomic) NSInteger cardId;
@property (assign, nonatomic) NSInteger rightCount;
@property (assign, nonatomic) NSInteger wrongCount;
@property (assign, nonatomic) NSInteger cardLevel;
@property (retain, nonatomic) NSDate *lastUpdated;
@property (retain, nonatomic) NSDate *createdAt;

@end
