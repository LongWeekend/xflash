package com.longweekendmobile.android.xflash;

//  SettingsFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void switchStudyMode()
//  public static void switchStudyLanguage()
//  public static void switchReadingMode()
//  public static void goDifficulty(Xflash  )
//  public static void switchAnswerSize()
//  public static void advanceColorScheme()
//  public static void goUser(Xflash  )
//  public static void goUpdate(Xflash  )
//  public static void launchSettingsWeb(View  ,Xflash  )

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.User;
import com.longweekendmobile.android.xflash.model.UserPeer;

public class SettingsFragment extends Fragment
{
    // private static final String MYTAG = "XFlash SettingsFragment";
    private static LinearLayout settingsLayout;

    public static boolean isTwitter = false;
    

    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Settings activity
        settingsLayout = (LinearLayout)inflater.inflate(R.layout.settings, container, false);

        // set the title bar to the current color scheme
        // this Activity does not need the onResume check present in
        // all other activities, because this Activity will never
        // start with an unexpected color change
        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)settingsLayout.findViewById(R.id.settings_heading);
        Button tempButton = (Button)settingsLayout.findViewById(R.id.settings_ratebutton);
 
        XflashSettings.setupColorScheme(titleBar,tempButton);
 
        // set the "Study Mode" label in our settings view
        TextView tempView = (TextView)settingsLayout.findViewById(R.id.settings_studymode_label);
        tempView.setText( XflashSettings.getStudyModeName() );
        
        // set the "Language Mode" label in our settings view
        tempView = (TextView)settingsLayout.findViewById(R.id.settings_studylanguage_label);
        tempView.setText( XflashSettings.getStudyLanguageName() );
        
        // set the "Furigana / Reading" label in our settings view
        tempView = (TextView)settingsLayout.findViewById(R.id.settings_furigana_label);
        tempView.setText( XflashSettings.getReadingModeName() );
        
        // set the answer text size label in our settings view
        tempView = (TextView)settingsLayout.findViewById(R.id.settings_answersize);
        tempView.setText( XflashSettings.getAnswerTextLabel() );
        
        // set the "Theme" label in our settings view
        tempView = (TextView)settingsLayout.findViewById(R.id.settings_theme_label);
        tempView.setText( XflashSettings.getColorSchemeName() );
       
        // and set the current user label
        User tempUser = UserPeer.getUserByPK( XflashSettings.getCurrentUserId() );
        tempView = (TextView)settingsLayout.findViewById(R.id.settings_activeuser_label);
        tempView.setText( tempUser.getUserNickname() ); 
     
        return settingsLayout;

    }  // end onCreateView()


    public static void switchStudyMode()
    {
        int tempMode = XflashSettings.getStudyMode();

        if( tempMode == XflashSettings.LWE_STUDYMODE_PRACTICE )
        {
            XflashSettings.setStudyMode(XflashSettings.LWE_STUDYMODE_BROWSE);
        }
        else
        {
            XflashSettings.setStudyMode(XflashSettings.LWE_STUDYMODE_PRACTICE);
        }
        
        // set the "Study Mode" label in our settings view
        TextView tempView = (TextView)settingsLayout.findViewById(R.id.settings_studymode_label);
        tempView.setText( XflashSettings.getStudyModeName() );

    }  // end switchStudyMode()
   

    public static void switchStudyLanguage()
    {
        int tempMode = XflashSettings.getStudyLanguage();

        if( tempMode == XflashSettings.LWE_STUDYLANGUAGE_JAPANESE )
        {
            XflashSettings.setStudyLanguage(XflashSettings.LWE_STUDYLANGUAGE_ENGLISH);
        }
        else
        {
            XflashSettings.setStudyLanguage(XflashSettings.LWE_STUDYLANGUAGE_JAPANESE);
        }
        
        // set the "Study Language" label in our settings view
        TextView tempView = (TextView)settingsLayout.findViewById(R.id.settings_studylanguage_label);
        tempView.setText( XflashSettings.getStudyLanguageName() );
    
    }  // end switchStudyLanguage()
   

    public static void switchReadingMode()
    {
        int tempMode = XflashSettings.getReadingMode();

        switch(tempMode) 
        {
            case XflashSettings.LWE_READINGMODE_BOTH:   
                                XflashSettings.setReadingMode(XflashSettings.LWE_READINGMODE_ROMAJI);
                                break;
            case XflashSettings.LWE_READINGMODE_ROMAJI:   
                                XflashSettings.setReadingMode(XflashSettings.LWE_READINGMODE_KANA);
                                break;
            case XflashSettings.LWE_READINGMODE_KANA:   
                                XflashSettings.setReadingMode(XflashSettings.LWE_READINGMODE_BOTH);
                                break;
            default:            break;
        }

        // set the "Furigana / Reading" label in our settings view
        TextView tempView = (TextView)settingsLayout.findViewById(R.id.settings_furigana_label);
        tempView.setText( XflashSettings.getReadingModeName() );
    
    }  // end switchStudyLanguage()
   

    // calls a new view activity for fragment tab layout 
    public static void goDifficulty(Xflash inContext)
    {
        // load the HelpPageFragment to the fragment tab manager
        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_DIFFICULTY);
        inContext.onScreenTransition("difficulty",XflashScreen.DIRECTION_OPEN);
    }

    
    // changes the answer text size in the PracticeFragment
    public static void switchAnswerSize()
    {
        int oldSize = XflashSettings.getAnswerTextSize();
        int newSize = -1;

        if( oldSize == XflashSettings.LWE_ANSWERTEXT_NORMAL )
        {
            newSize = XflashSettings.LWE_ANSWERTEXT_LARGE;
        }
        else
        {
            newSize = XflashSettings.LWE_ANSWERTEXT_NORMAL;
        }

        XflashSettings.setAnswerText(newSize);

        // reset the answer text size label 
        TextView tempView  = (TextView)settingsLayout.findViewById(R.id.settings_answersize);
        tempView.setText( XflashSettings.getAnswerTextLabel() );

    }  // end switchAnswerSize()


    public static void advanceColorScheme()
    {
        int tempScheme = XflashSettings.getColorScheme();

        // set our new color
        if(tempScheme == 2)
        {
            tempScheme = 0;
        }
        else
        {
            ++tempScheme;
        }

        // set our static color field
        XflashSettings.setColorScheme(tempScheme);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)settingsLayout.findViewById(R.id.settings_heading);
        Button tempButton = (Button)settingsLayout.findViewById(R.id.settings_ratebutton);

        XflashSettings.setupColorScheme(titleBar,tempButton);

        // and update the "Theme" label in our settings view
        TextView tempView = (TextView)settingsLayout.findViewById(R.id.settings_theme_label);
        tempView.setText( XflashSettings.getColorSchemeName() );

    }  // end advanceColorScheme()

    
    // calls a new view activity for fragment tab layout 
    public static void goUser(Xflash inContext)
    {
        // load the UserFragment to the fragment tab manager
        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_USER);
        inContext.onScreenTransition("user",XflashScreen.DIRECTION_OPEN);
    }

   
    public static void goUpdate(Xflash inContext)
    {
        // load the UpdateFragment to the fragment tab manager
        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_UPDATE);
        inContext.onScreenTransition("update",XflashScreen.DIRECTION_OPEN);
    }

 
    public static void launchSettingsWeb(View v,Xflash inContext)
    {
        if( v.getId() == R.id.settings_launch_twitter)
        {
            isTwitter = true;
        }
        else
        {
            isTwitter = false;
        }

        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_WEB);
        inContext.onScreenTransition("settings_web",XflashScreen.DIRECTION_OPEN);
    }


}  // end SettingsFragment class declaration




