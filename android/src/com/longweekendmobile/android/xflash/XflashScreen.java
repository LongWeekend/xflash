package com.longweekendmobile.android.xflash;

//  XflashScreen.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  PERSONAL NOTE: it would probably be more portable, more
//      conventional, and generally better design if this class 
//      were built on ArrayList objects, and coordinated to
//      operate on dynamic number of tabs, with a dynamic
//      of sub-screens, recognized by dynamically set name tags.
//
//      however, in switching to using Fragments we are now 
//      reconstructing each view on each view change, and I
//      feel it's worth keeping the class simple to avoid extra
//      object construction and garbage collection while the
//      phones resources are already taxed by the animation
//
//
//      *** ALL METHODS STATIC ***
//
//  public void fireUpScreenManager()
//  public void setScreenValues(String  )
//  public int[] getAnim(String  )
//  public TabInfo getTransitionFragment(String  )
//  public void detachExtras(FragmentTransaction  )
//  public void detachSelectExtras(FragmentTransaction  ,String  )
//  public String goBack(String  )
//
//  public int getCurrentSettingsScreen()
//  public int getCurrentHelpScreen()

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


    // set all necessary internal flags following a view change
    // (called for both  Xflash.onTabChanged()  and  Xflash.onScreenTransition()
    public static void setScreenValues(String inTag)
    {
        if( inTag == "settings" )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = false;
            currentSettingsScreen = 0;
        }
        else if( inTag == "help" )
        {
            extraScreensOn[LWE_HELP_TAB] = false;
            currentHelpScreen = 0;
        }
        else if( inTag == "difficulty" )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = true;
            currentSettingsScreen = 1;
        }
        else if( inTag == "help_page" )
        {
            extraScreensOn[LWE_HELP_TAB] = true;
            currentHelpScreen = 1;
        }

    }  // end setScreenValues()

    
    // takes the 'tag' of the view fragment we are transitioning to, and
    // returns an int[] contining the resource IDs of the appropriate
    // animation for  FragmentTransaction.setCustomAnimations(int incoming,int outgoing)
    // only called by  Xflash.onScreenTransition()
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

    }  // end getAnim()


    // takes the 'tag' of a view fragment and returns the TabInfo containing
    // that fragment's information
    // ONLY USED FOR EXTRA SCREENS, as the TabInfo data for the primary tab
    // screens is held and controlled by Xflash.class and the tab host
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

    }  // end getTransitionFragment()


    // called by Xflash.onTabChanged() to detach any extra screen fragments
    public static void detachExtras(FragmentTransaction ft)
    {
        // cycle through each tab, looking for attached extra screens
        for(int i = XflashScreen.LWE_PRACTICE_TAB; i <= XflashScreen.LWE_HELP_TAB; i++)
        {
            if( extraScreensOn[i] )
            {
                ft.detach(extraFragments[i].fragment);
                extraScreensOn[i] = false;
            }
        }
    }

    // called by Xflash.onScreenTransition() to detach a specific extra screen
    public static void detachSelectExtras(FragmentTransaction ft,String inTag)
    {
        // when transitioning to a specific screen (inTag) away from a single
        // extra screen, we already know exactly which fragment to detach
        if( inTag == "settings" )
        {
            if( extraFragments[LWE_SETTINGS_TAB].fragment != null )
            {
                ft.detach(extraFragments[XflashScreen.LWE_SETTINGS_TAB].fragment);
                extraScreensOn[LWE_SETTINGS_TAB] = false;
            }
        }
        else if( inTag == "help" )
        {
            if( extraFragments[LWE_HELP_TAB].fragment != null )
            {
                ft.detach(extraFragments[XflashScreen.LWE_HELP_TAB].fragment);
                extraScreensOn[LWE_HELP_TAB] = false;
            }
        }

    }  // end detachSelectExtras()


    // return the 'tag' for any eligible fragment when the hardware
    // back button is pressed, or null if we are in root view state
    public static String goBack(String currentTab)
    {
        if( currentTab == "settings" )
        { 
            if( currentSettingsScreen > 0 )
            {
                return "settings";
            }     
        }
        else if( currentTab == "help" )
        {
            if( currentHelpScreen > 0 )
            {
                return "help";
            }
        }

        // no available screens, return null for app exit
        return null;

    }  // end goBack()


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


