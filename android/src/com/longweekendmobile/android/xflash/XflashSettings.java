package com.longweekendmobile.android.xflash;

//  XflashSettings.java
//  Xflash
//
//  Created by Todd Presson on 2/5/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  a class to maintain all of the app level settings
//
//      *** ALL METHODS STATIC ***
//
//  public void load()
//
//  public  void updateCheck()
//  public  void setActiveTag(Tag  )
//  public  Tag getActiveTag()
//  private int checkForBug(int  )                      --------- temporary?
//  private Tag checkForAnotherBug(Tag  )               --------- temporary? 
//  public  Card getActiveCard()
//  public static void setActiveCard(Card  )
//
//  public static void dumpObservers()
//
//  public int getColorScheme()
//  public String getColorSchemeName()
//  public String getThemeCSS()
//  public void setColorScheme(int  )
//  public void setupPracticeBack(RelativeLayout  )
//  public void setupColorScheme(RelativeLayout  )
//  public void setupColorScheme(RelativeLayout  ,View  )
//  public void setupColorScheme(RelativeLayout  ,View  )
//  public void setRadioColors(XflashRadio[]  )
//  public int[] getIcons()
//  public int[] getHHArray()
//
//  public int getStudyMode()
//  public String getStudyModeName()
//  public void setStudyMode(int  )
//  public int getStudyLanguage()
//  public String getStudyLanguageName()
//  public void setStudyLanguage(int  )
//  public int getCurrentUserId()
//  public void setCurrentUserId(int  )
//  public int getReadingMode()
//  public String getReadingModeName()
//  public void setReadingMode(int  )
//  public int getAnswerTextSize()
//  public int getAnswerTextLabel()
//  public String getAnswerSizeCSS()
//  public void setAnswerText(int  )
//  public int getDifficultyMode()
//  public void setDifficultyMode(int  )
//  public int getStudyPool()
//  public int getCustomStudyPool()
//  public void setCustomStudyPool(int  )
//  public int getFrequency()
//  public int getCustomFrequency()
//  public void setCustomFrequency(int  )
//  public boolean getHideLearned()
//  public boolean toggleHideLearned()
//  public boolean getRemindersOn()
//  public void setReminderCount(int  )
//  public int getReminderCount()
//  public String getReminderText()
//  public void toggleReminders()
//  public void setReminders()
//
//  private void throwBadValue(String  ,int  )

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;
import android.view.View;
import android.widget.RelativeLayout;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class XflashSettings
{
    private static final String MYTAG = "XFlash XflashSettings";

    // PRACTICE TAB STUFF
    private static Tag activeTag = null;
    private static Card activeCard = null;

    // COLOR SETTINGS PROPERTIES
    public static final int LWE_THEME_RED = 0;
    public static final int LWE_THEME_BLUE = 1;
    public static final int LWE_THEME_TAME = 2;
   
    // ICON SELECTION PROPERTIES
    public static final int LWE_ICON_FOLDER = 0;
    public static final int LWE_ICON_SPECIAL_FOLDER = 1;  
    public static final int LWE_ICON_TAG = 2;
    public static final int LWE_ICON_STARRED_TAG = 3;

    // arrays of resource IDs for use in setupScheme()
    // they are loaded such that their index corresponds to the appropriate
    // color scheme, i.e.  { LWE_THEME_RED , LWE_THEME_BLUE , LWE_THEME_TAME }
    // so that we can use colorScheme directly
    private static int[] backgroundIds = { R.drawable.practice_bg_red, 
                                           R.drawable.practice_bg_blue , 
                                           R.drawable.practice_bg_tame };
    private static int[] viewGradients = { R.drawable.gradient_red , R.drawable.gradient_blue ,
                                           R.drawable.gradient_tame };
    private static int[] buttonGradients = { R.drawable.button_red , R.drawable.button_blue , 
                                             R.drawable.button_tame };
            
    // red hot head drawable resources
    private static int[] redHeads = { R.drawable.red_hh_ecstatic, R.drawable.red_hh_happy,
                                      R.drawable.red_hh_jolly, R.drawable.red_hh_small_smile,
                                      R.drawable.red_hh_my_name_is_forest, 
                                      R.drawable.red_hh_uncommunicative, 
                                      R.drawable.red_hh_wounded, R.drawable.red_hh_losin_it,
                                      R.drawable.red_hh_pissed, R.drawable.red_hh_sea_sick,
                                      R.drawable.red_hh_wounded };

    // blue hot head drawable resources 
    private static int[] blueHeads = { R.drawable.blue_hh_ecstatic, R.drawable.blue_hh_happy,
                                       R.drawable.blue_hh_jolly, R.drawable.blue_hh_small_smile,
                                       R.drawable.blue_hh_my_name_is_forest, 
                                       R.drawable.blue_hh_uncommunicative, 
                                       R.drawable.blue_hh_wounded, R.drawable.blue_hh_losin_it,
                                       R.drawable.blue_hh_pissed, R.drawable.blue_hh_sea_sick,
                                       R.drawable.blue_hh_wounded };

    // reminder properties
    private static final int LWE_DEFAULT_REMINDERCOUNT = 4;

    // properties for global app settings
    private static int colorScheme = -1;
    private static int studyMode = -1;
    private static int studyLanguage = -1;
    private static int readingMode = -1;
    private static int difficultyMode = -1;
    private static int answerTextSize = -1;
    private static int customStudyPool = -1;
    private static int customFrequency = -1;
    private static int currentUser = -1;
    private static int reminderCount = -1;
    private static boolean hideLearnedCards = false;
    private static boolean remindersOn = false;

    // STUDY MODE PROPERTIES
    public static final int LWE_STUDYMODE_PRACTICE = 0;
    public static final int LWE_STUDYMODE_BROWSE = 1;

    // STUDY LANGUAGE PROPERTIES
    public static final int LWE_STUDYLANGUAGE_JAPANESE = 0;
    public static final int LWE_STUDYLANGUAGE_ENGLISH = 1;
        
    // READING MODE PROPERTIES
    public static final int LWE_READINGMODE_BOTH = 0;
    public static final int LWE_READINGMODE_ROMAJI= 1;
    public static final int LWE_READINGMODE_KANA = 2;

    // ANSWER TEXT PROPERTIES
    public static final int LWE_ANSWERTEXT_NORMAL = 0;
    public static final int LWE_ANSWERTEXT_LARGE = 1;

    // DIFFICULTY PROPERTIES
    public static final int LWE_DIFFICULTY_EASY = 0;
    public static final int LWE_DIFFICULTY_MEDIUM = 1;
    public static final int LWE_DIFFICULTY_HARD = 2;
    public static final int LWE_DIFFICULTY_CUSTOM = 3;

    private static final int LWE_STUDYPOOL_MIN = 5;
    public static final int LWE_STUDYPOOL_EASY = 15;
    public static final int LWE_STUDYPOOL_MEDIUM = 25;
    public static final int LWE_STUDYPOOL_HARD = 35;
    private static final int LWE_STUDYPOOL_MAX = 50;

    public static final int LWE_FREQUENCY_EASY = 1;
    public static final int LWE_FREQUENCY_MEDIUM = 2;
    public static final int LWE_FREQUENCY_HARD = 3;
    public static final int LWE_FREQUENCY_MAX = 4;

    public static final int LWE_DEFAULT_USER = 1;
    
    // load all settings from Preferences on start
    public static void load()
    {
        // get a Context, get the SharedPreferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        // load all settings to user set or default
        colorScheme = settings.getInt("colorScheme",LWE_THEME_RED);
        studyMode = settings.getInt("studyMode",LWE_STUDYMODE_PRACTICE);
        studyLanguage = settings.getInt("studyLanguage",LWE_STUDYLANGUAGE_JAPANESE);
        readingMode = settings.getInt("readingMode",LWE_STUDYLANGUAGE_JAPANESE);
        answerTextSize = settings.getInt("answerTextSize",LWE_ANSWERTEXT_NORMAL);
        difficultyMode = settings.getInt("difficultyMode",LWE_DIFFICULTY_MEDIUM);
        customStudyPool = settings.getInt("customStudyPool",LWE_STUDYPOOL_HARD);
        customFrequency = settings.getInt("customFrequency",LWE_FREQUENCY_HARD);
        currentUser = settings.getInt("currentUser",LWE_DEFAULT_USER);
        reminderCount = settings.getInt("reminderCount",LWE_DEFAULT_REMINDERCOUNT);
        hideLearnedCards = settings.getBoolean("hideLearnedCards",false);
        remindersOn = settings.getBoolean("remindersOn",false);

    }  // end load()


    // called to check for first-run or updates, display dialogs as appropriate
    public static void updateCheck()
    {
        // get a Context, get the SharedPreferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        int manifestVersionCode = 1;
        
        // get the current versionCode listed in AndroidManifest.xml
        try
        {
            manifestVersionCode = tempInstance.getPackageManager().getPackageInfo( tempInstance.getPackageName(), 0).versionCode;
        }
        catch(android.content.pm.PackageManager.NameNotFoundException e)
        {
            // this should not be possible, given we are pulling the
            // package name directly from the PackageManager we are 
            // feeding it back to. However, it pleases the compiler gods
            Log.d(MYTAG,"ERROR - in updateCheck(), bad package name");
            throw new RuntimeException("Oh well!");
        }
        
        // check if they is the first run of the app
        boolean hasRanBefore = settings.contains("lwe_jf_version");
        
        if( !hasRanBefore )
        {
            // this will save our version for later reference based on the 
            // versionCode we assign in AndroidManifest.xml 
            
            // if preferable we could pull a string value for versonName 
            // (in this case "1.0") and save it as a float value instead
            SharedPreferences.Editor editor = settings.edit();
            editor.putInt("lwe_jf_version",manifestVersionCode);
            editor.commit();        

            // fire update with first run (versionCode 1)
            XflashAlert.fireUpdate(manifestVersionCode);
        }
        else
        {
            // check for an update, if for some reason the Preferences broke
            // between settings.contains() and here, default to the code we 
            // just pulled from the Manifest so we end up doing nothing and
            // nothing goes wonky
            int savedVersionCode = settings.getInt("lwe_jf_version",manifestVersionCode);

            if( savedVersionCode != manifestVersionCode )
            {
                // save new version code
                SharedPreferences.Editor editor = settings.edit();
                editor.putInt("lwe_jf_version",manifestVersionCode);
                editor.commit();        

                // on snap, we got ourselves an udpate
                XflashAlert.fireUpdate(manifestVersionCode);
            }
        
        }  // end check for updates
    
    }  // end updateCheck()

 
    // called when any Fragment is setting a new Tag to study
    public static void setActiveTag(Tag inTag)
    {
        if( inTag.getCardCount() < 1 )
        {
            Log.d(MYTAG,"ERROR - in setActiveTag() : cardCount == 0");
        }
            
        // set the new tag id in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("active_tag", inTag.getId() );
        editor.commit();
    
        // set our actual active tag
        activeTag = inTag;
        activeTag.populateCards();
   
        // when we set the active tag, also set the active card
        // to the zero-index card of said new tag, and reset
        // the practice screen count
        activeTag.setCurrentIndex(0);
        activeCard = activeTag.flattenedCardArray.get(0);

        XFApplication.getNotifier().activeTagBroadcast();
       
    }  // end setActiveTag()


    // loads and returns XflashSettings.activeTag
    public static Tag getActiveTag()
    {
        // if active tag is null, pull the default (Long Weekend Favorites)
        if( ( activeTag == null ) || ( activeTag.getCardCount() < 1 ) )
        {
            // get a Context, get the SharedPreferences
            XFApplication tempInstance = XFApplication.getInstance();
            SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);
            
            // pull the saved tag id, default to 'Long Weekend Favorites'
            int tempTagId = settings.getInt("active_tag",Tag.DEFAULT_TAG_ID);
           
            // TODO - bug, pain in the ass
            tempTagId = checkForBug(tempTagId); 
            
            activeTag = TagPeer.retrieveTagById(tempTagId);
            activeTag.populateCards();
        }
            
        // TODO - another bug check
        activeTag = checkForAnotherBug(activeTag);
        
        return activeTag;

    }  // end getActiveTag()

 
