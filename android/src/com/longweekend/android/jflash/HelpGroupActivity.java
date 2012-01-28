package com.longweekend.android.jflash;

//  HelpGroupActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 LONG WEEKEND INC.. All rights reserved.

import android.content.Intent;
import android.os.Bundle;

public class HelpGroupActivity extends XflashGroupActivity
{
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.practice);

        startChildActivity("HelpActivity", new Intent(this,HelpActivity.class));
    }

}  // end Help1GroupActivity class declaration
