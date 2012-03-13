package com.longweekendmobile.android.xflash;

//  ExampleSentenceFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/8/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void loadCard(JapaneseCard  ,int[]  )
//
//  private void setAnswerBarListeners()
//  private void refreshCountBar();
//  private void exampleClick(View  )
//  private static void addCard(View  )
//  private void toggleRead(View  )
//  private void loadExampleSentenceBlock(Button  ,int  ,LinearLayout  )

import java.util.ArrayList;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.ImageButton;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.ExampleSentence;
import com.longweekendmobile.android.xflash.model.ExampleSentencePeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.LWEDatabase;

public class ExampleSentenceFragment extends Fragment
{
    // private static final String MYTAG = "XFlash ExampleSentenceFragment";
    
    private static int practiceCardCounts[] = { 0,0,0,0,5 };
    private static JapaneseCard currentCard;
    private static ArrayList<ExampleSentence> esList = null;
    
    private RelativeLayout ESlayout;
    private LinearLayout exampleBody;

    private static boolean needLoad = false;
    
    
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate the layout for our example sentence activity
        ESlayout = (RelativeLayout)inflater.inflate(R.layout.example_sentence, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout exampleBack = (RelativeLayout)ESlayout.findViewById(R.id.example_mainlayout);
        XflashSettings.setupPracticeBack(exampleBack);
        
        // load and set the count bar values
        refreshCountBar();
        
        // set the reading
        TextView tempView = (TextView)ESlayout.findViewById(R.id.es_readingtext);
        tempView.setText( currentCard.reading() );

        // set the headword
        tempView = (TextView)ESlayout.findViewById(R.id.es_headword);
        tempView.setText( currentCard.getHeadword() );
        
        // get the view body to add our example sentence rows
        exampleBody = (LinearLayout)ESlayout.findViewById(R.id.es_body);
        
        // only reload the ArrayList via database if our card has changed
        if( needLoad )
        {
            XFApplication.getDao().attachDatabase(LWEDatabase.DB_EX);
            esList = ExampleSentencePeer.getExampleSentencesByCardId( currentCard.getCardId() );
            XFApplication.getDao().detachDatabase(LWEDatabase.DB_EX);

            needLoad = false;
        }

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
            Button tempReadButton = (Button)esRow.findViewById(R.id.es_readbutton);
            tempReadButton.setTag(tempSentenceId);

            // set a click listener for the read button of each row
            tempReadButton.setOnClickListener( new View.OnClickListener()
            {
                @Override
                public void onClick(View v)
                {
                    toggleRead(v);
                }
            });

            exampleBody.addView(esRow);

        }  // end for loop
       
        setAnswerBarListeners();

