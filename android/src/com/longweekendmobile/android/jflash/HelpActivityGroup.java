package com.longweekendmobile.android.jflash;

//  HelpActivityGroup.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

import android.content.Intent;
import android.os.Bundle;

public class HelpActivityGroup extends XflashActivityGroup
{
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.practice);

        startChildActivity("HelpActivity", new Intent(this,HelpActivity.class));
    }


}  // end HelpActivityGroup class declaration
