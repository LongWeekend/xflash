package com.longweekendmobile.android.xflash;

//  CreateTagActivity.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//  public void onResume()      @over
//  public void onPause()       @over
//
//  public static void setCurrentGroup(Group  )
//
//  private void keyboardDone()

import android.os.Bundle;
import android.support.v4.app.FragmentActivity;

public class CreateTagActivity extends FragmentActivity
{
    // private static final String MYTAG = "XFlash CreateTagActivity";
   
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        
        // feed 'this' to the EditTagFragment so it both knows it is being
        // called as an Activity, and so it can display the no-name alert properly
        EditTagFragment.setActivityContext(this);
        EditTagFragment.setTagToEdit(null);

        setContentView(R.layout.createtag_activity);

    }   // end onCreate()

    
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

    @Override
    public void onStop()
    {
        super.onStop();

        // clear EditTagFragment's activity context on exit, so it does not
        // later think it's running as an Activity when in fact it is a Fragment
        EditTagFragment.setActivityContext(null);
        EditTagFragment.resetToFragment();
    }


}  // end CreateTagActivity class declaration




