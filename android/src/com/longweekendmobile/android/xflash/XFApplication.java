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
//  public static void initializeDaoPhone()
//  public static void initializeDaoSDcard()
//  public static LWEDatabase getDao()
//  public static SQLiteDatabase getWritableDao()
//  public static XFApplication getInstance()
//  public static XflashNotification getNotifier()

import java.io.File;

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
    
    // our master notification server class
    private static XflashNotification myNotifier = null;

    @Override
    public void onCreate()
    {
        super.onCreate();
    
        // set out database to the global app context
        myInstance = this;
        
        // set up the master nofifier
        myNotifier = new XflashNotification();

    }  // end onCreate()

    
    // set our SQLiteOpenHelper to the local phone space
    public static void initializeDaoPhone()
    {
        Log.d(MYTAG,">>> initalizing DAO to local storage");
        
        dao = new LWEDatabase(myInstance);
    }

    // set our SQLiteOpenHelper to the SD card
    public static void initializeDaoSDcard()
    {
        Log.d(MYTAG,">>> initalizing DAO to SD card");
        
        File root = myInstance.getExternalFilesDir(null);
        File checkFile = new File(root,"jFlash.mp3");

        dao = new LWEDatabase(myInstance,checkFile.getAbsolutePath(),null,1);
    } 

    // return our entire SQLiteOpenHelper -> LWEDatabase object
    public static LWEDatabase getDao()
    {
        if( dao == null )
        {
            throw new RuntimeException("DAO not initialized!");
        }

        return dao;
    }

    
    // return just a writable SQLiteDatabase
    public static SQLiteDatabase getWritableDao()
    {
        if( dao == null )
        {
            throw new RuntimeException("DAO not initialized!");
        }

        return dao.getWritableDatabase();
    }   


    // return the global context instance
    public static XFApplication getInstance()
    {
        return myInstance;
    }

    
    // return the global notification system
    public static XflashNotification getNotifier()
    {
        return myNotifier;
    }

    
}  // end XFApplication class declaration




