package com.longweekendmobile.android.jflash;

//  SearchFragment.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

public class SearchFragment extends Fragment
{
    // private static final String MYTAG = "JFlash SearchFragment";

    // properties for handling color theme transitions
    private LinearLayout searchLayout;
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    } 


    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Search activity
        searchLayout = (LinearLayout)inflater.inflate(R.layout.search, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)searchLayout.findViewById(R.id.search_heading);
        Button tempButton = (Button)searchLayout.findViewById(R.id.search_cancelbutton);
  
        JFApplication.ColorManager.setupScheme(titleBar,tempButton);
        
        return searchLayout;
    }


}  // end SearchFragment class declaration


