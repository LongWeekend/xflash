package com.longweekend.android.jflash;

//  HelpActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 LONG WEEKEND INC.. All rights reserved.

import android.app.Activity;
import android.os.Bundle;

public class HelpActivity extends Activity
{
    private static final String MYTAG = "JFlash HelpActivity";
    

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.help);
    }



}  // end HelpActivity class declaration


