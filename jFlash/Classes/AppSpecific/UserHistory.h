//
//  UserHistory.h
//  xFlash
//
//  Created by Mark Makdad on 5/6/12.
//  Copyright (c) 2012 Long Weekend LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMResultSet.h"

@interface UserHistory : NSObject

+(UserHistory *)userHistoryWithResultSet:(FMResultSet *)rs;

@property NSInteger cardId;
@property NSInteger rightCount;
@property NSInteger wrongCount;
@property NSInteger cardLevel;
@property NSDate *lastUpdated;
@property NSDate *createdAt;

@end
