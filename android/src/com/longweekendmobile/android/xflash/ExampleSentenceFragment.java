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
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.JapaneseCard;

public class ExampleSentenceFragment extends Fragment
{
    // private static final String MYTAG = "XFlash ExampleSentenceFragment";
    
    // properties for handling color theme transitions
    private static RelativeLayout ESlayout;
    private static JapaneseCard currentCard;

    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate the layout for our example sentence activity
        ESlayout = (RelativeLayout)inflater.inflate(R.layout.example_sentence, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout exampleBack = (RelativeLayout)ESlayout.findViewById(R.id.example_mainlayout);
        XflashSettings.setupPracticeBack(exampleBack);
        
        TextView tempView = (TextView)ESlayout.findViewById(R.id.es_readingtext);
        tempView.setText( currentCard.reading() );

        tempView = (TextView)ESlayout.findViewById(R.id.es_headword);
        tempView.setText( currentCard.getHeadword() );
        
        LinearLayout exampleBody = (LinearLayout)ESlayout.findViewById(R.id.es_body);
        
        for(int i = 0; i < 5; i++)
        {
            RelativeLayout esRow = (RelativeLayout)inflater.inflate(R.layout.es_row, container, false);
            exampleBody.addView(esRow);
        }
        
        return ESlayout;
    }
  

    // method called when any button in the options block is clicked
    public static void exampleClick(View v,Xflash inContext)
    {
        // remove the transition to the example sentence fragment
        XflashScreen.popBackPractice();
        XflashScreen.setPracticeOverride();
        
        PracticeFragment.setPracticeBlank();
        inContext.onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);
    }


    public static void setIncomingCard(JapaneseCard inCard)
    {
        currentCard = inCard;
    }

}  // end ExampleSentenceFragment class declaration





