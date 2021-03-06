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
//      operate on dynamic number of tabs, with a dynamic number
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
//  public void popBackPractice()
//  public void setPracticeOverride()
//  public void setScreenValues(String  )
//  public TabInfo getTransitionFragment(String  )
//  public void addTagStack()
//  public void popTagStack()
//  public void detachExtras(FragmentTransaction  )
//  public String goBack(String  )
//
//  public static boolean getTagCardsOn()
//  public static boolean getEditTagOn()
//  public static boolean getAddCardToTagOn()
//
//  public static void resetPracticeScreen()
//  public static int getCurrentPracticeScreen()
//  public static int getCurrentTagScreen()
//  public static int getCurrentSearchScreen()
//  public int getCurrentSettingsScreen()
//  public void setCurrentSettingsType(int  )
//  public int getCurrentSettingsType()
//  public int getCurrentHelpScreen()

import java.util.ArrayList;

import android.support.v4.app.FragmentTransaction;
import android.util.Log;

import com.longweekendmobile.android.xflash.model.Group;

public class XflashScreen 
{
    private static final String MYTAG = "XFlash XflashScreen";
    
    private static final int LWE_PRACTICE_TAB = 0; 
    private static final int LWE_TAG_TAB = 1; 
    private static final int LWE_SEARCH_TAB = 2; 
    private static final int LWE_SETTINGS_TAB = 3; 
    private static final int LWE_HELP_TAB = 4; 

    // settings page extra screen ids 
    public static final int LWE_SETTINGS_DIFFICULTY = 0;
    public static final int LWE_SETTINGS_REMINDERS = 1;
    public static final int LWE_SETTINGS_USER = 2;
    public static final int LWE_SETTINGS_EDIT_USER = 3;
    public static final int LWE_SETTINGS_UPDATE = 4;
    public static final int LWE_SETTINGS_WEB = 5;

    // properties for screen transitions
    public static final int LWE_TAB_ROOT_SCREEN = 0;
    public static final int DIRECTION_CLOSE = 0;
    public static final int DIRECTION_OPEN = 1;
    public static final int DIRECTION_NULL = -1;

    // properties for how many screens we are away from tab root screen
    private static int currentPracticeScreen = -1;
    private static int currentTagScreen = -1;
    private static int currentSearchScreen = -1;
    private static int currentHelpScreen = -1;
    private static int currentSettingsScreen = -1;
    
    // properties for keeping track of the currently active screen
    private static int currentSettingsType = -1;

    private static boolean overridePracticeCount;

    // the index of this array corresponds to the five tabs 
    // practice = 0, tag = 1, search = 2, settings = 3, help = 4
    // used solely to determine what to detach during Xflash.onTabChanged
    private static boolean[] extraScreensOn;
    private static boolean tagCardsOn;
    private static boolean editTagOn;
    private static boolean addCardToTagOn;

    private static TabInfo[] extraFragments;
    private static ArrayList<Group> tagStack;