        return ESlayout;

    }  // end onCreateView()


    // called by PracticeFragment to set new values
    public static void loadCard(JapaneseCard inCard,int[] inCounts)
    {
        // don't do anything if it's the card we've already loaded
        if( ( currentCard == null ) || ( !currentCard.isEqual(inCard) ) )
        {
            currentCard = inCard;
            needLoad = true;
            
            // refresh the local card counts
            for(int i = 0; i < 5; i++)
            {
                practiceCardCounts[i] = inCounts[i];
            }
        }

    }  // end loadCard()

    
    // sets onClick listeners for the three buttons in the answer bar
    private void setAnswerBarListeners()
    {
        ImageButton tempButton = (ImageButton)ESlayout.findViewById(R.id.es_optionblock_actions);
        tempButton.setOnClickListener(exampleClickListener);

        tempButton = (ImageButton)ESlayout.findViewById(R.id.es_optionblock_right);
        tempButton.setOnClickListener(exampleClickListener);

        tempButton = (ImageButton)ESlayout.findViewById(R.id.es_optionblock_wrong);
        tempButton.setOnClickListener(exampleClickListener);

        tempButton = (ImageButton)ESlayout.findViewById(R.id.es_optionblock_goaway);
        tempButton.setOnClickListener(exampleClickListener);


    }  // end setAnswerBarListeners()


    private void refreshCountBar()
    {
        TextView cardCountViews[] = { null, null, null, null, null };

        cardCountViews[0] = (TextView)ESlayout.findViewById(R.id.es_study_num);
        cardCountViews[1] = (TextView)ESlayout.findViewById(R.id.es_right1_num);
        cardCountViews[2] = (TextView)ESlayout.findViewById(R.id.es_right2_num);
        cardCountViews[3] = (TextView)ESlayout.findViewById(R.id.es_right3_num);
        cardCountViews[4] = (TextView)ESlayout.findViewById(R.id.es_learned_num);

        for(int i = 0; i < 5; i++)
        {
            cardCountViews[i].setText( Integer.toString( practiceCardCounts[i] ) );
        }

    }  // end refreshCountBar()

    
    // method called when any button in the options block is clicked
    private void exampleClick(View v)
    {
        // remove the transition to the example sentence fragment
        XflashScreen.popBackPractice();
        XflashScreen.setPracticeOverride();
        
        PracticeFragment.setPracticeBlank();
        Xflash.getActivity().onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);
    }


    // TODO - compiler is demanding this be static
    
    // launch AddCardToTagFragment as a modal Activity
    private static void addCard(View v)
    {
        int tempInt = (Integer)v.getTag();
        
        // load the card to AddCardToTagFragment, as it is the layout
        // and functionality for AddCardActivity
        AddCardToTagFragment.loadCard(tempInt);

        Xflash myContext = Xflash.getActivity();
        
        // launch the Activity - modal
        Intent myIntent = new Intent(myContext,AddCardActivity.class);
        myContext.startActivity(myIntent);
    
    }  // end addCard()


    // open or close the view containing all cards in any
    // given example sentence
    private void toggleRead(View v)
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
            loadExampleSentenceBlock(tempReadButton,tempSentenceId,cardBlock);
        } 

    }  // end toggleRead()

    
    private void loadExampleSentenceBlock(Button tempReadButton,int tempSentenceId,LinearLayout cardBlock)
    {
        LayoutInflater inflater = (LayoutInflater)Xflash.getActivity().getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        FrameLayout tempDivider = (FrameLayout)inflater.inflate(R.layout.divider,null);
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
            RelativeLayout tempWordRow = (RelativeLayout)inflater.inflate(R.layout.es_card_row,null);

            // headword
            TextView tempView = (TextView)tempWordRow.findViewById(R.id.es_cardrow_headword);
            tempView.setText( tempCard.headwordIgnoringMode(true) );

            // reading
            tempView = (TextView)tempWordRow.findViewById(R.id.es_cardrow_reading);
            tempView.setText( tempCard.reading() );

            // tag the button for addCard() with the card id
            Button tempAddButton = (Button)tempWordRow.findViewById(R.id.es_cardrow_button);
            tempAddButton.setTag( tempCard.getCardId() );

            // set a click listener for the 'add card' button for each card/word
            tempAddButton.setOnClickListener( new View.OnClickListener()
            {
                @Override
                public void onClick(View v)
                {
                    // TODO - compiler is claiming this is a static call?
                    addCard(v);
                }
            });

            // add the word/card row
            cardBlock.addView(tempWordRow); 
                
            // add a divider at the end
            tempDivider = (FrameLayout)inflater.inflate(R.layout.divider,null);
            cardBlock.addView(tempDivider);
        }

        // add the bottom margin layout
        tempDivider = (FrameLayout)inflater.inflate(R.layout.es_word_margin,null);
        cardBlock.addView(tempDivider);
            
        // change the button and show the cards
        tempReadButton.setText("Close");
        cardBlock.setVisibility(View.VISIBLE);

    }  // end loadExampleSentenceBlock()

    
    // click listener for the answer bar buttons
    private View.OnClickListener exampleClickListener = new View.OnClickListener()
    {
        @Override
        public void onClick(View v)
        {
            exampleClick(v);
        }
    };


}  // end ExampleSentenceFragment class declaration





