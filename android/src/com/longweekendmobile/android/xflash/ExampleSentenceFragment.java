package com.longweekendmobile.android.xflash;

//  ExampleSentenceFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/8/2012.
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

public class ExampleSentenceFragment extends Fragment
{
    private static final String MYTAG = "XFlash ExampleSentenceFragment";
    
    // properties for handling color theme transitions
    private static RelativeLayout exampleSentenceLayout;

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
        // inflate the layout for our example sentence activity
        exampleSentenceLayout = (RelativeLayout)inflater.inflate(R.layout.example_sentence, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout exampleBack = (RelativeLayout)exampleSentenceLayout.findViewById(R.id.example_mainlayout);
        XflashSettings.setupPracticeBack(exampleBack);
        
        // set the appropriate answer bar based on our settings
        // setAnswerBar( XflashSettings.getStudyMode() ); 
        setAnswerBar(PracticeFragment.PRACTICE_BAR_SHOW);

        return exampleSentenceLayout;
    }
  

    // when the answer bar is clicked in practice mode
    public static void reveal()
    {
        setAnswerBar(PracticeFragment.PRACTICE_BAR_SHOW);
    }


    // method called when user taps to reveal the answer
    public static void setAnswerBar(int inMode)
    {
        // pull all necessary resources
        ImageButton blankButton= (ImageButton)exampleSentenceLayout.findViewById(R.id.example_sentence_answerbutton);
        RelativeLayout showFrame = (RelativeLayout)exampleSentenceLayout.findViewById(R.id.example_sentence_options_block);
        RelativeLayout browseFrame = (RelativeLayout)exampleSentenceLayout.findViewById(R.id.es_browse_options_block);

        // set what should be visible based on study mode
        switch(inMode)
        {
            case PracticeFragment.PRACTICE_BAR_BLANK:    browseFrame.setVisibility(View.GONE);
                                        showFrame.setVisibility(View.GONE);
                                        blankButton.setVisibility(View.VISIBLE);
                                        break;
            case PracticeFragment.PRACTICE_BAR_BROWSE:   blankButton.setVisibility(View.GONE);
                                        showFrame.setVisibility(View.GONE);
                                        browseFrame.setVisibility(View.VISIBLE);
                                        break;
            case PracticeFragment.PRACTICE_BAR_SHOW:     blankButton.setVisibility(View.GONE);
                                        browseFrame.setVisibility(View.GONE);
                                        showFrame.setVisibility(View.VISIBLE);
                                        break;
            default:    Log.d(MYTAG,"Error in setAnswerBar()  :  invalid study mode: " + inMode);
        } 

    }  // end setAnswerBar()

    
    // method called when any button in the options block is clicked
    public static void exampleClick(View v,Xflash inContext)
    {
        // remove the transition to the example sentence fragment
        XflashScreen.popBackPractice();
 
        XflashScreen.setPracticeOverride();
        inContext.onScreenTransition("practice",Xflash.DIRECTION_OPEN);
    }


    // method called when any button in the options block is clicked
    public static void browseClick()
    {
        Log.d(MYTAG,"click in the browse block");
    }



}  // end PracticeFragment class declaration





