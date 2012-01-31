package com.longweekend.android.jflash;

//  TagActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;

public class TagActivity extends Activity
{
    // private static final String MYTAG = "JFlash TagActivity";
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.tag);
    }


    // onClick for our PLUS button
    public void addTag(View v)
    {
        startActivity(new Intent(this,CreateTagActivity.class));
    }

}  // end TagActivity class declaration


