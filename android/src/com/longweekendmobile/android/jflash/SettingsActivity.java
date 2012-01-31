package com.longweekendmobile.android.jflash;

//  SettingsActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.RelativeLayout;
import android.view.View;

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
        setSettingsColor();
 
    }  // end onCreate()


    public void advanceColorScheme(View v)
    {
        int tempScheme = JFApplication.PrefsManager.getColorScheme();

        if(tempScheme == 2)
        {
            tempScheme = 0;
        }
        else
        {
            ++tempScheme;
        }

        JFApplication.PrefsManager.setColorScheme(tempScheme);
        setSettingsColor();
    }


    private void setSettingsColor()
    {
        // set the title bar to the current color theme
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.settings_heading);
        Button tempButton = (Button)findViewById(R.id.settings_ratebutton);
        
        switch( JFApplication.PrefsManager.getColorScheme() )
        {
            case 0: titleBar.setBackgroundResource(R.drawable.gradient_red);
                    tempButton.setBackgroundResource(R.drawable.button_red);
                    break;
            case 1: titleBar.setBackgroundResource(R.drawable.gradient_blue);
                    tempButton.setBackgroundResource(R.drawable.button_blue);
                    break;
            case 2: titleBar.setBackgroundResource(R.drawable.gradient_tame);       
                    tempButton.setBackgroundResource(R.drawable.button_tame);
                    break;
            default:    Log.d(MYTAG,"Error - PrefsManager.colorScheme out of bounds");
                        break;
        }

    }  // end setSettingsColors()

}  // end SettingsActivity class declaration


