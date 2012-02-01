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
import android.widget.Button;
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
    public static class ColorManager
    {
        private static int colorScheme = LWE_THEME_RED;
        private static int[] backgroundIds = { R.drawable.practice_bg_red , R.drawable.practice_bg_blue , 
                                               R.drawable.practice_bg_tame };


        public static int getColorScheme()
        {
            return colorScheme;
        }

        public static void setColorScheme(int inColor)
        {
            colorScheme = inColor;
        }

        public static void setupScheme(RelativeLayout inLayout)
        {
            setupScheme(inLayout,null,null);
        }

        public static void setupScheme(RelativeLayout inLayout,Button inButton1)
        {
            setupScheme(inLayout,inButton1,null);
        }


        // sets the background image for the PracticeActivity
        public static void setupPracticeBack(RelativeLayout inLayout)
        {
            inLayout.setBackgroundResource( backgroundIds[colorScheme] );
        }


        // TODO - okay, there HAS to be a better way to do this
        public static void setupScheme(RelativeLayout inLayout,Button inButton1,Button inButton2)
        {
            // based on the current color scheme, set up as many parameters as have been passed
            switch(colorScheme)
            {
                case LWE_THEME_RED: 
                        inLayout.setBackgroundResource(R.drawable.gradient_red);
                        if( inButton1 != null )
                        {
                            inButton1.setBackgroundResource(R.drawable.button_red);
                        }
                        if( inButton2 != null )
                        {
                            inButton2.setBackgroundResource(R.drawable.button_red);
                        }
                        break;
                case LWE_THEME_BLUE: 
                        inLayout.setBackgroundResource(R.drawable.gradient_blue);
                        if( inButton1 != null )
                        {
                            inButton1.setBackgroundResource(R.drawable.button_blue);
                        }
                        if( inButton2 != null )
                        {
                            inButton2.setBackgroundResource(R.drawable.button_blue);
                        }
                        break;
                case LWE_THEME_TAME: 
                        inLayout.setBackgroundResource(R.drawable.gradient_tame);
                        if( inButton1 != null )
                        {
                            inButton1.setBackgroundResource(R.drawable.button_tame);
                        }
                        if( inButton2 != null )
                        {
                            inButton2.setBackgroundResource(R.drawable.button_tame);
                        }
                        break;

                default: break;

            }  // end switch()

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




