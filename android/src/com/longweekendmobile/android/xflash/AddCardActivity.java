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
//
//  public void AddCardToTagFragment_toggleWord(View  )
//  public void AddCardToTagFragment_addTag(View  )

import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.view.View;

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

    }

    @Override
    public void onPause()
    {
        super.onPause();
        
        overridePendingTransition(R.anim.hold,R.anim.slideout_bottom);
    }

    public void AddCardToTagFragment_toggleWord(View v)
    {
        AddCardToTagFragment.toggleWord(v);
    }

    public void AddCardToTagFragment_addTag(View v)
    {
        AddCardToTagFragment.addTag(this);
    }

}  // end AddCardActivity class declaration
