package com.longweekendmobile.android.jflash;

//  FragManager.java
//  jFlash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//  public void onResume()                                              @over

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

public class FragManager 
{
    // private static final String MYTAG = "JFlash FragManager";
    
    // properties for handling color theme transitions
    private static int currentHelpScreen = 0;

    public static int getCurrentHelpScreen()
    {
        return currentHelpScreen;
    }

    public static void setCurrentHelpScreen(int inScreen)
    {
        currentHelpScreen = inScreen;
    }


}  // end FragManager class declaration


