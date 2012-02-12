package com.longweekendmobile.android.xflash;

//  ExampleSentenceFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/8/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void exampleClick(View  ,Xflash  )

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

public class ExampleSentenceFragment extends Fragment
{
    // private static final String MYTAG = "XFlash ExampleSentenceFragment";
    
    // properties for handling color theme transitions
    private static RelativeLayout exampleSentenceLayout;


    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate the layout for our example sentence activity
        exampleSentenceLayout = (RelativeLayout)inflater.inflate(R.layout.example_sentence, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout exampleBack = (RelativeLayout)exampleSentenceLayout.findViewById(R.id.example_mainlayout);
        XflashSettings.setupPracticeBack(exampleBack);
        
        return exampleSentenceLayout;
    }
  

    // method called when any button in the options block is clicked
    public static void exampleClick(View v,Xflash inContext)
    {
        // remove the transition to the example sentence fragment
        XflashScreen.popBackPractice();
 
        XflashScreen.setPracticeOverride();
        PracticeFragment.clearAnswerBar();
        inContext.onScreenTransition("practice",Xflash.DIRECTION_OPEN);
    }


}  // end PracticeFragment class declaration