/*
        So, as I mentioned in an email (to Mark) there is a quirk with some
        Samsung devices in that they override the standard directory that
        Android uses to save Preferences and SharedPreferences. The consequence
        of this is that you RETAIN ANY SAVED PREFERENCES WHEN YOU UNINSTALL
        THE APP.  Why they did this, and then failed to fix their shit so that
        it also uninstalled properly is unclear.
        That's not terrible, necessarily, but in cases like this:

        getActiveTag() is supposed to default to "Long Weekend Favorites" if 
        there is no active tag saved.   However!  While debugging and whatnot,
        if I make a new tag and EXIT THE APP WHILE STUDYING A USER CREATED TAG, 
        then uninstall and re-install the app, I will retain a saved Preference 
        with an active tag_id that is a HIGHER numeric value that any available 
        in the freshly re-installed database.  That causes an empty query 
        return when looking for our active tag in the database, and consequently 
        causes the app to throw an Exception immediatly on load.

        The purpose of this check is to make sure that isn't happening.
*/

    // TODO - bug, pain in the ass, probably not permanent
    private static int checkForBug(int inId)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();

        Cursor myCursor = tempDB.rawQuery("SELECT MAX(tag_id) FROM tags",null);
        myCursor.moveToFirst();

        int maxTagId = myCursor.getInt(0);
        myCursor.close();

        if( inId > maxTagId )
        {
            // got a problem! substitute "Long Weekend Favorites"
            return Tag.DEFAULT_TAG_ID;
        }
        else
        {
            // if the id is valid, return it for use
            return inId;
        }

    }  // end checkForBug()


    // TODO - another bug check
    private static Tag checkForAnotherBug(Tag inTag)
    {
        // until I get the bug sorted out in TagPeer.cancelMembership()
        // it's possible to drop down to zero cards in the active
        // Tag, causing major problems on load

        if( inTag.getCardCount() < 1 )
        {
            Log.d(MYTAG,">   we exited the app with a zero-card tag active");
            Log.d(MYTAG,">   defaulting to Long Weekend Favorites");

            Tag tempTag = TagPeer.retrieveTagById(Tag.DEFAULT_TAG_ID);
            
            return tempTag;
        }
        else
        {
            return inTag;
        }

    }  // end checkForAnotherBug()
 

    // called only on app exit, to clear static values
    public static void clearActiveTag()
    {
        activeTag = null;
    }

    
    // return the currently active Card
    public static Card getActiveCard()
    {
        // when we get the active card, if it's null, pull the
        // zero-index card of the active Tag
        if( activeCard == null )
        {
            if( activeTag == null )
            {
                activeTag = getActiveTag();
            }

            activeCard = activeTag.flattenedCardArray.get(0);
        }
        
        if( activeCard.isFault )
        {
            activeCard.hydrate();
        }
        
        return activeCard;
    }

    public static void setActiveCard(Card inCard)
    {
        activeCard = inCard;
    }

    
    // empties all fragment's observer properties - necessary because
    // of static crap... kind feel like this shouldn't be necessary
    // but oh well
    public static void dumpObservers()
    {
        AddCardToTagFragment.dumpObservers();
        PracticeFragment.dumpObservers();        
        TagCardsFragment.dumpObservers();
        TagFragment.dumpObservers();

        XFApplication.clearNotifier();

    }  // end dumpObservers()


