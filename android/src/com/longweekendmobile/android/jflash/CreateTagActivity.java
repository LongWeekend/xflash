package com.longweekendmobile.android.jflash;

//  CreateTagActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//  public void onResume()      @over
//  public void onPause()       @over
//
//  public void cancel(View v)
//
//  private void setCreateTagColor()


import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.RelativeLayout;

public class CreateTagActivity extends Activity
{
    private static final String MYTAG = "JFlash TagActivity";
   
    private int localColor;
 
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.create_tag);
    
        // if we're just starting up, force load of color
        localColor = -1;
    }

    @Override
    public void onResume()
    {
        super.onResume();
        overridePendingTransition(R.anim.slidein_bottom,R.anim.hold);

        // set the background to the current color scheme
        if( localColor != JFApplication.PrefsManager.getColorScheme() )
        {
            setCreateTagColor();
        }
    }

    @Override
    public void onPause()
    {
        super.onPause();
        
        overridePendingTransition(R.anim.hold,R.anim.slideout_bottom);
    }

    public void cancel(View v)
    {
        finish();
    }


    // method for setting all local colors
    private void setCreateTagColor()
    {
        // set the title bar to the current color scheme
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.create_tag_heading);
        Button tempButton = (Button)findViewById(R.id.create_tag_cancelbutton);

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

    }  // end setCreateTagColor()



}  // end TagActivity class declaration




