package com.longweekendmobile.android.xflash;

//  PracticeFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void reveal()
//  public static void toggleReading()
//  public static void practiceClick(View  ,Xflash  )
//  public static void browseClick(View  ,Xflash  )
//  public static void goRight(Xflash  )
//  public static void setPracticeBlank()
//
//  private static class PracticeScreen
//
//      public static void initialize()
//      public static void setupPracticeView(int  )
//      public static void setAnswerBar(int  )
//      public static void toggleReading()

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.Tag;

public class PracticeFragment extends Fragment
{
    private static final String MYTAG = "XFlash PracticeFragment";
    
    // properties for handling color theme transitions
    private static RelativeLayout practiceLayout;

    public static final int PRACTICE_VIEW_BLANK = 0;
    public static final int PRACTICE_VIEW_BROWSE = 1;
    public static final int PRACTICE_VIEW_REVEAL = 2;

    private static int practiceViewStatus = -1;

    private static Tag currentTag = null;
    private static int incomingTagId = -1000;
    
    private static JapaneseCard currentCard = null;

    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate the layout for our practice activity
        practiceLayout = (RelativeLayout)inflater.inflate(R.layout.practice, container, false);

        // TODO - debugging
        currentCard = (JapaneseCard)CardPeer.retrieveCardByPK(112000);
        
        // set up view based on current study mode
        if( XflashSettings.getStudyMode() == XflashSettings.LWE_STUDYMODE_PRACTICE )    
        {
            // if we're not revealed, reset to blank (in case of mode change)
            if( practiceViewStatus != PRACTICE_VIEW_REVEAL )
            {
                practiceViewStatus = PRACTICE_VIEW_BLANK;
            }
        }
        else  
        {
            practiceViewStatus = PRACTICE_VIEW_BROWSE;
        } 
    
        // load all view elements and set up based on view status
        PracticeScreen.initialize();
        PracticeScreen.setupPracticeView(practiceViewStatus);

