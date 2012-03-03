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
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.ExampleSentence;
import com.longweekendmobile.android.xflash.model.ExampleSentencePeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.LWEDatabase;

public class ExampleSentenceFragment extends Fragment
{
    private static final String MYTAG = "XFlash ExampleSentenceFragment";
    
    // properties for handling color theme transitions
    private static RelativeLayout ESlayout;
    private static LinearLayout exampleBody;
    private static JapaneseCard currentCard;

    private static LayoutInflater myInflater = null;

    
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        myInflater = inflater;
        
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
        exampleBody = (LinearLayout)ESlayout.findViewById(R.id.es_body);
        
        // attach the EX database long enough to pull our sentences
        XFApplication.getDao().attachDatabase(LWEDatabase.DB_EX);
        ArrayList<ExampleSentence> esList = ExampleSentencePeer.getExampleSentencesByCardId( currentCard.getCardId() );
        XFApplication.getDao().detachDatabase(LWEDatabase.DB_EX);

        // load each of the present sentences 
        int numSentences = esList.size();
        for(int i = 0; i < numSentences; i++)
        {
            ExampleSentence tempSentence = esList.get(i);
            int tempSentenceId = tempSentence.getSentenceId();

            // inflate a row for each sentence and tag with the sentence id
            RelativeLayout esRow = (RelativeLayout)inflater.inflate(R.layout.es_row, container, false);
            esRow.setTag(tempSentenceId);

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
            tempReadButton.setTag(tempSentenceId);

            exampleBody.addView(esRow);
        }
        
        return ESlayout;

    }  // end onCreateView()


    // method called when any button in the options block is clicked
    public static void exampleClick(View v,Xflash inContext)
    {
        // remove the transition to the example sentence fragment
        XflashScreen.popBackPractice();
        XflashScreen.setPracticeOverride();
        
        PracticeFragment.setPracticeBlank();
        inContext.onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);
    }


    public static void loadCard(JapaneseCard inCard)
    {
        currentCard = inCard;
    }

    public static void addCard(View v)
    {
        Log.d(MYTAG,"addCard() clicked with id:  " + (Integer)v.getTag() );
    }


    public static void toggleRead(View v)
    {
        Button tempReadButton = (Button)v;
        int tempSentenceId = (Integer)v.getTag();

        // pull the relevant row
        RelativeLayout tempRow = (RelativeLayout)exampleBody.findViewWithTag(tempSentenceId);
        
        // pull the LinearLayout word block to populate
        LinearLayout cardBlock = (LinearLayout)tempRow.findViewById(R.id.es_card_block);
        
        if( cardBlock.getVisibility() == View.VISIBLE )
        {
            // if the word block is shown, hide it
            tempReadButton.setText("Read");
            cardBlock.setVisibility(View.GONE);
        }
        else
        {
            FrameLayout tempDivider = (FrameLayout)myInflater.inflate(R.layout.divider,null);
            cardBlock.addView(tempDivider);
            
            // load our cards
            XFApplication.getDao().attachDatabase(LWEDatabase.DB_EX);
            ArrayList<Card> tempCardArray = CardPeer.retrieveCardSetForExampleSentenceId(tempSentenceId);
            XFApplication.getDao().detachDatabase(LWEDatabase.DB_EX);
            
            int numCards = tempCardArray.size();
            for(int i = 0; i < numCards; i++)
            {
                JapaneseCard tempCard = (JapaneseCard)tempCardArray.get(i);

                // inflate a new word/card row
                RelativeLayout tempWordRow = (RelativeLayout)myInflater.inflate(R.layout.es_card_row,null);

                // headword
                TextView tempView = (TextView)tempWordRow.findViewById(R.id.es_cardrow_headword);
                tempView.setText( tempCard.headwordIgnoringMode(true) );

                // reading
                tempView = (TextView)tempWordRow.findViewById(R.id.es_cardrow_reading);
                tempView.setText( tempCard.reading() );

                // tag the button for addCard() with the card id
                Button tempAddButton = (Button)tempWordRow.findViewById(R.id.es_cardrow_button);
                tempAddButton.setTag( tempCard.getCardId() );

                // add the word/card row
                cardBlock.addView(tempWordRow); 
                
                // add a divider at the end
                tempDivider = (FrameLayout)myInflater.inflate(R.layout.divider,null);
                cardBlock.addView(tempDivider);
            }

            // add the bottom margin layout
            tempDivider = (FrameLayout)myInflater.inflate(R.layout.es_word_margin,null);
            cardBlock.addView(tempDivider);
            
            // change the button and show the cards
            tempReadButton.setText("Close");
            cardBlock.setVisibility(View.VISIBLE);

        }  // end else clause for if( cardBlock.isVisible() )

    }  // end toggleRead()


}  // end ExampleSentenceFragment class declaration





