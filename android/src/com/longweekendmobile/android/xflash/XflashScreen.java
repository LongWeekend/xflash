package com.longweekendmobile.android.xflash;

//  XflashScreen.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//  public void onResume()                                              @over

import android.support.v4.app.FragmentTransaction;
import android.util.Log;

public class XflashScreen 
{
    private static final String MYTAG = "XFlash XflashScreen";
    
    private static final int LWE_PRACTICE_TAB = 0; 
    private static final int LWE_TAG_TAB = 1; 
    private static final int LWE_SEARCH_TAB = 2; 
    private static final int LWE_SETTINGS_TAB = 3; 
    private static final int LWE_HELP_TAB = 4; 

    // properties for handling color theme transitions
    private static int currentHelpScreen = -1;
    private static int currentSettingsScreen = -1;

    // the index of this array corresponds to the five tabs 
    // practice = 0, tag = 1, search = 2, settings = 3, help = 4
    private static boolean[] extraScreensOn;
    private static TabInfo[] extraFragments;

    // set all fragment page values to zero when starting app
    public static void fireUpScreenManager()
    {
        currentHelpScreen = 0;
        currentSettingsScreen = 0;
        
        extraScreensOn = new boolean[] { false, false, false, false, false };
        extraFragments = new TabInfo[] { null, null, null, null, null };
    } 


    // set all necessary flags for an in-tab Xflash.onScreenTransition()
    public static void setScreenValues(String tag)
    {
        if( tag == "settings" )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = false;
            currentSettingsScreen = 0;
        }
        else if( tag == "help" )
        {
            extraScreensOn[LWE_HELP_TAB] = false;
            currentHelpScreen = 0;
        }
        else if( tag == "difficulty" )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = true;
            currentSettingsScreen = 1;
        }
        else if( tag == "help_page" )
        {
            extraScreensOn[LWE_HELP_TAB] = true;
            currentHelpScreen = 1;
        }

    }  // end setScreenValues()

    
    public static int[] getAnim(String inTag)
    {
        int[] tempAnimSet = null;

        if( ( inTag == "settings" ) || ( inTag == "help" ) )
        {
            tempAnimSet = new int[] { R.anim.slidein_left, R.anim.slideout_right };
        }
        else if( ( inTag == "difficulty" ) || ( inTag == "help_page" ) ) 
        {
            tempAnimSet = new int[] { R.anim.slidein_right, R.anim.slideout_left };
        }

        if( tempAnimSet == null )
        {
            Log.d(MYTAG,"ERROR in getAnim() : tempAnimSet is NULL");
        }

        return tempAnimSet;
    }


    public static TabInfo getTransitionFragment(String inTag)
    {
        if( inTag == "difficulty" )
        {
            if( extraFragments[LWE_SETTINGS_TAB] == null ) 
            {    
                extraFragments[LWE_SETTINGS_TAB] = new TabInfo("difficulty", DifficultyFragment.class, null);
            }

            return extraFragments[LWE_SETTINGS_TAB];
        }
        else if( inTag == "help_page" )
        {
            if( extraFragments[LWE_HELP_TAB] == null )
            {    
                extraFragments[LWE_HELP_TAB] = new TabInfo("help_page", HelpPageFragment.class, null);
            }
                
            return extraFragments[LWE_HELP_TAB];
        }

        return null;
    }

    public static void detachExtras(FragmentTransaction ft)
    {
        // cycle through extra fragments, if any are attached, detach them
        for(int i = XflashScreen.LWE_PRACTICE_TAB; i <= XflashScreen.LWE_HELP_TAB; i++)
        {
            if( extraScreensOn[i] )
            {
                ft.detach(extraFragments[i].fragment);
                extraScreensOn[i] = false;
            }
        }
    }

    public static void detachSelectExtras(FragmentTransaction ft,String inTag)
    {
        if( inTag == "settings" )
        {
            if( extraFragments[LWE_SETTINGS_TAB].fragment != null )
            {
                ft.detach(extraFragments[XflashScreen.LWE_SETTINGS_TAB].fragment);
                extraScreensOn[LWE_SETTINGS_TAB] = false;
            }
        }
        if( inTag == "help" )
        {
            if( extraFragments[LWE_HELP_TAB].fragment != null )
            {
                ft.detach(extraFragments[XflashScreen.LWE_HELP_TAB].fragment);
                extraScreensOn[LWE_HELP_TAB] = false;
            }
        }

    }


    public static int getCurrentSettingsScreen()
    {
        if( ( currentSettingsScreen < 0 ) || ( currentSettingsScreen > 1 ) )
        {
            Log.d(MYTAG,"Error: XflashScreen.getCurrentSettingsScreen()");
            Log.d(MYTAG,"       currentHelpScreen invalid:  " + currentSettingsScreen);
        }

        return currentSettingsScreen;
    }

    
    public static int getCurrentHelpScreen()
    {
        if( ( currentHelpScreen < 0 ) || ( currentHelpScreen > 1 ) )
        {
            Log.d(MYTAG,"Error: XflashScreen.getCurrentHelpScreen()");
            Log.d(MYTAG,"       currentHelpScreen invalid:  " + currentHelpScreen);
        }

        return currentHelpScreen;
    }



}  // end XflashScreen class declaration


