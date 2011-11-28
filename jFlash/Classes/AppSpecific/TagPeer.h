//
//  TagPeer.h
//  jFlash
//
//  Created by paul on 5/6/09.
//  Copyright 2009 Long Weekend LLC. All rights reserved.
//

#import "Tag.h"
#import "FMResultSet.h"

extern NSString * const LWETagContentDidChange;
extern NSString * const LWETagContentDidChangeTypeKey;
extern NSString * const LWETagContentDidChangeCardKey;
extern NSString * const LWETagContentCardAdded;
extern NSString * const LWETagContentCardRemoved; 

extern NSString * const kTagPeerErrorDomain;
extern NSUInteger const kRemoveLastCardOnATagError;

@interface TagPeer : NSObject

+ (Tag*) createTagNamed:(NSString*)tagName inGroup:(Group*)owner;
+ (Tag*) createTagNamed:(NSString*)tagName inGroup:(Group*)owner withDescription:(NSString*)description;

+ (BOOL) cancelMembership:(Card*)card fromTag:(Tag*)tag error:(NSError **)theError;
+ (BOOL) subscribeCard:(Card*)card toTag:(Tag*)tag;
+ (BOOL) card:(Card*)card isMemberOfTag:(Tag*)tag;
+ (NSArray*) membershipListForCard:(Card*)card;
+ (NSArray*) retrieveMyTagList; // this is not actually all of the user tags
+ (NSArray*) retrieveSysTagList;
+ (NSArray*) retrieveUserTagList;
+ (NSArray*) retrieveSysTagListContainingCard:(Card*)card;
+ (NSArray*) retrieveTagListByGroupId: (NSInteger)groupId;
+ (NSArray*) retrieveTagListLike: (NSString*)string;
+ (Tag*) retrieveTagById: (NSInteger) tagId;
+ (Tag*) retrieveTagByName: (NSString*) tagName;
+ (BOOL) deleteTag:(Tag*)tag;

+ (void) recacheCountsForUserTags;
+ (void) setCardCount:(NSInteger)newCount forTag:(Tag*)tag;
@end
