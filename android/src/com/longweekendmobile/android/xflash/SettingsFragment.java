package com.longweekendmobile.android.xflash;

//  SettingsFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  private void switchStudyMode()
//  private void switchStudyLanguage()
//  private void switchReadingMode()
//  private void goDifficulty()
//  private void switchAnswerSize()
//  private void advanceColorScheme()
//  private void goReminders()
//  private void goUser()
//  private void goUpdate()
//  private void launchSettingsWeb(View  )
//
//  private void setClickBackgrounds()
//  private void setClickListeners()

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
    
    private LinearLayout settingsLayout;

    public static final int LOAD_TWITTER = 0;
    public static final int LOAD_FACEBOOK = 1;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Settings activity
        settingsLayout = (LinearLayout)inflater.inflate(R.layout.settings, container, false);

        // set the title bar to the current color scheme
        RelativeLayout titleBar = (RelativeLayout)settingsLayout.findViewById(R.id.settings_heading);
        Button rateButton = (Button)settingsLayout.findViewById(R.id.settings_ratebutton);
 
        XflashSettings.setupColorScheme(titleBar,rateButton);
 
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
      
        // set the "Study Reminders" label in our settings view
        tempView = (TextView)settingsLayout.findViewById(R.id.settings_reminder_label);
        tempView.setText( XflashSettings.getReminderText() );

        // and set the current user label
        User tempUser = UserPeer.getUserByPK( XflashSettings.getCurrentUserId() );
        tempView = (TextView)settingsLayout.findViewById(R.id.settings_activeuser_label);
        tempView.setText( tempUser.getUserNickname() ); 
     
        // set click listeners for all of our views
        setClickBackgrounds();
        setClickListeners();
        
        return settingsLayout;

    }  // end onCreateView()


    private void switchStudyMode()
    {
        int tempStudyMode = XflashSettings.getStudyMode();

        if( tempStudyMode == XflashSettings.LWE_STUDYMODE_PRACTICE )
        {
            XflashSettings.setStudyMode(XflashSettings.LWE_STUDYMODE_BROWSE);
        }
        else
        {
            XflashSettings.setStudyMode(XflashSettings.LWE_STUDYMODE_PRACTICE);
        }
        
        // set the "Study Mode" label in our settings view
        TextView studyModeLabel = (TextView)settingsLayout.findViewById(R.id.settings_studymode_label);
        studyModeLabel.setText( XflashSettings.getStudyModeName() );

    }  // end switchStudyMode()
   

    private void switchStudyLanguage()
    {
        int tempLanguage = XflashSettings.getStudyLanguage();

        if( tempLanguage == XflashSettings.LWE_STUDYLANGUAGE_JAPANESE )
        {
            XflashSettings.setStudyLanguage(XflashSettings.LWE_STUDYLANGUAGE_ENGLISH);
        }
        else
        {
            XflashSettings.setStudyLanguage(XflashSettings.LWE_STUDYLANGUAGE_JAPANESE);
        }
        
        // set the "Study Language" label in our settings view
        TextView studyLanguageLabel = (TextView)settingsLayout.findViewById(R.id.settings_studylanguage_label);
        studyLanguageLabel.setText( XflashSettings.getStudyLanguageName() );
    
    }  // end switchStudyLanguage()
   

    private void switchReadingMode()
    {
        int tempReadingMode = XflashSettings.getReadingMode();

        switch(tempReadingMode) 
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
        TextView furiganaReadingLabel = (TextView)settingsLayout.findViewById(R.id.settings_furigana_label);
        furiganaReadingLabel.setText( XflashSettings.getReadingModeName() );
    
    }  // end switchReadingMode()
   

    // calls a new view activity for fragment tab layout 
    private void goDifficulty()
    {
        // load the HelpPageFragment to the fragment tab manager
        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_DIFFICULTY);
        Xflash.getActivity().onScreenTransition("difficulty",XflashScreen.DIRECTION_OPEN);
    }

    
    // changes the answer text size in the PracticeFragment
    private void switchAnswerSize()
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
        TextView answerSize = (TextView)settingsLayout.findViewById(R.id.settings_answersize);
        answerSize.setText( XflashSettings.getAnswerTextLabel() );

    }  // end switchAnswerSize()


    private void advanceColorScheme()
    {
        int tempScheme = XflashSettings.getColorScheme();

        // set our new color
        if( tempScheme == XflashSettings.LWE_THEME_TAME )
        {
            tempScheme = XflashSettings.LWE_THEME_RED;
        }
        else
        {
            ++tempScheme;
        }

        // set our static color field
        XflashSettings.setColorScheme(tempScheme);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)settingsLayout.findViewById(R.id.settings_heading);
        Button rateButton = (Button)settingsLayout.findViewById(R.id.settings_ratebutton);

        XflashSettings.setupColorScheme(titleBar,rateButton);

        // and update the "Theme" label in our settings view
        TextView themeLabel = (TextView)settingsLayout.findViewById(R.id.settings_theme_label);
        themeLabel.setText( XflashSettings.getColorSchemeName() );

    }  // end advanceColorScheme()

    
    // load the ReminderFragment to the fragment tab manager
    private void goReminders()
    {
        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_REMINDERS);
        Xflash.getActivity().onScreenTransition("reminders",XflashScreen.DIRECTION_OPEN);
    }

   
    // load the UserFragment to the fragment tab manager
    private void goUser()
    {
        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_USER);
        Xflash.getActivity().onScreenTransition("user",XflashScreen.DIRECTION_OPEN);
    }


