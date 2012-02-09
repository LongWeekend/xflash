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
//  public static void popBackPractice()
//  public static void setPracticeOverride()
//  public static void clearPracticeScreens()
//  public void setScreenValues(String  )
//  public TabInfo getTransitionFragment(String  )
//  public void detachExtras(FragmentTransaction  )
//  public void detachSelectExtras(FragmentTransaction  ,String  )
//  public String goBack(String  )
//
//  public int getCurrentSettingsScreen()
//  public static void setCurrentSettingsType(int  )
//  public static int getCurrentSettingsType()
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

    public static final int LWE_SETTINGS_DIFFICULTY = 0;
    public static final int LWE_SETTINGS_WEB = 1;

    // properties for handling fragment view transitions
    private static int currentPracticeScreen = -1;
    private static int currentHelpScreen = -1;
    private static int currentSettingsScreen = -1;
    private static int currentSettingsType = -1;

    private static boolean overridePracticeCount;

    // the index of this array corresponds to the five tabs 
    // practice = 0, tag = 1, search = 2, settings = 3, help = 4
    private static boolean[] extraScreensOn;
    private static TabInfo[] extraFragments;

    // set all fragment page values to zero when starting app
    public static void fireUpScreenManager()
    {
        currentPracticeScreen = 0;
        currentHelpScreen = 0;
        currentSettingsScreen = 0;
    
        overridePracticeCount = false;
        
        extraScreensOn = new boolean[] { false, false, false, false, false };
        extraFragments = new TabInfo[] { null, null, null, null, null };
    } 

    // remove the last transition from the practice back stack
    public static void popBackPractice()
    {
        --currentPracticeScreen;
    }


    // called after scoring a card - sets flag to open a practice window WITHOUT
    // adding it to the 'backstack'
    public static void setPracticeOverride()
    {
        overridePracticeCount = true;
    }

    // when switching   practice mode <-> browse mode   clear practice backstack
    public static void clearPracticeScreens()
    {
        currentPracticeScreen = 0;
    }

    // set all necessary internal flags following a view change
    // (called for both  Xflash.onTabChanged()  and  Xflash.onScreenTransition()
    public static void setScreenValues(String inTag,int direction)
    {
        if( inTag == "practice" || inTag == "example_sentence" )
        {
            // the practice and example sentence screen can scroll in either direction
            if( ( direction == Xflash.DIRECTION_OPEN ) && !overridePracticeCount )
            {
                ++currentPracticeScreen;
            }
            else if( ( direction == Xflash.DIRECTION_CLOSE ) && !overridePracticeCount )
            {
                --currentPracticeScreen;
            }
            else if( overridePracticeCount )
            {
                overridePracticeCount = false;
            }

            if( ( currentPracticeScreen != 0 ) && ( inTag == "example_sentence" ) )
            {
                extraScreensOn[LWE_PRACTICE_TAB] = true;
            }
            else
            {
                extraScreensOn[LWE_PRACTICE_TAB] = false;
            }
        }
        else if( inTag == "settings" )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = false;
            currentSettingsScreen = 0;
        }
        else if( inTag == "difficulty" )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = true;
            currentSettingsScreen = 1;
        }
        else if( inTag == "settings_web" )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = true;
            currentSettingsScreen = 1;
        }
        else if( inTag == "help" )
        {
            extraScreensOn[LWE_HELP_TAB] = false;
            currentHelpScreen = 0;
        }
        else if( inTag == "help_page" )
        {
            extraScreensOn[LWE_HELP_TAB] = true;
            currentHelpScreen = 1;
        }

    }  // end setScreenValues()

    
    // takes the 'tag' of a view fragment and returns the TabInfo containing
    // that fragment's information
    // ONLY USED FOR EXTRA SCREENS, as the TabInfo data for the primary tab
    // screens is held and controlled by Xflash.class and the tab host
    public static TabInfo getTransitionFragment(String inTag)
    {
        if( inTag == "example_sentence" )
        {
            if( extraFragments[LWE_PRACTICE_TAB] == null ) 
            {    
                extraFragments[LWE_PRACTICE_TAB] = new TabInfo("example_sentence", ExampleSentenceFragment.class, null);
            }

            return extraFragments[LWE_PRACTICE_TAB];
        }
        else if( inTag == "difficulty" )
        {
            // if we haven't instantiated our extra screen, or if we have 
            // and it's the wrong one
            if( ( extraFragments[LWE_SETTINGS_TAB] == null ) ||
                ( extraFragments[LWE_SETTINGS_TAB].tag != "difficulty" ) )
            {    
                extraFragments[LWE_SETTINGS_TAB] = new TabInfo("difficulty", DifficultyFragment.class, null);
            }

            return extraFragments[LWE_SETTINGS_TAB];
        }
        else if( inTag == "settings_web" )
        {
            // if we haven't instantiated our extra screen, or if we have 
            // and it's the wrong one
            if( ( extraFragments[LWE_SETTINGS_TAB] == null ) ||
                ( extraFragments[LWE_SETTINGS_TAB].tag != "settings_web" ) )
            {    
                extraFragments[LWE_SETTINGS_TAB] = new TabInfo("settings_web", SettingsWebFragment.class, null);
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
        if( ( inTag == "practice" ) && ( extraScreensOn[LWE_PRACTICE_TAB] == true ) )
        {
            if( extraFragments[LWE_PRACTICE_TAB].fragment != null )
            {
                ft.detach(extraFragments[XflashScreen.LWE_PRACTICE_TAB].fragment);
                extraScreensOn[LWE_PRACTICE_TAB] = false;
            }
        }
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
        // check each tab for which we have extra screens
        // if we aren't on the root screen for that tab, return
        // the new screen in line, otherwise do nothing to return null
        if( currentTab == "practice" )
        { 
            if( currentPracticeScreen != 0 )
            {
                return "practice";
            }     
        }
        else if( currentTab == "settings" )
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


    public static int getCurrentPracticeScreen()
    {
        return currentPracticeScreen;
    }

    
    public static int getCurrentSettingsScreen()
    {
        if( ( currentSettingsScreen < 0 ) || ( currentSettingsScreen > 1 ) )
        {
            Log.d(MYTAG,"Error: XflashScreen.getCurrentSettingsScreen()");
            Log.d(MYTAG,"       currentSettingsScreen invalid:  " + currentSettingsScreen);
        }

        return currentSettingsScreen;
    }

   
    public static void setCurrentSettingsType(int inType)
    {
        currentSettingsType = inType;
    }
 
    public static int getCurrentSettingsType()
    {
        if( ( currentSettingsScreen < 0 ) || ( currentSettingsScreen > 1 ) )
        {
            Log.d(MYTAG,"Error: XflashScreen.getCurrentSettingsType()");
            Log.d(MYTAG,"       currentSettingsType invalid:  " + currentSettingsType);
        }

        return currentSettingsType;
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


