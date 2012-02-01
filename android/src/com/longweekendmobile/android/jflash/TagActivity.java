package com.longweekendmobile.android.jflash;

//  TagActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//  public void onResume()      @over
//
//  public void addTag(View  )

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageButton;
import android.widget.RelativeLayout;

public class TagActivity extends Activity
{
    private static final String MYTAG = "JFlash TagActivity";
    
    private int localColor;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.tag);

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
            // set the background to the current color scheme
            if( localColor != JFApplication.ColorManager.getColorScheme() )
            {
                // load the title bar elements and pass them to the color manager
                RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.tag_heading);
                ImageButton tempButton = (ImageButton)findViewById(R.id.tag_addbutton);

                JFApplication.ColorManager.setupScheme(titleBar,tempButton);
            }
        }

    }  // end onResume()


    // onClick for our PLUS button
    public void addTag(View v)
    {
        startActivity(new Intent(this,CreateTagActivity.class));
    }

    
}  // end TagActivity class declaration