//  *** COLOR SETTINGS ***

    public static int getColorScheme()
    {
        return colorScheme;
    }

    
    // return a String for the name of the current theme
    public static String getColorSchemeName()
    {
        switch(colorScheme)
        {
            case LWE_THEME_RED:     return "Fire";
            case LWE_THEME_BLUE:    return "Water";
            case LWE_THEME_TAME:    return "Tame";
            default:                return "Error";
        }

    }  // end getColorSchemeName()
   

    //  public static String getThemeCSS()
    public static String getThemeCSS()
    {
        switch(colorScheme)
        {
            case LWE_THEME_RED:     return "dfn, button { background-color:orange; border-color:yellow; }";
            case LWE_THEME_BLUE:    return "dfn { background-color:lightsteelblue; border-color:white; }";
            case LWE_THEME_TAME:    return "dfn { background-color:silver; border-color:darkslategray; }";
            default:                return "Error";
        }
    
    }  // end getThemeCSS()
    
    
    // sets the color scheme and saves for persistence
    public static void setColorScheme(int inColor)
    {
        // if the passed value is out of range
        if( ( colorScheme < LWE_THEME_RED ) || ( colorScheme > LWE_THEME_TAME ) )
        {
            throwBadValue("setColorScheme",inColor);
        }
    
        colorScheme = inColor;
        
        // set the new color in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("colorScheme",colorScheme);
        editor.commit();
    }

    
    // sets the background image for the PracticeActivity
    public static void setupPracticeBack(RelativeLayout inLayout)
    {
        inLayout.setBackgroundResource( backgroundIds[colorScheme] );
    }
   
 
    public static void setupColorScheme(RelativeLayout inLayout)
    {
        setupColorScheme(inLayout,null,null);
    }

    public static void setupColorScheme(RelativeLayout inLayout,View inButton1)
    {
        setupColorScheme(inLayout,inButton1,null);
    }


    // takes in views from the title bar of any given Activity and sets
    // the background drawables according to color scheme
    public static void setupColorScheme(RelativeLayout inLayout,View inButton1,View inButton2)
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

        
    // sets the color scheme for our radio button array in DifficultyFragment
    public static void setRadioColors(XflashRadio inArray[])
    {
        switch(colorScheme)
        {
            case LWE_THEME_RED:     inArray[0].setButtonDrawable(R.drawable.radio_red_left_flip);
                                    inArray[1].setButtonDrawable(R.drawable.radio_red_middle_flip);
                                    inArray[2].setButtonDrawable(R.drawable.radio_red_middle_flip);
                                    inArray[3].setButtonDrawable(R.drawable.radio_red_right_flip);
                                    break;
            case LWE_THEME_BLUE:    inArray[0].setButtonDrawable(R.drawable.radio_blue_left_flip);
                                    inArray[1].setButtonDrawable(R.drawable.radio_blue_middle_flip);
                                    inArray[2].setButtonDrawable(R.drawable.radio_blue_middle_flip);
                                    inArray[3].setButtonDrawable(R.drawable.radio_blue_right_flip);
                                    break;
            case LWE_THEME_TAME:    inArray[0].setButtonDrawable(R.drawable.radio_tame_left_flip);
                                    inArray[1].setButtonDrawable(R.drawable.radio_tame_middle_flip);
                                    inArray[2].setButtonDrawable(R.drawable.radio_tame_middle_flip);
                                    inArray[3].setButtonDrawable(R.drawable.radio_tame_right_flip);
                                    break;
            default:                break;
        }

    }  // end setRadioColors()
 
    
    // returns an int[4] of resource IDs for tag icons
    // in order: LWE_ICON_FOLDER , LWE_ICON_SPECIAL_FOLDER , LWE_ICON_TAG , LWE_ICON_STARRED_TAG
    public static int[] getIcons()
    {
        int[] tempIcons = null;

        switch(colorScheme)
        {
            case LWE_THEME_RED:     tempIcons = new int[] { R.drawable.folder_icon_red,
                                                            R.drawable.special_folder_icon_red,
                                                            R.drawable.tag_icon_red,
                                                            R.drawable.tag_starred_icon_red };
                                    break;
            case LWE_THEME_BLUE:    tempIcons = new int[] { R.drawable.folder_icon_blue,
                                                            R.drawable.special_folder_icon_blue,
                                                            R.drawable.tag_icon_blue,
                                                            R.drawable.tag_starred_icon_blue };
                                    break;
            case LWE_THEME_TAME:    tempIcons = new int[] { R.drawable.folder_icon_tame,
                                                            R.drawable.special_folder_icon_tame,
                                                            R.drawable.tag_icon_tame,
                                                            R.drawable.tag_starred_icon_tame };
                                    break;
            default:    Log.d(MYTAG,"Error in XflashSettings.getTagIcons() - invalid colorScheme: " + colorScheme);
        }
        
        return tempIcons; 

    }  // end getIcons()
 

    // returns and int[] of Hot Head image resources based on
    // current color theme
    public static int[] getHHArray()
    {
        if( colorScheme == LWE_THEME_BLUE )
        {
            return blueHeads;
        }
        else
        {
            // though there's a separate folder with separate images for red
            // and tame in the Obj C code, it looks like they're the same
            return redHeads;
        }
    
    }  // end getHHArray()