/* 
    private void goUpdate()
    {
        // load the UpdateFragment to the fragment tab manager
        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_UPDATE);
        Xflash.getActivity().onScreenTransition("update",XflashScreen.DIRECTION_OPEN);
    }
*/


    private void launchSettingsWeb(View v)
    {
        if( v.getId() == R.id.settings_launch_twitter )
        {
            SettingsWebFragment.setPage(LOAD_TWITTER);
        }
        else
        {
            SettingsWebFragment.setPage(LOAD_FACEBOOK);
        }

        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_WEB);
        Xflash.getActivity().onScreenTransition("settings_web",XflashScreen.DIRECTION_OPEN);
    }

   
    // set the click-backgrounds for all relevant views
    private void setClickBackgrounds()
    {
        // difficult row
        RelativeLayout tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.godifficulty_block);
        tempLayout.setBackgroundResource( XflashSettings.getBottomByColor() );
    
        // study reminder row
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.reminder_block);
        tempLayout.setBackgroundResource( XflashSettings.getMiddleByColor() );
    
        // active user row
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.activeuser_block);
        tempLayout.setBackgroundResource( XflashSettings.getBottomByColor() );
    
        // Twitter row
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.settings_launch_twitter);
        tempLayout.setBackgroundResource( XflashSettings.getTopByColor() );
    
        // Facebook row
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.settings_launch_facebook);
        tempLayout.setBackgroundResource( XflashSettings.getBottomByColor() );
    
    }  // end setClickBackgrounds()


    // set click listeners for all views
    private void setClickListeners()
    {
        // the study mode bar  ( practice / browse )
        RelativeLayout tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.studymode_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                switchStudyMode();
            }
        });

        // the study language bar  ( japanese / english )
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.studylanguage_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                switchStudyLanguage();
            }
        });

        // the furigana / reading bar  ( both / romaji / kana )
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.furiganareading_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                switchReadingMode();
            }
        });

        // the answer size bar  ( normal / large )
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.answersize_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                switchAnswerSize();
            }
        });

        // the launch DifficultyFragment bar
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.godifficulty_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                goDifficulty();
            }
        });

        // the color theme bar ( fire / water / tame )
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.colortheme_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                advanceColorScheme();
                setClickBackgrounds();
            }
        });

        // the study reminders bar
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.reminder_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                goReminders();
            }
        });
        
        // the active user bar ( various )
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.activeuser_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                goUser();
            }
        });

        
/*
        // the update bar ( x installed )
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.update_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                goUpdate();
            }
        });
*/

        // the twitter bar 
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.settings_launch_twitter);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                launchSettingsWeb(v);
            }
        });

        // the facebook bar 
        tempLayout = (RelativeLayout)settingsLayout.findViewById(R.id.settings_launch_facebook);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                launchSettingsWeb(v);
            }
        });

    }  // end setClickListeners()


}  // end SettingsFragment class declaration