    // set all fragment page values to zero when starting app
    public static void fireUpScreenManager()
    {
        // start all tabs at root screen
        currentPracticeScreen = 0;
        currentTagScreen = 0;
        currentSearchScreen = 0;
        currentHelpScreen = 0;
        currentSettingsScreen = 0;
        
        currentSettingsType = 0;
    
        overridePracticeCount = false;
        
        // initialize extra screens to null
        extraScreensOn = new boolean[] { false, false, false, false, false };
        tagCardsOn = false;
        editTagOn = false;
        addCardToTagOn= false;
        
        extraFragments = new TabInfo[] { null, null, null, null, null };
        tagStack = null;
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


    // set all necessary internal flags following a view change
    // (called for both  Xflash.onTabChanged()  and  Xflash.onScreenTransition()
    public static void setScreenValues(String inTag,int direction)
    {
        if( inTag == "practice" )
        {
            if( overridePracticeCount )
            {
                overridePracticeCount = false;
            }

            extraScreensOn[LWE_PRACTICE_TAB] = false;
        }
        else if( inTag == "tag" )
        {
            if( extraScreensOn[LWE_TAG_TAB] == true )
            {
                // if they are going back from a TagCardsFragment
                extraScreensOn[LWE_TAG_TAB] = false;
                --currentTagScreen;
            }
            else
            {
                if( direction == DIRECTION_OPEN )
                {
                    ++currentTagScreen;
                }
                else if( direction == DIRECTION_CLOSE )
                {
                    --currentTagScreen;
                    
                    if( currentTagScreen == 0 )
                    {
                        tagStack = null;
                    }
                }
            }
        }
        else if( inTag == "tag_cards" )
        {
            extraScreensOn[LWE_TAG_TAB] = true;
            tagCardsOn = true;
            
            if( direction == DIRECTION_OPEN )
            {
                // coming from TagFragment
                ++currentTagScreen;
            }
            else if( direction == DIRECTION_CLOSE )
            {
                // coming from AddCardToTagFragment or EditTagFragment
                editTagOn = false;
                addCardToTagOn = false;     
                --currentTagScreen;
            }
        }
        else if( inTag == "edit_tag" )
        {
            extraScreensOn[LWE_TAG_TAB] = true;
            editTagOn = true;
            
            if( direction == DIRECTION_OPEN )
            {
                // coming from TagCardsFragment
                tagCardsOn = false;
                ++currentTagScreen;
            }
        }
        else if( inTag == "add_card" )
        {
            extraScreensOn[LWE_TAG_TAB] = true;
            addCardToTagOn = true;
            
            if( direction == DIRECTION_OPEN )
            {
                // coming from TagCardsFragment
                tagCardsOn = false;
                ++currentTagScreen;
            }
        }
        else if( inTag == "search" )
        {
            extraScreensOn[LWE_SEARCH_TAB] = false;
            currentSearchScreen = 0;
        }
        else if( inTag == "search_add_card" )
        {
            extraScreensOn[LWE_SEARCH_TAB] = true;
            currentSearchScreen = 1;
        }
        else if( inTag == "settings" )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = false;
            currentSettingsScreen = 0;
        }
        else if( ( inTag == "difficulty" ) || ( inTag == "reminders") ||
                 ( inTag == "user" ) || ( inTag == "update" ) || 
                 ( inTag == "settings_web" ) )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = true;
            currentSettingsScreen = 1;
        }
        else if( inTag == "edit_user" )
        {
            extraScreensOn[LWE_SETTINGS_TAB] = true;
            currentSettingsScreen = 2;
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
        if( inTag == "tag_cards" )
        {
            if( ( extraFragments[LWE_TAG_TAB] == null ) ||
                ( extraFragments[LWE_TAG_TAB].tag != "tag_cards" ) )
            {    
                extraFragments[LWE_TAG_TAB] = new TabInfo("tag_cards", TagCardsFragment.class, null);
            }

            return extraFragments[LWE_TAG_TAB];
        }
        if( inTag == "edit_tag" )
        {
            if( ( extraFragments[LWE_TAG_TAB] == null ) ||
                ( extraFragments[LWE_TAG_TAB].tag != "edit_tag" ) )
            {    
                extraFragments[LWE_TAG_TAB] = new TabInfo("edit_tag", EditTagFragment.class, null);
            }

            return extraFragments[LWE_TAG_TAB];
        }
        if( inTag == "add_card" )
        {
            if( ( extraFragments[LWE_TAG_TAB] == null ) ||
                ( extraFragments[LWE_TAG_TAB].tag != "add_card" ) )
            {    
                extraFragments[LWE_TAG_TAB] = new TabInfo("add_card", AddCardToTagFragment.class, null);
            }

            return extraFragments[LWE_TAG_TAB];
        }
        if( inTag == "search_add_card" )
        {
            if( extraFragments[LWE_SEARCH_TAB] == null ) 
            {    
                // this will possible wind up with two instantiations of 
                // AddCardToTabFragment, one in extraFragments[LWE_TAG_TAB}
                // and the other in extraFragments[LWE_SEARCH_TAB]
                
                // this is NOT ideal, but at the moment I'm not thinking of an
                // easier way to deal with a single instantiation that would
                // NOT require a heavy reworking of detachExtras() and
                // setScreenValues("add_card")
                extraFragments[LWE_SEARCH_TAB] = new TabInfo("search_add_card", AddCardToTagFragment.class, null);
            }

            return extraFragments[LWE_SEARCH_TAB];
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
        else if( inTag == "reminders" )
        {
            // if we haven't instantiated our extra screen, or if we have 
            // and it's the wrong one
            if( ( extraFragments[LWE_SETTINGS_TAB] == null ) ||
                ( extraFragments[LWE_SETTINGS_TAB].tag != "reminders" ) )
            {    
                extraFragments[LWE_SETTINGS_TAB] = new TabInfo("reminders", ReminderFragment.class, null);
            }

            return extraFragments[LWE_SETTINGS_TAB];
        }
        else if( inTag == "user" )
        {
            // if we haven't instantiated our extra screen, or if we have 
            // and it's the wrong one
            if( ( extraFragments[LWE_SETTINGS_TAB] == null ) ||
                ( extraFragments[LWE_SETTINGS_TAB].tag != "user" ) )
            {    
                extraFragments[LWE_SETTINGS_TAB] = new TabInfo("user", UserFragment.class, null);
            }

            return extraFragments[LWE_SETTINGS_TAB];
        }
        else if( inTag == "edit_user" )
        {
            // if we haven't instantiated our extra screen, or if we have 
            // and it's the wrong one
            if( ( extraFragments[LWE_SETTINGS_TAB] == null ) ||
                ( extraFragments[LWE_SETTINGS_TAB].tag != "edit_user" ) )
            {    
                extraFragments[LWE_SETTINGS_TAB] = new TabInfo("edit_user", EditUserFragment.class, null);
            }

            return extraFragments[LWE_SETTINGS_TAB];
        }
        else if( inTag == "update" )
        {
            // if we haven't instantiated our extra screen, or if we have 
            // and it's the wrong one
            if( ( extraFragments[LWE_SETTINGS_TAB] == null ) ||
                ( extraFragments[LWE_SETTINGS_TAB].tag != "update" ) )
            {    
                extraFragments[LWE_SETTINGS_TAB] = new TabInfo("update", UpdateFragment.class, null);
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


    public static void addTagStack()
    {
        if( tagStack == null )
        {   
            tagStack = new ArrayList<Group>();
        }
        
        tagStack.add( (Group)TagFragment.currentGroup.clone() );
        TagFragment.setNeedLoad();
    }

    public static void popTagStack()
    {
        int tempInt = ( tagStack.size() - 1 );

        TagFragment.currentGroup = (Group)tagStack.get(tempInt).clone();
        TagFragment.setNeedLoad();

        tagStack.remove(tempInt);
    }

    
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

    
    // return the 'tag' for any eligible fragment when the hardware
    // back button is pressed, or null if we are in root view state
    public static String goBack(String currentTab)
    {
        // check each tab for which we have extra screens
        // if we aren't on the root screen for that tab, return
        // the new screen in line, otherwise do nothing to return null
        if( currentTab == "tag" )
        { 
            if( currentTagScreen != 0 )
            {
                if( extraScreensOn[LWE_TAG_TAB] == false )
                {
                    popTagStack();
                    TagFragment.setNeedLoad();
                    
                    return "tag";
                }     
                else if( tagCardsOn == true )
                {
                    tagCardsOn = false;
                    
                    return "tag";
                }
                else if( editTagOn == true ) 
                {
                    editTagOn = false;
                    tagCardsOn = true;
                    
                    return "tag_cards";
                }
                else if( addCardToTagOn == true ) 
                {
                    addCardToTagOn = false;
                    tagCardsOn = true;
                    
                    return "tag_cards";
                }
            }
        }
        else if( currentTab == "search" )
        { 
            if( currentSearchScreen > 0 )
            {
                return "search";
            }     
        }
        else if( currentTab == "settings" )
        { 
            if( currentSettingsScreen > 0 )
            {
                if( currentSettingsScreen == 1 )
                {
                    return "settings";
                }
                else
                {
                    return "user";
                }
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


    public static boolean getTagCardsOn()
    {
        return tagCardsOn;
    }

    public static boolean getEditTagOn()
    {
        return editTagOn;
    }

    public static boolean getAddCardToTagOn()
    {
        return addCardToTagOn;
    }

    public static void resetPracticeScreen()
    {
        currentPracticeScreen = 0;
    }

    public static int getCurrentPracticeScreen()
    {
        return currentPracticeScreen;
    }

    public static int getCurrentTagScreen()
    {
        return currentTagScreen;
    }

    public static int getCurrentSearchScreen()
    {
        return currentSearchScreen;
    }

    
    public static int getCurrentSettingsScreen()
    {
        if( ( currentSettingsScreen < LWE_TAB_ROOT_SCREEN ) || ( currentSettingsScreen > 4 ) )
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
        // valid settings types (specific screens) range form 0 to 4
        if( ( currentSettingsType < 0 ) || ( currentSettingsType > 4 ) )
        {
            Log.d(MYTAG,"Error: XflashScreen.getCurrentSettingsType()");
            Log.d(MYTAG,"       currentSettingsType invalid:  " + currentSettingsType);
        }

        return currentSettingsType;
    }

    
    public static int getCurrentHelpScreen()
    {
        if( ( currentHelpScreen < LWE_TAB_ROOT_SCREEN ) || ( currentHelpScreen > 1 ) )
        {
            Log.d(MYTAG,"Error: XflashScreen.getCurrentHelpScreen()");
            Log.d(MYTAG,"       currentHelpScreen invalid:  " + currentHelpScreen);
        }

        return currentHelpScreen;
    }


}  // end XflashScreen class declaration