//  *** STUDY MODE SETTINGS ***


    public static int getStudyMode()
    {
        return studyMode;
    }

    
    // return a String for the name of the current study mode 
    public static String getStudyModeName()
    {
        switch(studyMode)
        {
            case LWE_STUDYMODE_PRACTICE:    return "Practice";
            case LWE_STUDYMODE_BROWSE:      return "Browse";
            default:                        return "Error";
        }
    }
   
       
    // sets the color scheme and saves for persistence
    public static void setStudyMode(int inMode)
    {
        if( ( studyMode != LWE_STUDYMODE_PRACTICE ) && ( studyMode != LWE_STUDYMODE_BROWSE ) )
        {
            throwBadValue("setStudyMode",inMode);
        }
    
        studyMode = inMode;
        
        // set the new study mode in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("studyMode",studyMode);
        editor.commit();
    }


//  *** STUDY LANGUAGE SETTINGS ***

    public static int getStudyLanguage()
    {
        return studyLanguage;
    }

    // return a String for the name of the current language mode 
    public static String getStudyLanguageName()
    {
        switch(studyLanguage)
        {
            case LWE_STUDYLANGUAGE_JAPANESE: return "Japanese";
            case LWE_STUDYLANGUAGE_ENGLISH:  return "English";
            default:                         return "Error";
        }
    }
  
    public static void setStudyLanguage(int inMode)
    {
        if( ( studyLanguage != LWE_STUDYLANGUAGE_JAPANESE ) &&
            ( studyLanguage != LWE_STUDYLANGUAGE_ENGLISH ) )
        {
            throwBadValue("setStudyLanguage",inMode);
        }

        studyLanguage = inMode;
        
        // set the new study language in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("studyLanguage",studyLanguage);
        editor.commit();
    }


