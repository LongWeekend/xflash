//
//  LWEUITableUtils.m
//  jFlash
//
//  Created by Mark Makdad on 2/21/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "LWEUITableUtils.h"

//! Helper class containing static methods to help manage UITableViews
@implementation LWEUITableUtils

//! Returns a new UITableViewCell - automatically determines whether new or off the queue
+ (UITableViewCell*) reuseCellForIdentifier: (NSString*) identifier onTable:(UITableView*) lclTableView usingStyle:(UITableViewCellStyle)style
{
  UITableViewCell* cell = [lclTableView dequeueReusableCellWithIdentifier:identifier];
  if (cell == nil)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:identifier] autorelease];
  }
  return cell;
}


@end
