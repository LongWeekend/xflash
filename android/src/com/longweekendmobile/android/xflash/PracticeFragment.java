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
import android.widget.RelativeLayout;

public class PracticeFragment extends Fragment
{
    private static final String MYTAG = "XFlash PracticeFragment";
    
    // properties for handling color theme transitions
    private static RelativeLayout practiceLayout;

    public static final int PRACTICE_BAR_BLANK = 0;  // corresponds to XflashSettings.LWE_STUDYMODE_PRACTICE 
    public static final int PRACTICE_BAR_BROWSE = 1; // corresponds to XflashSettings.LWE_STUDYMODE_BROWSE
    public static final int PRACTICE_BAR_SHOW = 2;
 
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
        XflashSettings.setupPracticeBack(practiceBack);
        
        // set the appropriate answer bar based on our settings
        setAnswerBar( XflashSettings.getStudyMode() ); 

        return practiceLayout;
    }
  

    // when the answer bar is clicked in practice mode
    public static void reveal()
    {
        setAnswerBar(PRACTICE_BAR_SHOW);
    }


    // method called when user taps to reveal the answer
    public static void setAnswerBar(int inMode)
    {
        // pull all necessary resources
        ImageButton rightArrow = (ImageButton)practiceLayout.findViewById(R.id.practice_rightbutton);
        ImageButton blankButton= (ImageButton)practiceLayout.findViewById(R.id.practice_answerbutton);
        RelativeLayout showFrame = (RelativeLayout)practiceLayout.findViewById(R.id.practice_options_block);
        RelativeLayout browseFrame = (RelativeLayout)practiceLayout.findViewById(R.id.browse_options_block);

        // set what should be visible based on study mode
        switch(inMode)
        {
            case PRACTICE_BAR_BLANK:    browseFrame.setVisibility(View.GONE);
                                        showFrame.setVisibility(View.GONE);
                                        rightArrow.setVisibility(View.GONE);
                                        blankButton.setVisibility(View.VISIBLE);
                                        break;
            case PRACTICE_BAR_BROWSE:   blankButton.setVisibility(View.GONE);
                                        rightArrow.setVisibility(View.GONE);
                                        showFrame.setVisibility(View.GONE);
                                        browseFrame.setVisibility(View.VISIBLE);
                                        break;
            case PRACTICE_BAR_SHOW:     blankButton.setVisibility(View.GONE);
                                        browseFrame.setVisibility(View.GONE);
                                        rightArrow.setVisibility(View.VISIBLE);
                                        showFrame.setVisibility(View.VISIBLE);
                                        break;
            default:    Log.d(MYTAG,"Error in setAnswerBar()  :  invalid study mode: " + inMode);
        } 

    }  // end setAnswerBar()

    
    // method called when any button in the options block is clicked
    public static void practiceClick(View v,Xflash inContext)
    {
        XflashScreen.setPracticeOverride();
        inContext.onScreenTransition("practice",Xflash.DIRECTION_OPEN);
    }


    // method called when any button in the options block is clicked
    public static void browseClick(View v,Xflash inContext)
    {
        switch( v.getId() )
        {
            case R.id.browseblock_last:     inContext.onScreenTransition("practice",Xflash.DIRECTION_CLOSE);
                                            break;
            case R.id.browseblock_actions:  break;
            case R.id.browseblock_next:     inContext.onScreenTransition("practice",Xflash.DIRECTION_OPEN);
                                            break;  
        } 
    }


    // method called when user click to queue the extra screen
    public static void goRight(Xflash inContext)
    {
        // load the ExampleSentenceFragment to the fragment tab manager
        inContext.onScreenTransition("example_sentence",Xflash.DIRECTION_OPEN);
    }



}  // end PracticeFragment class declaration