//  *** CURRENT USER SETTINGS ***

    public static int getCurrentUserId()
    {
        if( currentUser < 0 )
        {
            Log.d(MYTAG,"Error in getCurrentUserId()  :  currentUser invalid:  " + currentUser);
        }
        
        return currentUser;
    }

    public static void setCurrentUserId(int inUser)
    {
        if( inUser < 0 )
        {
            throwBadValue("setCurrentUser",inUser);
        }

        currentUser = inUser;
        
        // set the new reading mode in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("currentUser",currentUser);
        editor.commit();
    }

//  *** READING MODE SETTINGS ***

    public static int getReadingMode()
    {
        return readingMode;
    }

    
    // return a String for the name of the current language mode 
    public static String getReadingModeName()
    {
        switch(readingMode)
        {
            case LWE_READINGMODE_BOTH:      return "Both";
            case LWE_READINGMODE_ROMAJI:    return "Romaji";
            case LWE_READINGMODE_KANA:      return "Kana";
            default:                        return "Error";
        }
    }
 
    public static void setReadingMode(int inMode)
    {
        if( ( readingMode < LWE_READINGMODE_BOTH ) || ( readingMode > LWE_READINGMODE_KANA ) )
        {
            throwBadValue("setReadingMode",inMode);
        }
        
        readingMode = inMode;
        
        // set the new reading mode in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("readingMode",readingMode);
        editor.commit();

    }  // end setReadingMode()


    public static int getAnswerTextSize()
    {
        return answerTextSize;
    }

    public static String getAnswerTextLabel()
    {
        if( answerTextSize == LWE_ANSWERTEXT_NORMAL )
        {
            return "Normal";
        }
        else
        {
            return "Large";
        }
    
    }  // end getAnswerTextLabel()

    
    // get CSS to be injected for displaying the answer in PracticeFragment
    public static String getAnswerSizeCSS()
    {
        // otherwise return size CSS based on size setting
        switch(answerTextSize)
        {
            case LWE_ANSWERTEXT_NORMAL:     return "font-size:14px;";
            case LWE_ANSWERTEXT_LARGE:      return "font-size:20px;";
            
            default: return "error";
        }

    }  // end getAnswerSizeCSS()


    public static void setAnswerText(int inSize)
    {
        if( ( inSize < LWE_ANSWERTEXT_NORMAL ) || ( inSize > LWE_ANSWERTEXT_LARGE ) )
        {
            throwBadValue("setAnswerText",inSize);
        }
        
        answerTextSize = inSize;
        
        // set the new reading mode in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("answerTextSize",answerTextSize);
        editor.commit();

    }  // end setAnswerText()


