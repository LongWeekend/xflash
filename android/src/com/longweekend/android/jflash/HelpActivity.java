package com.longweekend.android.jflash;

//  HelpActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 LONG WEEKEND INC.. All rights reserved.

import android.app.ListActivity;
import android.content.res.Resources;
import android.os.Bundle;
import android.widget.ArrayAdapter;

public class HelpActivity extends ListActivity
{
    private static final String MYTAG = "JFlash HelpActivity";
    
    // asdf

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.help);

        Resources res = getResources();
        String[] topics = res.getStringArray(R.array.help_topics);
        setListAdapter(new ArrayAdapter<String>(this,R.layout.help_row,
                                                R.id.help_label,topics));

    }



}  // end HelpActivity class declaration


