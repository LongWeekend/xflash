package com.longweekendmobile.android.xflash.model;

//  UserPeer.java
//  Xflash
//
//  Created by Todd Presson on 1/13/12.
//  Copyright 2012 Long Weekend Inc. All rights reserved.
//
//  public UserPeer()
//
//      *** ALL METHODS STATIC ***
//
//  public ArrayList getUsers()
//  public User createUserWithNickname(String  ,String  )
//  public User getUserByPK(int  )

import java.util.ArrayList;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.longweekendmobile.android.xflash.XFApplication;

public class UserPeer
{
    private static final String MYTAG = "XFlash UserPeer";

    // queries DB for all users returns an ArrayList of User objects
    public static ArrayList<User> getUsers()
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        // users to return, and a temporary for loading 
        ArrayList<User> userList = new ArrayList<User>();
        User tempUser;
    
        String query = "SELECT * FROM users ORDER BY user_id ASC";
        Cursor myCursor = tempDB.rawQuery(query,null);

        try
        {
            int rowCount = myCursor.getCount();
            myCursor.moveToFirst();
    
            // cycle through the rows (all users) and add
            // them to an ArrayList
            for(int i = 0; i < rowCount; i++)
            {
                tempUser = new User();
                tempUser.hydrate(myCursor);
                userList.add(tempUser);
                
                myCursor.moveToNext();
            }

            myCursor.close();

        } 
        catch (Throwable t)
        {
            LWEDatabase.logQueryFail( MYTAG , t.toString() , "getUsers()" );
        }

        return userList;  // which is an ArrayList of User objects

    }  // end getUsers()

    // creates a new User in the database
    public static User createUserWithNickname(String inName,String inPath)
    {
        // TODO - an user name is precisely the kind of scenario when we'd like to
        //      - use parameter binding, but for reasons as yet unknown, it just
        //      - doesn't work when I use parameter binding

        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        // make our new user, set the incoming info
        User tempUser = new User();
        tempUser.setUserNickname(inName);
        if( inPath != null )
        {
            tempUser.setAvatarImagePath(inPath);
        }
        else
        {
            tempUser.setAvatarImagePath(User.DEFAULT_USER_AVATAR_PATH);
        }

        String query = "INSERT INTO users (nickname,avatar_image_path,date_created) VALUES ('" + inName + "','" + inPath + "',date('now'))";

        try
        {
            // insert the row, test for success
            tempDB.execSQL(query);
    
            // on success, return the new user
            return tempUser;
        } 
        catch (Throwable t)
        {
            LWEDatabase.logQueryFail(MYTAG, t.toString() , "createUserWithNick()");
            
            // on fail, return null
            return null;
        }

    }  // end createUserWithNickname()

    // returns a user from database, selected by id
    public static User getUserByPK(int inId)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        String[] selectionArgs = new String[] { Integer.toString(inId) };
        String query = "SELECT * FROM users WHERE user_id = ?";
    
        try
        {
            // if successful, return the user
            Cursor myCursor = tempDB.rawQuery(query,selectionArgs);   
            myCursor.moveToFirst();

            User tempUser = new User();
            tempUser.hydrate(myCursor);

            myCursor.close();

            return tempUser;
        } 
        catch (Throwable t)
        {
            // on fail, return null
            LWEDatabase.logQueryFail(MYTAG, t.toString() , "getUserByPK" );
            
            return null;
        }
            
    }  // end getUserByPK()

}  // end UserPeer class declaration


