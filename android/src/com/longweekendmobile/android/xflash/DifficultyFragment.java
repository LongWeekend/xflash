package com.longweekendmobile.android.xflash;

//  DifficultyFragment.java
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
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

public class DifficultyFragment extends Fragment 
{
    // private static final String MYTAG = "XFlash DifficultyFragment";
   
    // properties for handling color theme transitions
    private static LinearLayout difficultyLayout;

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
        difficultyLayout = (LinearLayout)inflater.inflate(R.layout.difficulty, container, false);

        // TODO - this is not loading when the tab is switched to
        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)difficultyLayout.findViewById(R.id.difficulty_heading);
        XflashSettings.setupColorScheme(titleBar); 

        // set the text values of the four radio buttons
        XflashRadio radioArray[] = { null, null, null, null };

        radioArray[0] = (XflashRadio)difficultyLayout.findViewById(R.id.difficulty_easy);
        radioArray[0].setButtonText("Easy");

        radioArray[1] = (XflashRadio)difficultyLayout.findViewById(R.id.difficulty_medium);
        radioArray[1].setButtonText("Medium");

        radioArray[2] = (XflashRadio)difficultyLayout.findViewById(R.id.difficulty_hard);
        radioArray[2].setButtonText("Hard");

        radioArray[3] = (XflashRadio)difficultyLayout.findViewById(R.id.difficulty_custom);
        radioArray[3].setButtonText("Custom");

        
        XflashSettings.setRadioColors(radioArray);

        return difficultyLayout;
    }


    // reset the content view to the main settings screen
    public static void goBackToSettings(Xflash inContext)
    {
        // reload the Difficulty fragment to the fragment tab manager
        inContext.onScreenTransition("settings");
    }
    

}  // end HelpPageFragment class declaration





