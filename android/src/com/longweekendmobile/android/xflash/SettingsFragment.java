package com.longweekendmobile.android.xflash;

//  SettingsFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static LinearLayout getSettingsLayout()

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class SettingsFragment extends Fragment
{
    // private static final String MYTAG = "XFlash SettingsFragment";
    private static LinearLayout settingsLayout;
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    }


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
        
        // and set the "Theme" label in our settings view
        tempView = (TextView)settingsLayout.findViewById(R.id.settings_theme_label);
        tempView.setText( XflashSettings.getColorSchemeName() );
        
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
   
 
    // called when user makes a change to the color scheme in Settings
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


}  // end SettingsFragment class declaration




