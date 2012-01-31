package com.longweekendmobile.android.jflash;

//  SearchActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.RelativeLayout;

public class SearchActivity extends Activity
{
    private static final String MYTAG = "JFlash SearchActivity";
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.search);
   
        // set the title bar to the current color scheme
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.search_heading);
        Button tempButton = (Button)findViewById(R.id.search_cancelbutton);

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

  

    }  // end onCreate()



}  // end SearchActivity class declaration


