package com.longweekendmobile.android.xflash;

//  AllCardsFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import android.graphics.PorterDuff;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RadioGroup;
import android.widget.RadioGroup.OnCheckedChangeListener;
import android.widget.RelativeLayout;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;
import android.util.Log;

import com.longweekendmobile.android.xflash.model.Tag;

public class AllCardsFragment extends Fragment
{
    private static final String MYTAG = "XFlash AllCardsFragment";
   
    // properties for handling color theme transitions
    private static LinearLayout allCardsLayout;

    private static int incomingTagId;
    private static boolean isActive = false;
    private Tag currentTag;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onResume()
    {
        super.onResume();

        isActive = true;
    }

    @Override
    public void onPause()
    {
        super.onPause();

        isActive = false;
    }

    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the AllCardsPage fragment
        allCardsLayout = (LinearLayout)inflater.inflate(R.layout.all_cards, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)allCardsLayout.findViewById(R.id.allcards_heading);
        ImageButton tempButton = (ImageButton)allCardsLayout.findViewById(R.id.allcards_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,tempButton); 

        return allCardsLayout;
    }


    public static void setIncomingTagId(int inId)
    {
        incomingTagId = inId;
    }

    public static boolean getActive()
    {
        return isActive;
    }

}  // end AllCardsFragment class declaration





