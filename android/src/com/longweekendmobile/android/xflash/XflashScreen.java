package com.longweekendmobile.android.xflash;

//  XflashScreen.java
//  Xflash
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
import android.util.Log;

public class XflashScreen 
{
    private static final String MYTAG = "XFlash XflashScreen";
    
    // properties for handling color theme transitions
    private static int currentHelpScreen;

    // set all fragment page values to zero when starting app
    public static void fireUpScreenManager()
    {
        currentHelpScreen = 0;
    } 

    public static int getCurrentHelpScreen()
    {
        return currentHelpScreen;
    }

    public static void setCurrentHelpScreen(int inScreen)
    {
        currentHelpScreen = inScreen;
    }


}  // end XflashScreen class declaration


