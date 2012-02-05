package com.longweekendmobile.android.xflash;

//  PracticeFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
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

public class PracticeFragment extends Fragment
{
    private static final String MYTAG = "XFlash PracticeFragment";
    
    // properties for handling color theme transitions
    private static RelativeLayout practiceLayout;

    
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
        // inflate the layout for our practice activity
        practiceLayout = (RelativeLayout)inflater.inflate(R.layout.practice, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout practiceBack = (RelativeLayout)practiceLayout.findViewById(R.id.practice_mainlayout);

        XflashColor.setupPracticeBack(practiceBack);
        
        return practiceLayout;
    }
  

    // method called when user taps to reveal the answer
    public static void reveal()
    {
        // hide the answer button
        ImageButton tempButton= (ImageButton)practiceLayout.findViewById(R.id.practice_answerbutton);
        tempButton.setVisibility(View.GONE);
 
        // show the options block
        RelativeLayout answerFrame = (RelativeLayout)practiceLayout.findViewById(R.id.practice_options_block);
        answerFrame.setVisibility(View.VISIBLE);
        
        // show the right arrow 
        tempButton = (ImageButton)practiceLayout.findViewById(R.id.practice_rightbutton);
        tempButton.setVisibility(View.VISIBLE);
    }

    
    // method called when any button in the options block is clicked
    public static void practiceClick(View v)
    {
        Log.d(MYTAG,"click in the options block");
    }


    // method called when user click to queue the extra screen
    public static void goRight()
    {
        Log.d(MYTAG,"goRight clicked");
    }



}  // end PracticeFragment class declaration





