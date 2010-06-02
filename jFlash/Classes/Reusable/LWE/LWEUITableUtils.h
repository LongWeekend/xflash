//
//  LWEUITableUtils.h
//  jFlash
//
//  Created by Mark Makdad on 2/21/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LWEUITableUtils : NSObject {

}

+ (UITableViewCell*) reuseCellForIdentifier: (NSString*) identifier onTable:(UITableView*) lclTableView usingStyle:(UITableViewCellStyle)style;

@end
