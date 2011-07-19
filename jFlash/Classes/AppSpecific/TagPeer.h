//
//  TagPeer.h
//  jFlash
//
//  Created by paul on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Tag.h"
#import "FMResultSet.h"

@interface TagPeer : NSObject
{
}

+ (int) createTag: (NSString*) tagName withOwner: (NSInteger) ownerId;
+ (BOOL)cancelMembership:(NSInteger)cardId tagId:(NSInteger)tagId error:(NSError **)theError;
+ (void) subscribe: (NSInteger) cardId tagId:(NSInteger) tagId;
+ (BOOL) checkMembership: (NSInteger) cardId tagId:(NSInteger) tagId;
+ (NSMutableArray*) membershipListForCardId: (NSInteger) cardId;
+ (NSMutableArray*) retrieveTagListWithSQL: (NSString*) sql;
+ (NSMutableArray*) retrieveMyTagList; // this is not actually all of the user tags
+ (NSMutableArray*) retrieveSysTagList;
+ (NSMutableArray*) retrieveUserTagList;
+ (NSMutableArray*) retrieveSysTagListContainingCard:(Card*)card;
+ (NSMutableArray*) retrieveTagListByGroupId: (NSInteger)groupId;
+ (NSMutableArray*) retrieveTagListLike: (NSString*)string;
+ (Tag*) retrieveTagById: (NSInteger) tagId;
+ (Tag*) retrieveTagByName: (NSString*) tagName;
+ (BOOL) deleteTag:(NSInteger) tagId;
+ (void) recacheCountsForUserTags;

@end
