package com.longweekend.android.jflash.model;

//  User.java
//  jFlash
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
//  public int getUserid()
//  public void setUserNickname(String  )
//  public String getUserNickname()
//  public void setAvatarImaegPath(String  )
//  public String getAvatarImagePath()
//  public void setDateCrated(String  )
//  public String getDateCreated()

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.longweekend.android.jflash.JFApplication;

public class User
{
    // private static final String MYTAG = "JFlash User";

    private static final int kLWEUninitializedUserId = -1;
    private static final String DEFAULT_USER_AVATAR_PATH  = "/avatars/default00.png";

    private int userId;
    private String userNickname;
    private String avatarImagePath;
    private String dateCreated;

    public User()
    {
        userId = kLWEUninitializedUserId;
        avatarImagePath = DEFAULT_USER_AVATAR_PATH;
        userNickname = null;
        dateCreated = null;
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
        
        tempColumn = inCursor.getColumnIndex("avatar_image_path");
        avatarImagePath = inCursor.getString(tempColumn);   

        if( avatarImagePath.length() == 0 )
        {
            avatarImagePath = DEFAULT_USER_AVATAR_PATH;
        }

        tempColumn = inCursor.getColumnIndex("date_created");
        dateCreated = inCursor.getString(tempColumn);

        // assume the Cursor will be closed by the calling method
        // we don't know if they're done with it yet

    }  // end hydrate()

    // pretty obvious on this one
    public void save()
    {
        // get the dao
        SQLiteDatabase tempDB = JFApplication.getWritableDao();

        // set our values for either insert or update
        ContentValues updateValues = new ContentValues();
        updateValues.put("nickname",userNickname);
        updateValues.put("avatar_image_path",avatarImagePath);
        
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
    public void deleteUser(Context myContext)
    {
        // we can't delete an unitialized user
        if( userId == kLWEUninitializedUserId )
        {
            return;
        }

        // get the dao
        SQLiteDatabase tempDB = JFApplication.getWritableDao();

        String[] deleteArgs = new String[] { Integer.toString(userId) };

        tempDB.delete("users","user_id = ?",deleteArgs);
        tempDB.delete("user_history","user_id = ?",deleteArgs);
    }   

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

    public String getAvatarImagePath()
    {
        return avatarImagePath;
    }
    
    public void setAvatarImagePath(String inPath)
    {
        avatarImagePath = inPath;
    }

    public String getDateCreated()
    {
        return dateCreated;
    }
    
    public void setDateCreated(String inDate)
    {
        dateCreated = inDate;
    }

}  // end User class declaration



