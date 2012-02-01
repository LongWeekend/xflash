package com.longweekendmobile.android.jflash;

//  SearchActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//  public void onResume()      @over

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
        if( localColor != JFApplication.ColorManager.getColorScheme() )
        {
            // load the title bar elements and pass them to the color manager
            RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.search_heading);
            Button tempButton = (Button)findViewById(R.id.search_cancelbutton);
  
            JFApplication.ColorManager.setupScheme(titleBar,tempButton);
        }
    }


}  // end SearchActivity class declaration


