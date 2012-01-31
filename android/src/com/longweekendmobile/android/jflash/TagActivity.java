package com.longweekendmobile.android.jflash;

//  TagActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

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
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.tag);

       // set the title bar to the current color scheme
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.tag_heading);
        ImageButton tempButton = (ImageButton)findViewById(R.id.tag_addbutton);

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




    }


    // onClick for our PLUS button
    public void addTag(View v)
    {
        startActivity(new Intent(this,CreateTagActivity.class));
    }

}  // end TagActivity class declaration


