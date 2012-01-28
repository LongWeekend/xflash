package com.longweekend.android.jflash;

//  HelpPageActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/28/2012.
//  Copyright 2012 LONG WEEKEND INC.. All rights reserved.

import android.app.Activity;
import android.os.Bundle;
import android.view.View;

public class HelpPageActivity extends Activity 
{
    private static final String MYTAG = "JFlash HelpPageActivity";
   
 
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.help_page);

    
    }  // end onCreate()

   
    // reset the content view to the main help screen
    public void goBackToHelp(View v)
    {
        finish();
    }
    
    

}  // end HelpPageActivity class declaration


