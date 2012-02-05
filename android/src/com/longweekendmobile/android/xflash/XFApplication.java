package com.longweekendmobile.android.xflash;

//  XFApplication.java
//  Xflash
//
//  Created by Todd Presson on 1/7/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//
//  a simple wrapper extending the base Application class so
//  we can create a single instance of our database instance
//
//  public void onCreate()      @over
//
//  public static LWEDatabase getDao()
//  public static SQLiteDatabase getReadableDao()
//  public static SQLiteDatabase getWritableDao()

import android.app.Application;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.longweekendmobile.android.xflash.model.LWEDatabase;

public class XFApplication extends Application
{
    private static final String MYTAG = "XFlash XFApplication";

    // MASTER CONTROL FOR JFLASH/CFLASH
    public static final boolean IS_JFLASH = true;

    // Preferences file name
    public static final String XFLASH_PREFNAME = "XFLASH_PREFS";

    // our master "singleton" database instance
    // though it actually isn't a singleton, it's
    // superclassed to hang out in the global
    // application context
    private static XFApplication myInstance = null;
    private static LWEDatabase dao = null;
    
    @Override
    public void onCreate()
    {
        super.onCreate();
    
        // set out database to the global app context
        myInstance = this;
        dao = new LWEDatabase(myInstance);
    
        // set all display pages to 0 on app start
        XflashScreen.fireUpScreenManager(); 

        // setup all persistent app settings
        XflashSettings.load();
    }

    public static XFApplication getInstance()
    {
        return myInstance;
    }

    // return our entire SQLiteOpenHelper -> LWEDatabase object
    public static LWEDatabase getDao()
    {
        if( dao == null )
        {
            dao = new LWEDatabase( getInstance() );
        }

        return dao;
    }

    // return just a readable SQLiteDatabase
    public static SQLiteDatabase getReadableDao()
    {
        if( dao == null )
        {
            dao = getDao();
        }

        return dao.getReadableDatabase();
    } 

    // return just a writable SQLiteDatabase
    public static SQLiteDatabase getWritableDao()
    {
        if( dao == null )
        {
            dao = getDao();
        }

        return dao.getWritableDatabase();
    } 


}  // end XFApplication class declaration




