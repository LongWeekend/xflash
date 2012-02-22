package com.longweekendmobile.android.xflash.model;

//  GroupPeer.java
//  Xflash
//
//  Created by Todd Presson on 1/5/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public GroupPeer()
//
//      *** ALL METHODS STATIC ***
//
//  public Group topLevelGroup()
//  public ArrayList<Group> retrieveGroupsByOwner(int) 
//  public Group retrieveGroupById(int)

import java.util.ArrayList;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.longweekendmobile.android.xflash.XFApplication;

public class GroupPeer
{
    private static final String MYTAG = "XFlash GroupPeer";

    // I'm not actually entirely sure what this is for.  It pulls the...
    // uh... the top level group with owner = -1... I don't know what that means
    public static Group topLevelGroup()
    {
        ArrayList<Group> groups = retrieveGroupsByOwner(-1);
        
        if( groups.size() != 1 )
        {
            Log.d(MYTAG,"ERROR: topLevelGroup()");
            Log.d(MYTAG,"returned array has " + groups.size() + " groups, should be 1");
        }           

        return groups.get(0);
    }

    // this will take a group id number and return an ArrayList containing
    // all groups whose owner_id field matches the incoming groupId 
    public static ArrayList<Group> retrieveGroupsByOwner(int inUserId)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        ArrayList<Group> tmpArray = new ArrayList<Group>();
        Group tmpGroup = null;
        
        String[] selectionArgs = new String[] { Integer.toString(inUserId) };
        String query = "SELECT * FROM groups WHERE owner_id = ? ORDER BY recommended DESC, group_name ASC";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        
        try
        {
            int rowCount = myCursor.getCount();
            myCursor.moveToFirst();

            // cycle through the rows returned from the
            // database, make a new Group, and tack it
            // on to the end of the ArrayList
            for(int i = 0; i < rowCount; i++)
            {
                tmpGroup = new Group();
                tmpGroup.hydrate(myCursor);
                tmpArray.add(tmpGroup);

                myCursor.moveToNext();
            }
            
            myCursor.close();
        } 
        catch (Throwable t)
        {  
            LWEDatabase.logQueryFail( MYTAG, t.toString() , "retrieveGroupsByOwner()" );
        }

        return tmpArray;

    }  // end retrieveGroupsByOwner()

    // returns a single Group based on the incoming groupId
    public static Group retrieveGroupById(int inGroupId)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        Group tmpGroup = new Group();

        String[] selectionArgs = new String[] { Integer.toString(inGroupId) };
        String query = "SELECT * FROM groups WHERE group_id = ? LIMIT 1";
        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
    
        try
        {
            myCursor.moveToFirst();
            tmpGroup.hydrate(myCursor);
            myCursor.close();
        } 
        catch (Throwable t)
        {
            LWEDatabase.logQueryFail( MYTAG , t.toString() , "retrieveGroupById()" );  
        }

        return tmpGroup;
    }

    // returns the groupId of the parent group of inTag
    public static int parentGroupIdOfTag(Tag inTag)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        int groupId = 0;

        String[] selectionArgs = new String[] { Integer.toString( inTag.getId() ) };
        String query = "SELECT group_id FROM group_tag_link WHERE tag_id = ? LIMIT 1";
        Cursor mycursor = tempDB.rawQuery(query,selectionArgs);

        try
        {
            mycursor.moveToFirst();
            int tempColumn = mycursor.getColumnIndex("group_id");
            groupId = mycursor.getInt(tempColumn);
            mycursor.close();
        } 
        catch (Throwable t)
        {
            LWEDatabase.logQueryFail( MYTAG , t.toString() , "parentGroupIdOfTag()" ); 
        }

        return groupId;

    }  // end parentGroupIdOfTag()
    

}  // end GroupPeer class declaration



