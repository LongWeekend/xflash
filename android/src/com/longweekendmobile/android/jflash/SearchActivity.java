package com.longweekendmobile.android.jflash;

//  SearchActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//  public void onResume()      @over
//
//  private void setSearchColor()

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.RelativeLayout;

public class SearchActivity extends Activity
{
    private static final String MYTAG = "JFlash SearchActivity";

    private int localColor;
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.search);
   
        // if we're just starting up, force load of color
        localColor = -1;
    } 


    @Override
    public void onResume()
    {
        super.onResume();

        // set the background to the current color scheme
        if( localColor != JFApplication.PrefsManager.getColorScheme() )
        {
            setSearchColor();
        }
    }


    // sets the local color
    private void setSearchColor()
    {
        // set the title bar to the current color scheme
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.search_heading);
        Button tempButton = (Button)findViewById(R.id.search_cancelbutton);

        localColor = JFApplication.PrefsManager.getColorScheme();

        switch(localColor)
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
            case 3: titleBar.setBackgroundResource(R.drawable.gradient_green);
                    tempButton.setBackgroundResource(R.drawable.button_green);
                    break;
            default:    Log.d(MYTAG,"Error - PrefsManager.colorScheme out of bounds");
                        break;
        }

    }  // end setSearchColor() 


}  // end SearchActivity class declaration


