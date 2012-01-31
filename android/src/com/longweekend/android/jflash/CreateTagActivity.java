package com.longweekend.android.jflash;

//  CreateTagActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

import android.app.Activity;
import android.os.Bundle;
import android.view.View;

public class CreateTagActivity extends Activity
{
    // private static final String MYTAG = "JFlash TagActivity";
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.create_tag);
    }

    @Override
    public void onResume()
    {
        super.onResume();

        overridePendingTransition(R.anim.slidein_bottom,R.anim.hold);
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


