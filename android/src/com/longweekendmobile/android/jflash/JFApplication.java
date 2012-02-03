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
//
//  public void onCreate()      @over
//
//  public static LWEDatabase getDao()
//  public static SQLiteDatabase getReadableDao()
//  public static SQLiteDatabase getWritableDao()
//
//  public static class ColorManager
//
//  public static int ColorManager.getColorScheme()
//  public static void ColorManager.setupPracticeBack(RelativeLayout  )
//  public static void ColorManager.setColorScheme(int  )
//  public static void ColorManager.setupScheme(RelativeLayout  )
//  public static void ColorManager.setupScheme(RelativeLayout  )
//  public static void ColorManager.setupScheme(RelativeLayout  ,View  )
//  public static void ColorManager.setupScheme(RelativeLayout  ,View  ,View  )
//  public static String ColorManager.getSchemeName()

import android.app.Application;
import android.database.sqlite.SQLiteDatabase;
import android.view.View;
import android.widget.RelativeLayout;

import com.longweekendmobile.android.jflash.model.LWEDatabase;

public class JFApplication extends Application
{
    // MASTER CONTROL FOR JFLASH/CFLASH
    public static final boolean IS_JFLASH = true;

    public static final int LWE_THEME_RED = 0;
    public static final int LWE_THEME_BLUE = 1;
    public static final int LWE_THEME_TAME = 2;
    
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
    
        // set all display pages to 0 on app start
        FragManager.fireUpFragManager(); 
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
    // TODO - this is currently a subclass of JFApplication because I'm suspicious
    //        that it will wind up using Preferences, in which case we want it to
    //        have direct access to JFApplication.myInstance, lest we need to pass
    //        another copy of the Context
    //        If it winds up not developing that way, it can easily be moved out
    //        to be an independent class
    public static class ColorManager
    {
        private static int colorScheme = LWE_THEME_RED;

        // arrays of resource IDs for use in setupScheme()
        // they are loaded such that their index corresponds to the appropriate
        // color scheme, i.e.  { LWE_THEME_RED , LWE_THEME_BLUE , LWE_THEME_TAME }
        // so that we can use colorScheme directly
        private static int[] backgroundIds = { R.drawable.practice_bg_red , R.drawable.practice_bg_blue , 
                                               R.drawable.practice_bg_tame };
        private static int[] viewGradients = { R.drawable.gradient_red , R.drawable.gradient_blue ,
                                               R.drawable.gradient_tame };
        private static int[] buttonGradients = { R.drawable.button_red , R.drawable.button_blue , 
                                                 R.drawable.button_tame };

        public static int getColorScheme()
        {
            return colorScheme;
        }

        // sets the background image for the PracticeActivity
        public static void setupPracticeBack(RelativeLayout inLayout)
        {
            inLayout.setBackgroundResource( backgroundIds[colorScheme] );
        }


        public static void setColorScheme(int inColor)
        {
            colorScheme = inColor;
        }

        public static void setupScheme(RelativeLayout inLayout)
        {
            setupScheme(inLayout,null,null);
        }

        public static void setupScheme(RelativeLayout inLayout,View inButton1)
        {
            setupScheme(inLayout,inButton1,null);
        }


        // takes in views from the title bar of any given Activity and sets
        // the background drawables according to color scheme
        public static void setupScheme(RelativeLayout inLayout,View inButton1,View inButton2)
        {
            // based on the current color scheme, set up as many parameters as have been passed
            inLayout.setBackgroundResource( viewGradients[colorScheme] );

            if( inButton1 != null )
            {
                inButton1.setBackgroundResource( buttonGradients[colorScheme] );
            }

            if( inButton2 != null )
            {
                inButton2.setBackgroundResource( buttonGradients[colorScheme] );
            }

        }  // end setupScheme()

        
        // return a String for the name of the current theme
        public static String getSchemeName()
        {
            switch(colorScheme)
            {
                case LWE_THEME_RED:     return "Fire";
                case LWE_THEME_BLUE:    return "Water";
                case LWE_THEME_TAME:    return "Tame";
                default:                return "Error";
            }

        }  // end getSchemeName()
    
    }  // end JFApplication.ColorManager class declaration


}  // end JFApplication class declaration




