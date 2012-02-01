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
        if( localColor != JFApplication.ColorManager.getColorScheme() )
        {
            // load the title bar elements and pass them to the color manager
            RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.create_tag_heading);
            Button tempButton = (Button)findViewById(R.id.create_tag_cancelbutton);
            
            JFApplication.ColorManager.setupScheme(titleBar,tempButton);
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


}  // end TagActivity class declaration




