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

import java.util.ArrayList;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.ExampleSentence;
import com.longweekendmobile.android.xflash.model.ExampleSentencePeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.LWEDatabase;

public class ExampleSentenceFragment extends Fragment
{
    private static final String MYTAG = "XFlash ExampleSentenceFragment";
    
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
        
        // set the reading
        TextView tempView = (TextView)ESlayout.findViewById(R.id.es_readingtext);
        tempView.setText( currentCard.reading() );

        // set the headword
        tempView = (TextView)ESlayout.findViewById(R.id.es_headword);
        tempView.setText( currentCard.getHeadword() );
        
        // get the view body to add our example sentence rows
        LinearLayout exampleBody = (LinearLayout)ESlayout.findViewById(R.id.es_body);
        
        Log.d(MYTAG,"attaching example sentence database");
        XFApplication.getDao().attachDatabase(LWEDatabase.DB_EX);
        ArrayList<ExampleSentence> esList = ExampleSentencePeer.getExampleSentencesByCardId( currentCard.getCardId() );
        XFApplication.getDao().detachDatabase(LWEDatabase.DB_EX);

        // load each of the present sentences 
        int numSentences = esList.size();
        for(int i = 0; i < numSentences; i++)
        {
            RelativeLayout esRow = (RelativeLayout)inflater.inflate(R.layout.es_row, container, false);

            ExampleSentence tempSentence = esList.get(i);

            // set the number
            tempView = (TextView)esRow.findViewById(R.id.es_row_number);
            tempView.setText( Integer.toString( i + 1 ) + "." );

            // set the Japanese sentence
            tempView = (TextView)esRow.findViewById(R.id.es_sentence_jp);
            tempView.setText( tempSentence.getJa() ); 

            // set the English sentence 
            tempView = (TextView)esRow.findViewById(R.id.es_sentence_en);
            tempView.setText( tempSentence.getEn() ); 

            // tag the 'read' button with the sentence id
            Button tempReadButton = (Button)esRow.findViewById(R.id.es_read_button);
            tempReadButton.setTag( tempSentence.getSentenceId() );

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

    
    public static void read(View v)
    {
        Log.d(MYTAG,"read() called with sentence id:  " + (Integer)v.getTag() );
    }


}  // end ExampleSentenceFragment class declaration





