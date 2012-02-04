package com.longweekendmobile.android.jflash;

//  SettingsFragment.java
//  jFlash
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
    // private static final String MYTAG = "JFlash SettingsFragment";
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
 
        JFApplication.ColorManager.setupScheme(titleBar,tempButton);
 
        // and set the "Theme" label in our settings view
        TextView tempView = (TextView)settingsLayout.findViewById(R.id.settings_themelabel);
        tempView.setText( JFApplication.ColorManager.getSchemeName() );
        
        return settingsLayout;

    }  // end onCreateView()

    
    // called when user makes a change to the color scheme in Settings
    public static void advanceColorScheme()
    {
        int tempScheme = JFApplication.ColorManager.getColorScheme();

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
        JFApplication.ColorManager.setColorScheme(tempScheme);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)settingsLayout.findViewById(R.id.settings_heading);
        Button tempButton = (Button)settingsLayout.findViewById(R.id.settings_ratebutton);

        JFApplication.ColorManager.setupScheme(titleBar,tempButton);

        // and update the "Theme" label in our settings view
        TextView tempView = (TextView)settingsLayout.findViewById(R.id.settings_themelabel);
        tempView.setText( JFApplication.ColorManager.getSchemeName() );

    }  // end advanceColorScheme()


}  // end SettingsFragment class declaration




