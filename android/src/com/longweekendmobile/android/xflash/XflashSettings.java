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

    private static int colorScheme = -1;
    private static int studyMode = -1;
    private static int studyLanguage = -1;
    private static int readingMode = -1;

    // COLOR SETTINGS PROPERTIES
    private static final int LWE_THEME_RED = 0;
    private static final int LWE_THEME_BLUE = 1;
    private static final int LWE_THEME_TAME = 2;
    
    public static final int LWE_ICON_FOLDER = 0;
    public static final int LWE_ICON_SPECIAL_FOLDER = 1;  
    public static final int LWE_ICON_TAG= 2;
    public static final int LWE_ICON_STARRED_TAG= 3;

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
    }


//  *** COLOR SETTINGS ***

    public static int getColorScheme()
    {
        if( ( colorScheme < 0 ) || ( colorScheme > 2 ) )
        {
            Log.d(MYTAG,"Error in getColorScheme()  :  colorScheme invalid:  " + colorScheme); 
        }
    
        return colorScheme;
    }

    
    // sets the color scheme and saves for persistence
    public static void setColorScheme(int inColor)
    {
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
        if( ( studyMode < 0 ) || ( studyMode > 1 ) )
        {
            Log.d(MYTAG,"Error in getStudyMode()  :  studyMode invalid:  " + studyMode);
        }
    
        return studyMode;
    }

    
    // sets the color scheme and saves for persistence
    public static void setStudyMode(int inMode)
    {
        studyMode = inMode;
        
        // set the new color in the Preferences
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
        if( ( studyLanguage < 0 ) || ( studyLanguage > 1 ) )
        {
            Log.d(MYTAG,"Error in getStudyLanguage()  :  studyLanguage invalid:  " + studyLanguage);
        }

        return studyLanguage;
    }

    public static void setStudyLanguage(int inMode)
    {
        studyLanguage = inMode;
        
        // set the new color in the Preferences
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
   
//  *** READING MODE SETTINGS ***

    public static int getReadingMode()
    {
        if( ( readingMode < 0 ) || ( readingMode > 2 ) )
        {
            Log.d(MYTAG,"Error in getStudyLanguage()  :  studyLanguage invalid:  " + studyLanguage);
        }
        
        return readingMode;
    }

    public static void setReadingMode(int inMode)
    {
        readingMode = inMode;
        
        Log.d(MYTAG,"reading mode set: " + inMode);

        // set the new color in the Preferences
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
            default:                         return "Error";
        }
    }
   
       
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
        }

    }  // end setRadioColors()
 
}  // end XflashSettings class declaration




