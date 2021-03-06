package com.longweekendmobile.android.xflash.model;

//  User.java
//  Xflash
//
//  Created by Todd Presson on 1/13/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//
//  public User()
//
//  public void hydrate(Cursor  )
//  public void save()
//  public void deleteUser()
//  
//  public void setUserId(int  )
//  public int getUserId()
//  public void setUserNickname(String  )
//  public String getUserNickname()

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.longweekendmobile.android.xflash.XFApplication;

public class User
{
    // private static final String MYTAG = "XFlash User";

    private static final int kLWEUninitializedUserId = -1;
    public static final String DEFAULT_USER_AVATAR_PATH  = "NOT_IMPLEMENTED";

    private int userId;
    private String userNickname;

    public User()
    {
        userId = kLWEUninitializedUserId;
        userNickname = null;
    }

    // takes a sqlite result and populates the properties of user
    //
    //              expect that the incoming Cursor has already been 
    //              handled appropriately and prepared with moveToFirst()
    public void hydrate(Cursor inCursor)
    {
        int tempColumn = 0;

        // set our local User variables to the values returned
        // in our db query

        tempColumn = inCursor.getColumnIndex("user_id");
        userId = inCursor.getInt(tempColumn);

        tempColumn = inCursor.getColumnIndex("nickname");
        userNickname = inCursor.getString(tempColumn);
        
        // assume the Cursor will be closed by the calling method
        // we don't know if they're done with it yet

    }  // end hydrate()

    // pretty obvious on this one
    public void save()
    {
        // get the dao
        SQLiteDatabase tempDB = XFApplication.getWritableDao();

        // set our values for either insert or update
        ContentValues updateValues = new ContentValues();
        updateValues.put("nickname",userNickname);
        
        // if it's an existing user, UPDATE
        if( userId != kLWEUninitializedUserId )
        {
            String[] updateArgs = new String[] { Integer.toString(userId) };

            tempDB.update("users",updateValues,"user_id = ?",updateArgs); 
        }
        else
        {
            tempDB.insert("users",null,updateValues);
        }
    
    }  // end save()

    // also self explanatory
    public void deleteUser()
    {
        // we can't delete an unitialized user
        if( userId == kLWEUninitializedUserId )
        {
            return;
        }

        // get the dao
        SQLiteDatabase tempDB = XFApplication.getWritableDao();

        String[] deleteArgs = new String[] { Integer.toString(userId) };

        tempDB.delete("users","user_id = ?",deleteArgs);
        tempDB.delete("user_history","user_id = ?",deleteArgs);

    }  // end deleteUser()


    // generic getters / setters
    public int getUserId()
    {
        return userId;
    }

    public void setUserId(int inId)
    {
        userId = inId;
    }

    public String getUserNickname()
    {
        return userNickname;
    }
    
    public void setUserNickname(String inName)
    {
        userNickname = inName;
    }

}  // end User class declaration



