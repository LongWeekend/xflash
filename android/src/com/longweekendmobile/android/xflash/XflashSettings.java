package com.longweekendmobile.android.xflash;

//  XflashSettings.java
//  Xflash
//
//  Created by Todd Presson on 2/5/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  a class to maintain all of the app level settings

import android.content.SharedPreferences;
import android.util.Log;
import android.view.View;
import android.widget.RelativeLayout;

public class XflashSettings
{
    private static final String MYTAG = "XFlash XflashSettings";

    // properties for global app settings
    private static int colorScheme = -1;
    private static int studyMode = -1;
    private static int studyLanguage = -1;
    private static int readingMode = -1;
    private static int difficultyMode = -1;
    private static int customStudyPool = -1;
    private static int customFrequency = -1;
    private static int currentUser = -1;

    // COLOR SETTINGS PROPERTIES
    private static final int LWE_THEME_RED = 0;
    private static final int LWE_THEME_BLUE = 1;
    private static final int LWE_THEME_TAME = 2;
   
    public static final int LWE_ICON_FOLDER = 0;
    public static final int LWE_ICON_SPECIAL_FOLDER = 1;  
    public static final int LWE_ICON_TAG = 2;
    public static final int LWE_ICON_STARRED_TAG = 3;

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

    public static final int LWE_FREQUENCY_EASY = 0;
    public static final int LWE_FREQUENCY_MEDIUM = 1;
    public static final int LWE_FREQUENCY_HARD = 2;
    public static final int LWE_FREQUENCY_MAX = 3;

    public static final int LWE_DEFAULT_USER = 1;
    
    // load all settings from Preferences on start
    public static void load()
    {
        // get a Context, get the SharedPreferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        // on error, default to RED scheme
        colorScheme = settings.getInt("colorScheme",LWE_THEME_RED);
        studyMode = settings.getInt("studyMode",LWE_STUDYMODE_PRACTICE);
        studyLanguage = settings.getInt("studyLanguage",LWE_STUDYLANGUAGE_JAPANESE);
        readingMode = settings.getInt("readingMode",LWE_STUDYLANGUAGE_JAPANESE);
        difficultyMode = settings.getInt("difficultyMode",LWE_DIFFICULTY_EASY);
        customStudyPool = settings.getInt("customStudyPool",LWE_STUDYPOOL_HARD);
        customFrequency = settings.getInt("customFrequency",LWE_FREQUENCY_HARD);
        currentUser = settings.getInt("currentUser",LWE_DEFAULT_USER);
    }


//  *** COLOR SETTINGS ***

    public static int getColorScheme()
    {
        return colorScheme;
    }

    
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
   

    // returns an int[4] of resource IDs for tag icons
    // in order: LWE_ICON_FOLDER , LWE_ICON_SPECIAL_FOLDER , LWE_ICON_TAG , LWE_ICON_STARRED_TAG
    public static int[] getTagIcons()
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
    }
 

//  *** STUDY MODE SETTINGS ***


    public static int getStudyMode()
    {
        return studyMode;
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
   
       
//  *** STUDY LANGUAGE SETTINGS ***

    public static int getStudyLanguage()
    {
        return studyLanguage;
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
   
//  *** CURRENT USER SETTINGS ***

    public static int getCurrentUserId()
    {
        if( currentUser < 0 )
        {
            Log.d(MYTAG,"Error in getCurrentUserId()  :  currentUser invalid:  " + currentUser);
        }
        
        return currentUser;
    }

    public static void setCurrentUser(int inUser)
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
    }

    public static int getCustomStudyPool()
    {
        return customStudyPool;
    }

    // sets the custom study pool seek value and saves for persistence
    public static void setCustomStudyPool(int inMode)
    {
        if( ( customStudyPool < LWE_STUDYPOOL_MIN ) || ( customStudyPool > LWE_STUDYPOOL_MAX ) )
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
    
    public static int getCustomFrequency()
    {
        return customFrequency;
    }

    // sets the custom card frequency and saves for persistence
    public static void setCustomFrequency(int inFrequency)
    {
        if( ( customFrequency < LWE_FREQUENCY_EASY ) || ( customFrequency > LWE_FREQUENCY_MAX ) )
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


    // method to throw an exception when attempting to set any of the
    // settings to an invalid value
    public static void throwBadValue(String method,int value)
    {
        String error = "invalid value passed to XflashSettings." + method + "(" + value + ")";
        
        throw new RuntimeException(error);    
    }

}  // end XflashSettings class declaration




