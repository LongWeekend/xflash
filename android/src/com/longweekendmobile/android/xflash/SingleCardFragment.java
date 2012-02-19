package com.longweekendmobile.android.xflash;

//  SingleCardFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/19/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.util.Log;

public class SingleCardFragment extends Fragment
{
    private static final String MYTAG = "XFlash SingleCardFragment";
   
    private static LinearLayout singleCardLayout;
   
    private static int incomingCardId; 

    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        singleCardLayout = (LinearLayout)inflater.inflate(R.layout.single_card, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)singleCardLayout.findViewById(R.id.singlecard_heading);
        ImageButton tempButton = (ImageButton)singleCardLayout.findViewById(R.id.singlecard_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,tempButton); 

        Log.d(MYTAG,"called with incoming card id:  " + incomingCardId);

        return singleCardLayout;
    }


    public static void setIncomingCardId(int inId)
    {
        incomingCardId = inId;
    }
    
    public static void addTag(Xflash inContext)
    {
        Log.d(MYTAG,"SingleCardFragment.addtag() clicked");            
    }

}  // end SingleCardFragment class declaration