//  *** DIFFICULTY MODE SETTINGS ***
      
 
    public static int getDifficultyMode()
    {
        return difficultyMode;
    }

    // sets the difficulty and saves for persistence
    public static void setDifficultyMode(int inMode)
    {
        if( ( difficultyMode < LWE_DIFFICULTY_EASY ) || ( difficultyMode > LWE_DIFFICULTY_CUSTOM ) )
        {
            throwBadValue("setDifficultyMode",inMode);
        }
        
        difficultyMode = inMode;
        
        // set the new difficulty in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("difficultyMode",difficultyMode);
        editor.commit();

    }  // end setDifficultyMode()


    // return the study pool
    public static int getStudyPool()
    {
        if( difficultyMode == LWE_DIFFICULTY_CUSTOM )
        {
            return customStudyPool;
        }
        
        switch( difficultyMode )
        {
            case LWE_DIFFICULTY_EASY:      return LWE_STUDYPOOL_EASY;
            case LWE_DIFFICULTY_MEDIUM:    return LWE_STUDYPOOL_MEDIUM;
            case LWE_DIFFICULTY_HARD:      return LWE_STUDYPOOL_HARD;
            default:                       return -1;  // error
        }

    }  // end getStudyPool()

    
    public static int getCustomStudyPool()
    {
        return customStudyPool;
    }

    // sets the custom study pool seek value and saves for persistence
    public static void setCustomStudyPool(int inMode)
    {
        if( ( inMode < LWE_STUDYPOOL_MIN ) || ( inMode > LWE_STUDYPOOL_MAX ) )
        {
            throwBadValue("setCustomStudyPool",inMode);
        }
        
        customStudyPool = inMode;
        
        // set the new custom study pool seek value in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("customStudyPool",customStudyPool);
        editor.commit();
    }
    
    
    // return the frequency modifier
    public static int getFrequency()
    {
        if( difficultyMode == LWE_DIFFICULTY_CUSTOM )
        {
            return customFrequency;
        }
        
        switch( difficultyMode )
        {
            case LWE_DIFFICULTY_EASY:      return 1;
            case LWE_DIFFICULTY_MEDIUM:    return 2;
            case LWE_DIFFICULTY_HARD:      return 3;
            default:                       return -1;   // error
        }

    }  // end getFrequency()

    
    public static int getCustomFrequency()
    {
        return customFrequency;
    }

    // sets the custom card frequency and saves for persistence
    public static void setCustomFrequency(int inFrequency)
    {
        if( ( inFrequency < LWE_FREQUENCY_EASY ) || ( inFrequency > LWE_FREQUENCY_MAX ) )
        {
            throwBadValue("setCustomFrequency",inFrequency);
        }

        customFrequency = inFrequency;
        
        // set the new color in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("customFrequency",customFrequency);
        editor.commit();
    }


    // gets the current hide learned cards state
    public static boolean getHideLearned()
    {
        return hideLearnedCards;
    }


    // toggles the hide learned cards state and returns the new state
    public static boolean toggleHideLearned()
    {
        if( hideLearnedCards == false )
        {
            hideLearnedCards = true;
        }
        else
        {
            hideLearnedCards = false ;
        }

        // set the new state in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putBoolean("hideLearnedCards",hideLearnedCards);
        editor.commit();
        
        return hideLearnedCards;
    }

    
    public static boolean getRemindersOn()
    {
        return remindersOn;
    }


    // set the reminder count
    public static void setReminderCount(int inCount)
    {
        reminderCount = inCount;

        setReminders();
    }
    
    // return the current user-defined reminder day count
    public static int getReminderCount()
    {
        return reminderCount;
    }


    // return a string to display whether the study reminders are off/on
    public static String getReminderText()
    {
        Resources res = Xflash.getActivity().getResources();
        
        if( remindersOn )
        {
            return res.getString(R.string.just_on);
        }
        else
        {
            return res.getString(R.string.just_off);
        }

    }  // end getReminderText()


    public static void toggleReminders()
    {
        // get Preferences to update setting
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);
        SharedPreferences.Editor editor = settings.edit();
        
        if( remindersOn )
        {
            remindersOn = false;
        }
        else
        {
            remindersOn = true;
        }
       
        // update preferences
        editor.putBoolean("remindersOn",remindersOn);
        editor.commit();
        
        // set or clear the reminder
        setReminders();

    }  // end toggleReminders()


    // sets a new reminder based on the current value for reminder days
    // but only if reminders are set to on
    public static void setReminders()
    {
        // get Preferences to update alarm settings
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);
        SharedPreferences.Editor editor = settings.edit();
        
        // get the activity context
        Xflash myContext = Xflash.getActivity();
        
        // create an PendingIntent for our alarm
        Intent myIntent = new Intent(myContext, OnAlarmReceiver.class);
        PendingIntent alarmIntent = PendingIntent.getBroadcast(myContext, 0, myIntent, PendingIntent.FLAG_ONE_SHOT);
        
        // get the phone's alarm manager
        AlarmManager aMgr = (AlarmManager)myContext.getSystemService(Context.ALARM_SERVICE);
        
        if( remindersOn )
        {
            // save the days to wait
            editor.putInt("reminderCount",reminderCount);
            
            // create a variable holding the time to have the alarm go off
            long daysToWait = (long)(reminderCount * ( 24 * 60 * 60 * 1000 ) );
            long alarmTime = ( System.currentTimeMillis() + daysToWait );

            // save the alarm time to Preferences in case the phone is rebooted
            editor.putLong("alarmTime",alarmTime);
        
            // set the alarm
            aMgr.set(AlarmManager.RTC, alarmTime, alarmIntent);
        }
        else
        {
            // if we are turning the reminder off, clear it from Preferences
            // and delete it from the alarm manager
            editor.remove("alarmTime");
            aMgr.cancel(alarmIntent);      
        }

        // commit changes to the Preferences,
        editor.commit();

    }  // end setReminders() 

    
    // method to throw an exception when attempting to set any of the
    // settings to an invalid value
    private static void throwBadValue(String method,int value)
    {
        String error = "invalid value passed to XflashSettings." + method + "(" + value + ")";
        
        throw new RuntimeException(error);    
    }

}  // end XflashSettings class declaration




