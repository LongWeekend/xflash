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
//
//  private void setTagColor()

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
        if( localColor != JFApplication.PrefsManager.getColorScheme() )
        {
            setTagColor();
        }
    }

    // onClick for our PLUS button
    public void addTag(View v)
    {
        startActivity(new Intent(this,CreateTagActivity.class));
    }

    
    // sets the local colors
    private void setTagColor()
    {
        // set the title bar to the current color scheme
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.tag_heading);
        ImageButton tempButton = (ImageButton)findViewById(R.id.tag_addbutton);

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

    }  // end setTagColor()


}  // end TagActivity class declaration


