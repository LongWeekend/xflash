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
//
//  private void setSettingsColor()

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
        setSettingsColor();
 
    }  // end onCreate()


    // called when user makes a change to the color scheme in Settings
    public void advanceColorScheme(View v)
    {
        int tempScheme = JFApplication.PrefsManager.getColorScheme();

        // set our new color
        if(tempScheme == 3)
        {
            tempScheme = 0;
        }
        else
        {
            ++tempScheme;
        }

        // set our static color field
        JFApplication.PrefsManager.setColorScheme(tempScheme);
        setSettingsColor();

    }  // end advanceColorScheme()


    // sets the local colors
    private void setSettingsColor()
    {
        // set the title bar to the current color theme
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.settings_heading);
        Button tempButton = (Button)findViewById(R.id.settings_ratebutton);
        TextView tempView = (TextView)findViewById(R.id.settings_themelabel);
 
        switch( JFApplication.PrefsManager.getColorScheme() )
        {
            case 0: titleBar.setBackgroundResource(R.drawable.gradient_red);
                    tempButton.setBackgroundResource(R.drawable.button_red);
                    tempView.setText("Fire");
                    break;
            case 1: titleBar.setBackgroundResource(R.drawable.gradient_blue);
                    tempButton.setBackgroundResource(R.drawable.button_blue);
                    tempView.setText("Water");
                    break;
            case 2: titleBar.setBackgroundResource(R.drawable.gradient_tame);       
                    tempButton.setBackgroundResource(R.drawable.button_tame);
                    tempView.setText("Tame");
                    break;
            case 3: titleBar.setBackgroundResource(R.drawable.gradient_green);       
                    tempButton.setBackgroundResource(R.drawable.button_green);
                    tempView.setText("Forest");
                    break;
            default:    Log.d(MYTAG,"Error - PrefsManager.colorScheme out of bounds");
                        break;
        }

    }  // end setSettingsColors()


}  // end SettingsActivity class declaration




