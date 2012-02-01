package com.longweekendmobile.android.jflash;

//  JFApplication.java
//  jFlash
//
//  Created by Todd Presson on 1/7/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//
//  a simple wrapper extending the base Application class so
//  we can create a single instance of our database instance

import android.app.Application;
import android.database.sqlite.SQLiteDatabase;

import com.longweekendmobile.android.jflash.model.LWEDatabase;

public class JFApplication extends Application
{
    // MASTER CONTROL FOR JFLASH/CFLASH
    public static final boolean IS_JFLASH = true;

    // our master "singleton" database instance
    // though it actually isn't a singleton, it's
    // superclassed to hang out in the global
    // application context
    private static JFApplication myInstance;
    private static LWEDatabase dao;
    
    @Override
    public void onCreate()
    {
        super.onCreate();
    
        // set out database to the global app context
        myInstance = this;
        dao = new LWEDatabase(myInstance);
    }

    // return our entire SQLiteOpenHelper -> LWEDatabase object
    public static LWEDatabase getDao()
    {
        return dao;
    }

    // return just a readable SQLiteDatabase
    public static SQLiteDatabase getReadableDao()
    {
        return dao.getReadableDatabase();
    } 

    // return just a writable SQLiteDatabase
    public static SQLiteDatabase getWritableDao()
    {
        return dao.getWritableDatabase();
    } 

    
    // static class for JFApplication
    // TODO - will eventually be centralized managed for SharedPreferences
    public static class PrefsManager
    {
        private static int colorScheme;

        public PrefsManager()
        {
            colorScheme = 0;
        }

        public static int getColorScheme()
        {
            return colorScheme;
        }

        public static void setColorScheme(int inColor)
        {
            colorScheme = inColor;
        }

    }  // end JFApplication.PrefsManager class declaration


}  // end JFApplication class declaration



