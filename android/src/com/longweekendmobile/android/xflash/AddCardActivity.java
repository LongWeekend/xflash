package com.longweekendmobile.android.xflash;

//  AddCardActivity.java
//  Xflash
//
//  Created by Todd Presson on 3/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//  public void onResume()      @over
//  public void onPause()       @over

import android.os.Bundle;
import android.support.v4.app.FragmentActivity;

public class AddCardActivity extends FragmentActivity
{
    // private static final String MYTAG = "XFlash AddCardActivity";

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.addcard_activity);
    }

    @Override
    public void onResume()
    {
        super.onResume();
        overridePendingTransition(R.anim.slidein_bottom,R.anim.hold);

        // notify AddCardToTagFramgnt it is running modally
        AddCardToTagFragment.setModal(true,this);
    }

    @Override
    public void onPause()
    {
        super.onPause();
        overridePendingTransition(R.anim.hold,R.anim.slideout_bottom);
        
        // remove modal flag
        AddCardToTagFragment.setModal(false,null);
    }


}  // end AddCardActivity class declaration
