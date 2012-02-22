package com.longweekendmobile.android.xflash;

//  UpdateFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void check()

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

public class UpdateFragment extends Fragment
{
    private static final String MYTAG = "XFlash UpdateFragment";
   
    public static boolean isNew = false;


    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        LinearLayout updateLayout = (LinearLayout)inflater.inflate(R.layout.update, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)updateLayout.findViewById(R.id.update_heading);
        
        XflashSettings.setupColorScheme(titleBar); 

        return updateLayout;

    }  // end onCreateView()


    public static void check()
    {
        Log.d(MYTAG,"check clicked");
    }


}  // end UpdateFragment class declaration





