package com.longweekendmobile.android.xflash;

//  UserFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

public class UserFragment extends Fragment
{
    private static final String MYTAG = "XFlash UserFragment";
   
    // properties for handling color theme transitions
    private static LinearLayout userLayout;

    public static boolean isNew = false;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    }


    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        userLayout = (LinearLayout)inflater.inflate(R.layout.user, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)userLayout.findViewById(R.id.user_heading);
        ImageButton tempButton = (ImageButton)userLayout.findViewById(R.id.user_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,tempButton); 

        return userLayout;
    }


    public static void activateUser()
    {
        Log.d(MYTAG,"activate user click");
    }

    public static void editUser(View v,Xflash inContext)
    {
        if( v.getId() == R.id.user_addbutton )
        {
            isNew = true;
        }
        else
        {
            isNew = false;
        } 

        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_EDIT_USER);
        inContext.onScreenTransition("edit_user",Xflash.DIRECTION_OPEN); 
    }

}  // end UserFragment class declaration