        return practiceLayout;

    }  // end onCreateView()


    public static void setIncomingTagId(int inId)
    {
        incomingTagId = inId;
    }

    
    // called by Xflash when someone clicks 'tap for answer'
    public static void reveal()
    {
        PracticeScreen.setupPracticeView(PRACTICE_VIEW_REVEAL);
    }


    // called by Xflash when the reading is clicked on
    public static void toggleReading()
    {
        PracticeScreen.toggleReading();
    }
    
    
    // method called when any button in the options block is clicked
    public static void practiceClick(View v,Xflash inContext)
    {
        // load the next practice view without adding to the back stack
        XflashScreen.setPracticeOverride();
        practiceViewStatus = PRACTICE_VIEW_BLANK;
        inContext.onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);
    }


    // method called when any button in the options block is clicked
    public static void browseClick(View v,Xflash inContext)
    {
        switch( v.getId() )
        {
            case R.id.browseblock_last:     inContext.onScreenTransition("practice",XflashScreen.DIRECTION_CLOSE);
                                            break;
            case R.id.browseblock_actions:  break;
            case R.id.browseblock_next:     inContext.onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);
                                            break;  
        } 
    }


    // method called when user click to queue the extra screen
    public static void goRight(Xflash inContext)
    {
        // load the ExampleSentenceFragment to the fragment tab manager
        inContext.onScreenTransition("example_sentence",XflashScreen.DIRECTION_OPEN);
    }


    // called by ExampleSentenceFragment to reset the view
    public static void setPracticeBlank()
    {
        practiceViewStatus = PRACTICE_VIEW_BLANK;
    }


    // class to manage screen setup
    private static class PracticeScreen
    {
        // used for toggle of reading view
        private static boolean readingTextVisible = false; 
        
        // all of the layout views
        private static ImageButton blankButton = null;
        private static ImageButton rightArrow = null;
        private static ImageButton showReadingButton = null;
        private static ImageView hhBubble = null;
        private static ImageView hhImage = null;
        private static ImageView miniAnswerImage = null;
        private static LinearLayout countBar = null;
        private static RelativeLayout browseFrame = null;
        private static RelativeLayout showFrame = null;
        private static TextView answerTextView = null;
        private static TextView headwordView = null;
        private static TextView hhView = null;
        private static TextView showReadingText = null;
        
        public static void initialize()
        {
            // load the title bar and background elements and pass them to the color manager
            RelativeLayout practiceBack = (RelativeLayout)PracticeFragment.practiceLayout.findViewById(R.id.practice_mainlayout);
            XflashSettings.setupPracticeBack(practiceBack);
        
            // load the progress count bar
            countBar = (LinearLayout)practiceLayout.findViewById(R.id.count_bar);
            
            // load the show-reading button
            showReadingButton = (ImageButton)PracticeFragment.practiceLayout.findViewById(R.id.practice_showreadingbutton);

            // load the show-reading text
            showReadingText = (TextView)PracticeFragment.practiceLayout.findViewById(R.id.practice_readingtext);
            showReadingText.setText( currentCard.reading() );

            // load the headword view
            headwordView = (TextView)PracticeFragment.practiceLayout.findViewById(R.id.practice_headword);
            headwordView.setText( currentCard.getHeadword() );

            // load the actual card answer
            answerTextView = (TextView)practiceLayout.findViewById(R.id.practice_answertext);
            answerTextView.setText( currentCard.getJustHeadwordEN() );

            // load the mini answer button
            miniAnswerImage = (ImageView)practiceLayout.findViewById(R.id.practice_minianswer);
            
            // load the hot head
            hhImage = (ImageView)practiceLayout.findViewById(R.id.practice_hothead);
            
            // load the hot head's image bubble
            hhBubble = (ImageView)practiceLayout.findViewById(R.id.practice_hhbubble);
                
            // load the hot head percentage view
            hhView = (TextView)practiceLayout.findViewById(R.id.practice_talkbubble_text);
    
            // load the resources for the answer bar
            blankButton = (ImageButton)practiceLayout.findViewById(R.id.practice_answerbutton);
            browseFrame = (RelativeLayout)practiceLayout.findViewById(R.id.browse_options_block);
            rightArrow = (ImageButton)practiceLayout.findViewById(R.id.practice_rightbutton);
            showFrame = (RelativeLayout)practiceLayout.findViewById(R.id.practice_options_block);
        
        }  // end PracticeScreen.initialize()
        
        
        // set all widgets to the card-hidden state
        public static void setupPracticeView(int inViewMode)
        {
            if( inViewMode == PRACTICE_VIEW_BLANK )
            {
                // set up for blank view
                answerTextView.setVisibility(View.GONE);
                hhImage.setVisibility(View.VISIBLE);
                hhBubble.setVisibility(View.VISIBLE);
                hhView.setText("100%");
                hhView.setVisibility(View.VISIBLE);
                readingTextVisible = false;
                rightArrow.setVisibility(View.GONE);
                showReadingButton.setVisibility(View.VISIBLE);
                showReadingText.setVisibility(View.GONE);
            }
            else if( inViewMode == PRACTICE_VIEW_BROWSE )
            {
                // set up for browse view
                answerTextView.setVisibility(View.VISIBLE);
                countBar.setVisibility(View.GONE);
                hhImage.setVisibility(View.GONE);
                hhBubble.setVisibility(View.GONE);
                hhView.setVisibility(View.GONE);
                miniAnswerImage.setVisibility(View.GONE);
                readingTextVisible = false;
                rightArrow.setVisibility(View.GONE);
                showReadingButton.setVisibility(View.GONE);
                showReadingText.setVisibility(View.VISIBLE);
            }   
            else 
            {
                // set up for reveal
                answerTextView.setVisibility(View.VISIBLE);
                hhImage.setVisibility(View.VISIBLE);
                hhBubble.setVisibility(View.VISIBLE);
                hhView.setText("100%");
                hhView.setVisibility(View.VISIBLE);
                miniAnswerImage.setVisibility(View.GONE);
                readingTextVisible = true;
                rightArrow.setVisibility(View.VISIBLE);
                showReadingButton.setVisibility(View.GONE);
                showReadingText.setVisibility(View.VISIBLE);
                showReadingText.setClickable(false);

            }  // end if block for ( inViewMode )

            practiceViewStatus = inViewMode;
            setAnswerBar(practiceViewStatus);
    
        }  // end PracticeScreen.setupPracticeView()
    

        // method called when user taps to reveal the answer
        public static void setAnswerBar(int inMode)
        {
            // set what should be visible based on study mode
            switch(inMode)
            {
                case PRACTICE_VIEW_BLANK:   browseFrame.setVisibility(View.GONE);
                                            showFrame.setVisibility(View.GONE);
                                            blankButton.setVisibility(View.VISIBLE);
                                            break;
                case PRACTICE_VIEW_BROWSE:  blankButton.setVisibility(View.GONE);
                                            showFrame.setVisibility(View.GONE);
                                            browseFrame.setVisibility(View.VISIBLE);
                                            break;
                case PRACTICE_VIEW_REVEAL:  blankButton.setVisibility(View.GONE);
                                            browseFrame.setVisibility(View.GONE);
                                            showFrame.setVisibility(View.VISIBLE);
                                            break;
                default:    Log.d(MYTAG,"Error in PracticeScreen.setAnswerBar()  :  invalid study mode: " + inMode);
            } 

        }  // end PracticeScreen.setAnswerBar()


        // flip between 'show reading' button and the actual reading value
        public static void toggleReading()
        {
            if( readingTextVisible )
            {
                showReadingText.setVisibility(View.GONE);
                showReadingButton.setVisibility(View.VISIBLE); 
                readingTextVisible = false;
            }
            else
            {
                showReadingButton.setVisibility(View.GONE);
                showReadingText.setVisibility(View.VISIBLE);
                readingTextVisible = true;
            }
    
        }  // end PracticeScreen.toggleReading()


    }  // end PracticeScreen class declaration


}  // end PracticeFragment class declaration





