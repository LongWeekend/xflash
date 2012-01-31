package com.longweekend.android.jflash;

//  Jflash.java
//  jFlash
//
//  Created by Todd Presson on 1/7/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

import android.app.TabActivity;
import android.content.Intent;
import android.content.res.Resources;
import android.os.Bundle;
import android.widget.TabHost;

public class Jflash extends TabActivity
{
    // private static final String MYTAG = "JFlash main";
    
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        // resource object to get drawables
        Resources res = getResources();     
        // TagHost control objects
        TabHost tabHost = getTabHost();
        TabHost.TabSpec spec;
        
        // reusable intent for each tab
        Intent intent;

        // add the practice tab
        intent = new Intent().setClass(this,PracticeActivity.class);
        spec = tabHost.newTabSpec("practice").setIndicator("Practice",
                        res.getDrawable(R.drawable.target_flip)).setContent(intent);
        tabHost.addTab(spec);

        // add the tag tab
        intent = new Intent().setClass(this,TagActivity.class);
        spec = tabHost.newTabSpec("tag").setIndicator("Study Sets",
                        res.getDrawable(R.drawable.tags_flip)).setContent(intent);
        tabHost.addTab(spec);

        // add the search tab
        intent = new Intent().setClass(this,SearchActivity.class);
        spec = tabHost.newTabSpec("search").setIndicator("Search",
                        res.getDrawable(R.drawable.search_flip)).setContent(intent);
        tabHost.addTab(spec);

        // add the settings tab
        intent = new Intent().setClass(this,SettingsActivity.class);
        spec = tabHost.newTabSpec("settings").setIndicator("Settings",
                        res.getDrawable(R.drawable.gear_flip)).setContent(intent);
        tabHost.addTab(spec);

        // add the help tab
        intent = new Intent().setClass(this,HelpGroupActivity.class);
        spec = tabHost.newTabSpec("help").setIndicator("Help",
                        res.getDrawable(R.drawable.lifebuoy_flip)).setContent(intent);
        tabHost.addTab(spec);

        // set practice tab as default
        tabHost.setCurrentTab(0);

    }  // end onCreate()


}  // end Jflash class declaration
