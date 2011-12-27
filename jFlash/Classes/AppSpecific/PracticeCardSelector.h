//
//  PracticeCardSelector.h
//  xFlash
//
//  Created by Mark Makdad on 12/27/11.
//  Copyright (c) 2011 Long Weekend LLC. All rights reserved.
//

#import "Tag.h"

@interface PracticeCardSelector : NSObject
- (NSInteger)calculateNextCardLevelForTag:(Tag *)tag error:(NSError **)error;
- (CGFloat)calculateProbabilityOfUnseenWithCardsSeen:(NSUInteger)cardsSeenTotal totalCards:(NSUInteger)totalCardsInSet numerator:(NSUInteger)numeratorTotal levelOneCards:(NSUInteger)levelOneTotal;
@end
