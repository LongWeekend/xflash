package com.longweekendmobile.android.xflash.model;

//  Group.java
//  Xflash
//
//  Created by Todd Presson on 1/5/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public Group ()
//  public Object clone()
//
//  public void hydrate(Cursor  )
//  public boolean isTopLevelGroup()
//  public ArrayList<Tag> childTags()
//  public void setChildGroupCount(int  )
//  public int getChildGroupCount()
//
//  public void setGroupId(int  )
//  public int getGroupId()
//  public void setGroupName(String  )
//  public String getGroupName()
//  public void setOwnerId(int  )
//  public int getOwnerId()
//  public void setTagCount(int  )
//  public int getTagCount()
//  public void setRecommended(int  )
//  public int getRecommend()
//  public void setGroupDescription(String  )
//  public String getGroupDescription()

import java.util.ArrayList;

import android.database.Cursor;
import android.util.Log;

public class Group implements Cloneable
{
    private static final String MYTAG = "XFlash Group";

    private static final int kLWEUninitializedGroupId = -99;
    private static final int LWE_TOP_LEVEL_GROUP_ID = -1;

    int groupId;              // groupId of the parent Group
    int ownerId;
    int tagCount;             // cached number of Tag items in the Group
    int recommended;          // Is a recommended Group?
    int childGroupCount;      // cached number of children Group objects

    String groupName;         // Display name
    String groupDescription;
        
    public Group()
    {
        groupId = kLWEUninitializedGroupId;
        tagCount = -1;
        childGroupCount = -1;
    }
    
    public Object clone()
    {
        try
        {
            return super.clone();
        }
        catch(Exception e)
        {
            Log.d(MYTAG,"well, fuck");
            return null;
        }
    }
   
 
    // takes a cursor pointing to a row of Group information and loads into 'this'
    //
    //      expect that the incoming Cursor has already been 
    //      handled appropriately and prepared with moveToFirst()
    public void hydrate(Cursor inCursor)
    {
        int tempColumn = 0;

        // set our local variables to values in
        // the database Cursor

        tempColumn = inCursor.getColumnIndex("group_id");
        groupId = inCursor.getInt(tempColumn);

        tempColumn = inCursor.getColumnIndex("group_name");
        groupName = inCursor.getString(tempColumn);

        tempColumn = inCursor.getColumnIndex("owner_id");
        ownerId = inCursor.getInt(tempColumn);

        tempColumn = inCursor.getColumnIndex("tag_count");
        tagCount = inCursor.getInt(tempColumn);

        tempColumn = inCursor.getColumnIndex("recommended");
        recommended = inCursor.getInt(tempColumn);

        // how did these get here?
    
        // tempColumn = inCursor.getColumnIndex("description");
        // groupDescription = inCursor.getString(tempColumn);

        // assume the Cursor will be closed by the calling method
        // we don't know if they're done with it yet

    } // end hydrate()

    // simply returns a boolean as to whether 'this' Group is TOP_LEEVL_GROUP
    public boolean isTopLevelGroup()
    {
        return ( ownerId == LWE_TOP_LEVEL_GROUP_ID );
    }

    // returns an array of all tags belonging to 'this' Group
    public ArrayList<Tag> childTags()
    {
        
        if( groupId != kLWEUninitializedGroupId )
        {
            return TagPeer.retrieveTagListByGroupId( groupId );
        }
        else
        {
            return null;
        }
    }
    
    public void setChildGroupCount(int newChildGroupCount)
    {
        childGroupCount = newChildGroupCount;
    }

    public int getChildGroupCount()
    {
        // if the childGroupCount has not yet been calculated
        if( childGroupCount < 0 )
        {
            ArrayList<Group> groups = GroupPeer.retrieveGroupsByOwner(groupId);
            childGroupCount = groups.size();
        }
            
        return childGroupCount;
    }

    // basic getters/setters to replace @synthesize commands
    public void setGroupId(int inGroupId)
    {
        groupId = inGroupId;
    }

    public int getGroupId()
    {
        return groupId;
    }

    public void setGroupName(String inName)
    {
        groupName = inName;
    }

    public String getGroupName()
    {
        return groupName;
    }

    public void setOwnerId(int inOwnerId)
    {
        ownerId = inOwnerId;
    }

    public int getOwnerId()
    {
        return ownerId;
    }

    public void setTagCount(int inCount)
    {
        tagCount = inCount;
    }

    public int getTagCount()
    {
        return tagCount;
    }

    public void setRecommended(int inRecommended)
    {
        recommended = inRecommended;
    }

    public int getRecommended()
    {
        return recommended;
    }

    public void setGroupDescription(String inDescription)
    {
        groupDescription = inDescription;
    }

    public String getGroupDescription()
    {
        return groupDescription;
    }


}  // end Group class declaration


