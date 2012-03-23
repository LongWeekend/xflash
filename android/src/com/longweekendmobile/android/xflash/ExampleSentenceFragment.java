package com.longweekendmobile.android.xflash;

//  ExampleSentenceFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/8/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  private void setAnswerBarListeners()
//  private void refreshCountBar();
//  private void exampleClick(View  )
//  private void addCard(View  )
//  private void toggleRead(View  )
//  private void loadExampleSentenceBlock(Button  ,int  ,LinearLayout  )

import java.util.ArrayList;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.ExampleSentence;
import com.longweekendmobile.android.xflash.model.ExampleSentencePeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.LWEDatabase;
import com.longweekendmobile.android.xflash.model.Tag;

public class ExampleSentenceFragment extends Fragment
{
    private static final String MYTAG = "XFlash ExampleSentenceFragment";
    
    private static ArrayList<ExampleSentence> esList = null;
    
    private RelativeLayout ESlayout;
    private LinearLayout exampleBody;
    
    private Tag currentTag;
    private JapaneseCard currentCard;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate the layout for our example sentence activity
        ESlayout = (RelativeLayout)inflater.inflate(R.layout.example_sentence, container, false);

        currentTag = XflashSettings.getActiveTag();
        currentCard = (JapaneseCard)XflashSettings.getActiveCard();

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
        XFApplication.getDao().attachDatabase(LWEDatabase.DB_EX);
        esList = ExampleSentencePeer.getExampleSentencesByCardId( currentCard.getCardId() );
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


    // sets onClick listeners for the three buttons in the answer bar
    private void setAnswerBarListeners()
    {
        int ESbuttons[] = { R.id.es_optionblock_right, R.id.es_optionblock_wrong,
                                       R.id.es_optionblock_goaway };

        for(int i = 0; i < ESbuttons.length; i++)
        {
           ImageButton tempButton = (ImageButton)ESlayout.findViewById( ESbuttons[i] );
           tempButton.setOnClickListener(exampleClickListener);
        }

    }  // end setAnswerBarListeners()


    private void refreshCountBar()
    {
        int seenCardCount = currentTag.getSeenCardCount();
        int thisLevelCount = seenCardCount;

        int progressBars[] = { R.id.es_study_progress, R.id.es_right1_progress, R.id.es_right2_progress,
                               R.id.es_right3_progress, R.id.es_learned_progress };

        int cardCountViews[] = { R.id.es_study_num, R.id.es_right1_num, R.id.es_right2_num,
                                 R.id.es_right3_num, R.id.es_learned_num };

        // I *think* this is operating the way you want it to... though I 
        // completely fail to understand what we're displaying, so I'm not sure
        for(int i = 1; i < 6; i++)
        {
            if( i > 1 )
            {
                thisLevelCount -= currentTag.cardLevelCounts.get( (i - 1) );
            }

            // set the progress bar backgrounds
            // apparently ProgressBar is buggy as shit, and no one knows why. I'd post a link
            // but there's nothing coherent out there. If you have to work with them, expect
            // to be pissed off.  You've been warned.

            // these shouldn't need to be final, but for their use in an inner class
            // below to set the progress and post a delayed invalidation
            final ProgressBar tempProgress = (ProgressBar)ESlayout.findViewById( progressBars[i - 1] );
            final float progress;

            if( seenCardCount > 0 )
            {
                progress = (float)thisLevelCount / (float)seenCardCount;
            }
            else
            {
                progress = 0.0f;
            }

            // this shouldn't be necessary
            tempProgress.postDelayed( new Runnable()
            {
                @Override
                public void run()
                {
                    // this shouldn't be necessary either
                    tempProgress.setProgress( (int)( 100 * progress ) );
                    tempProgress.postInvalidate();
                }
            },350);

            // set the label numbers
            TextView tempCount = (TextView)ESlayout.findViewById( cardCountViews[i - 1] );
            tempCount.setText( Integer.toString( currentTag.cardLevelCounts.get(i) ) );

        }  // end for loop

        // set a click listerer to fire the Practice summary
        LinearLayout countBar = (LinearLayout)ESlayout.findViewById(R.id.example_sentence_bar);
        countBar.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                PracticeFragment.summaryPassThrough();
            }
        });

    }  // end refreshCountBar()

    
    // method called when any button in the options block is clicked
    private void exampleClick(View v)
    {
        switch( v.getId() )
        {
            case R.id.es_optionblock_right:     PracticeFragment.setRight();
                                                break;

            case R.id.es_optionblock_wrong:     PracticeFragment.setWrong();
                                                break;

            case R.id.es_optionblock_goaway:    PracticeFragment.setGoAway();
                                                break;

            default:    Log.d(MYTAG,"ERROR - exampleClick() passed invalied button id");

        }  // end switch( example button )
        
        PracticeCardSelector.setNextPracticeCard(currentTag,currentCard);

        // reload Practice
        XflashScreen.popBackPractice();
        PracticeFragment.setPracticeBlank();
        XflashScreen.setPracticeOverride();
        Xflash.getActivity().onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);

    }  // end exampleClick()


    // launch AddCardToTagFragment as a modal Activity
    private void addCard(View v)
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





