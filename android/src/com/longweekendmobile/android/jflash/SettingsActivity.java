package com.longweekendmobile.android.jflash;

//  SettingsActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//
//  public void advanceColorScheme(View  )

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class SettingsActivity extends Activity
{
    private static final String MYTAG = "JFlash SettingsActivity";
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.settings);
        
        // set the title bar to the current color scheme
        // this Activity does not need the onResume check present in
        // all other activities, because this Activity will never
        // start with an unexpected color change
        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.settings_heading);
        Button tempButton = (Button)findViewById(R.id.settings_ratebutton);
 
        JFApplication.ColorManager.setupScheme(titleBar,tempButton);
 
        // and set the "Theme" label in our settings view
        TextView tempView = (TextView)findViewById(R.id.settings_themelabel);
        tempView.setText( JFApplication.ColorManager.getSchemeName() );

    }  // end onCreate()


    // called when user makes a change to the color scheme in Settings
    public void advanceColorScheme(View v)
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
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.settings_heading);
        Button tempButton = (Button)findViewById(R.id.settings_ratebutton);
 
        JFApplication.ColorManager.setupScheme(titleBar,tempButton);
             
        // and update the "Theme" label in our settings view
        TextView tempView = (TextView)findViewById(R.id.settings_themelabel);
        tempView.setText( JFApplication.ColorManager.getSchemeName() );

    }  // end advanceColorScheme()


}  // end SettingsActivity class declaration




