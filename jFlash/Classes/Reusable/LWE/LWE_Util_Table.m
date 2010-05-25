//
//  LWE_Util_Table.m
//  jFlash
//
//  Created by Mark Makdad on 2/21/10.
//  Copyright 2010 LONG WEEKEND INC.. All rights reserved.
//

#import "LWE_Util_Table.h"


@implementation LWE_Util_Table

//--------------------------------------------------------------------------
// UITableViewCell reuseCellForIdentifier:id onTable:table usingStyle:style
// Helper function to reduce the complexity of cellForRowAtIndexPath
//--------------------------------------------------------------------------
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
