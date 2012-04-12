package com.longweekendmobile.android.xflash;

//  UpdateFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  private void check()

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

public class UpdateFragment extends Fragment
{
    private static final String MYTAG = "XFlash UpdateFragment";
   

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Update fragment
        LinearLayout updateLayout = (LinearLayout)inflater.inflate(R.layout.update, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)updateLayout.findViewById(R.id.update_heading);
        
        XflashSettings.setupColorScheme(titleBar); 

        // set a click listener for the 'check for updates' button
        Button checkUpdateButton = (Button)updateLayout.findViewById(R.id.update_checkbutton);
        checkUpdateButton.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                check();
            }
        });

        return updateLayout;

    }  // end onCreateView()


    private void check()
    {
        Log.d(MYTAG,"check clicked");
    }


}  // end UpdateFragment class declaration





