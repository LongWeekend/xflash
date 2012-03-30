package com.longweekendmobile.android.xflash;

//  PracticeFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  external class to handle display of PracticeFragment
//
//      *** ALL METHODS STATIC ***
//
//  public void initialize(RelativeLayout  )
//  public void dump()
//  public void setupPracticeView(int  )
//  public void showSummary()
//
//  private void setAnswerBar(int  )
//  private void toggleReading()
//  private void refreshCountBar()
//  private void loadMeaning()
//  private int getHHResource(int  )
//  private void setClickListeners()
//
//  TODO - this works, but could probably use some refactoring. Also, it feels
//       - wrong to declare the click listeners here, then have them call
//       - methods back in PracticeFragment. But it'd be worse to move all of
//       - the business logic from PracticeFragment to PracticeScreen (I think?)
//       - and all the views we're setting the listeners TO are here so...

import android.app.AlertDialog;
import android.content.Context;
import android.content.res.Resources;
import android.text.Spannable;
import android.text.style.ForegroundColorSpan;
import android.text.style.RelativeSizeSpan;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.TextView.BufferType;

import com.longweekendmobile.android.xflash.model.ExampleSentencePeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.LWEDatabase;
import com.longweekendmobile.android.xflash.model.Tag;

public class PracticeScreen
{
    private static final String MYTAG = "XFlash PracticeScreen";
    
    public static final int PRACTICE_VIEW_BLANK = 0;
    public static final int PRACTICE_VIEW_BROWSE = 1;
    public static final int PRACTICE_VIEW_REVEAL = 2;

    // used for toggle of reading view
    private static boolean readingTextVisible = false; 
       
    private static RelativeLayout practiceLayout = null;
        
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
    private static RelativeLayout practiceBack = null;
    private static RelativeLayout practiceScrollBack = null;
    private static TextView headwordView = null;
    private static TextView hhView = null;
    private static TextView showReadingText = null;
    
    private static int percentageRight = 100;
        
    private static Tag currentTag = null;
    private static JapaneseCard currentCard = null;

    public static void initialize(RelativeLayout inLayout,Tag inTag,JapaneseCard inCard)
    {
        practiceLayout = inLayout;
        currentTag = inTag;
        currentCard = inCard;
            
        // load the title bar and background elements and pass them to the color manager
        practiceBack = (RelativeLayout)practiceLayout.findViewById(R.id.practice_mainlayout);
        XflashSettings.setupPracticeBack(practiceBack);

        practiceScrollBack = (RelativeLayout)practiceLayout.findViewById(R.id.practice_scroll_back);
        
        // load the progress count bar
        countBar = (LinearLayout)practiceLayout.findViewById(R.id.count_bar);
           
        // load the show-reading button
        showReadingButton = (ImageButton)practiceLayout.findViewById(R.id.practice_showreadingbutton);
            
        // load the show-reading text
        showReadingText = (TextView)practiceLayout.findViewById(R.id.practice_readingtext);
        showReadingText.setText( currentCard.reading() );
            
        // load the headword view - variable based on study language in Card.java
        headwordView = (TextView)practiceLayout.findViewById(R.id.practice_headword);
        headwordView.setText( currentCard.getHeadword() );
           
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
       
        // load the tag name
        TextView tempPracticeInfo = (TextView)practiceLayout.findViewById(R.id.practice_tag_name);
        tempPracticeInfo.setText( currentTag.getName() );

        // load the tag card count
        String tempString = null;
        if( PracticeFragment.practiceViewStatus != PRACTICE_VIEW_BROWSE )
        {
            tempString = Integer.toString( ( currentTag.getCardCount() - 
                                             currentTag.getSeenCardCount() ) );
        }
        else
        {
            tempString = Integer.toString( currentTag.getCurrentIndex() + 1 );
        }

        tempString = tempString + " / ";
        tempString = tempString + Integer.toString( currentTag.getCardCount() );

        tempPracticeInfo = (TextView)practiceLayout.findViewById(R.id.practice_tag_count);
        tempPracticeInfo.setText(tempString);

        percentageRight = (int)( 100 * ( (float)PracticeFragment.numRight / (float)PracticeFragment.numViewed ) );
            
        // set all of our click listeners
        PracticeScreen.setClickListeners();
            
    }  // end PracticeScreen.initialize()
       
        
    // dumps all static variables dealing with layout
    public static void dump()
    {
        practiceLayout = null;
        blankButton = null;
        rightArrow = null;
        showReadingButton = null;
        hhBubble = null;
        hhImage = null;
        miniAnswerImage = null;
        countBar = null;
        browseFrame = null;
        showFrame = null;
        practiceBack = null;
        practiceScrollBack = null;
        headwordView = null;
        hhView = null;
        showReadingText = null;

    }  // end dump()
       

    // set all widgets to the card-hidden state
    public static void setupPracticeView(int inViewMode)
    {
        if( inViewMode == PRACTICE_VIEW_BLANK )
        {
            // set up for blank view
            hhImage.setVisibility(View.VISIBLE);
            hhBubble.setVisibility(View.VISIBLE);
            hhView.setText( Integer.toString( percentageRight ) + "%" );
            hhView.setVisibility(View.VISIBLE);
            rightArrow.setVisibility(View.GONE);
            showReadingButton.setVisibility(View.VISIBLE);
            if( readingTextVisible )
            {
                showReadingButton.setVisibility(View.GONE);
                showReadingText.setVisibility(View.VISIBLE);
            }
            else
            {
                showReadingText.setVisibility(View.GONE);
                showReadingButton.setVisibility(View.VISIBLE);
            }

            // enable reveal clicks on the body content in blank mode
            practiceScrollBack.setClickable(true);
        }
        else if( inViewMode == PRACTICE_VIEW_BROWSE )
        {
            // set up for browse view
            countBar.setVisibility(View.INVISIBLE);
            hhImage.setVisibility(View.GONE);
            hhBubble.setVisibility(View.GONE);
            hhView.setVisibility(View.GONE);
            miniAnswerImage.setVisibility(View.GONE);
            rightArrow.setVisibility(View.GONE);
            showReadingButton.setVisibility(View.GONE);
            if( readingTextVisible )
            {
                showReadingButton.setVisibility(View.GONE);
                showReadingText.setVisibility(View.VISIBLE);
            }
            else
            {
                showReadingText.setVisibility(View.GONE);
                showReadingButton.setVisibility(View.VISIBLE);
            }

            // set and display the answer
            loadMeaning();
        }   
        else 
        {
            // set up for reveal
            hhImage.setVisibility(View.VISIBLE);
            hhBubble.setVisibility(View.VISIBLE);
            hhView.setText( Integer.toString( percentageRight ) + "%" );
            hhView.setVisibility(View.VISIBLE);
            miniAnswerImage.setVisibility(View.GONE);
            showReadingText.setVisibility(View.VISIBLE);
                
            // temporarily show the reading and disable the click
            showReadingButton.setVisibility(View.GONE);
            showReadingText.setVisibility(View.VISIBLE);
            showReadingText.setClickable(false);
                
            // only display the arrow if example sentences exist
            XFApplication.getDao().attachDatabase(LWEDatabase.DB_EX);
            if( ExampleSentencePeer.sentencesExistForCardId( currentCard.getCardId() ) )
            {
                rightArrow.setVisibility(View.VISIBLE);
            }
            XFApplication.getDao().detachDatabase(LWEDatabase.DB_EX);

            // set and display the answer
            loadMeaning();
                
        }  // end if block for ( inViewMode )

        // set the hot head resource
        hhImage.setImageResource( getHHResource(percentageRight) );

        PracticeFragment.practiceViewStatus = inViewMode;
        setAnswerBar(PracticeFragment.practiceViewStatus);
        refreshCountBar();
        
    }  // end PracticeScreen.setupPracticeView()
    

    // show the big summary dialog
    public static void showSummary()
    {
        final Xflash inContext = Xflash.getActivity();
        Resources res = inContext.getResources();

        AlertDialog.Builder builder;

        // inflate the dialog layout into a View object
        LayoutInflater inflater = (LayoutInflater)inContext.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View layout = inflater.inflate(R.layout.practice_summary, (ViewGroup)inContext.findViewById(R.id.summary_root));

        builder = new AlertDialog.Builder(inContext);
        builder.setView(layout);

        final AlertDialog summaryDialog = builder.create();
        summaryDialog.show();

        // we cannot reference our buttons until after the dialog.show()
        // method has been called - otherwise they don't "exist" 
        
        // set the title
        TextView tempView = (TextView)summaryDialog.findViewById(R.id.summary_tag);
        tempView.setText( currentTag.getName() );

        // set the studying description
        // it's a damn shame that using HTML in TextViews is a bit iffy
        String des1 = res.getString(R.string.psummary_des1) + "  ";
        String des2 = "  " + res.getString(R.string.psummary_des2) + "  ";
        String des3 = "  " + res.getString(R.string.psummary_des3);

        int totalCards = currentTag.getCardCount();
        int studyNum = XflashSettings.getStudyPool();
        if( studyNum > totalCards )
        {
            studyNum = totalCards;
        }
            
        String stringStudyNum = Integer.toString(studyNum) + "*";
        String stringTotalCards = Integer.toString(totalCards);

        int studyNumStart = des1.length();
        int studyNumEnd = studyNumStart + stringStudyNum.length();

        int totalCardsStart = studyNumEnd + des2.length();
        int totalCardsEnd = totalCardsStart + stringTotalCards.length();

        tempView = (TextView)summaryDialog.findViewById(R.id.summary_description);
        tempView.setText( des1 + stringStudyNum + des2 + stringTotalCards + des3, BufferType.SPANNABLE );

        Spannable willThisWork = (Spannable)tempView.getText();
        willThisWork.setSpan( new RelativeSizeSpan(1.2f), studyNumStart, studyNumEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE );
        willThisWork.setSpan( new RelativeSizeSpan(1.2f), totalCardsStart, totalCardsEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE );

        // set the subtext 
        String sub1 = res.getString(R.string.psummary_sub1) + " ";
        String sub2 = res.getString(R.string.psummary_sub2);

        tempView = (TextView)summaryDialog.findViewById(R.id.summary_subtext);
        tempView.setText( sub1 + sub2, BufferType.SPANNABLE );

        Spannable s = (Spannable)tempView.getText();
        int start = sub1.length();
        int end = start + sub2.length();
        s.setSpan( new ForegroundColorSpan(0xFFEDF68C), start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        
        // set the table view 
            
        // set the right count
        tempView = (TextView)summaryDialog.findViewById(R.id.summary_right_count);
        tempView.setText( Integer.toString( PracticeFragment.numRight ) );

        // set the wrong count
        tempView = (TextView)summaryDialog.findViewById(R.id.summary_wrong_count);
        tempView.setText( Integer.toString( PracticeFragment.numWrong ) );

        // set the streak
        String streak = null;
        if( ( PracticeFragment.rightStreak < 2 ) && ( PracticeFragment.wrongStreak < 2 ) )
        {
            // don't display a streak unless it's at least 2 in a row
            streak = "-";
        }
        else if( PracticeFragment.rightStreak > 0 )
        {
            streak = Integer.toString( PracticeFragment.rightStreak ) + " " + res.getString(R.string.psummary_right);
        }
        else
        {
            streak = Integer.toString( PracticeFragment.wrongStreak ) + " " + res.getString(R.string.psummary_wrong);
        }
            
        tempView = (TextView)summaryDialog.findViewById(R.id.summary_streak_count);
        tempView.setText(streak);

        // set the cards seen
        int seenCount = currentTag.getSeenCardCount();

        String seen = null;
        if( seenCount > 0 )
        {
            seen = Integer.toString(seenCount);
        }
        else
        {
            seen = "-";
        }

        tempView = (TextView)summaryDialog.findViewById(R.id.summary_seen_count);
        tempView.setText(seen);

        // set the progress stuff
        int progressBars[] = { R.id.summary_untested_progress, R.id.summary_studying_progress,
                               R.id.summary_right1x_progress,  R.id.summary_right2x_progress,
                               R.id.summary_right3x_progress,  R.id.summary_learned_progress };
        int valuesViews[] = { R.id.summary_untested_values, R.id.summary_studying_values,
                               R.id.summary_right1x_values,  R.id.summary_right2x_values,
                               R.id.summary_right3x_values,  R.id.summary_learned_values };

        for(int i = 0; i < valuesViews.length; i++)
        {
            int levelCount = currentTag.cardsByLevel.get(i).size();
            float percentage = ( (float)levelCount / (float)totalCards );
            
            String toSet = Integer.toString( (int)( 100 * percentage ) ) +
                           "% - " + Integer.toString(levelCount);

            // set the progress bar
            ProgressBar tempProgress = (ProgressBar)summaryDialog.findViewById( progressBars[i] );
            tempProgress.setProgress( (int)( 100 * percentage ) );
                
            // set the level count description
            tempView = (TextView)summaryDialog.findViewById( valuesViews[i] );
            tempView.setText(toSet);
        } 
           
        // set the cancel button
        ImageButton cancelButton = (ImageButton)summaryDialog.findViewById(R.id.summary_cancel);
        cancelButton.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                summaryDialog.dismiss();
            }
        });
            
    }  // end showSummary()
  

    // method called when user taps to reveal the answer
    private static void setAnswerBar(int inMode)
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
    private static void toggleReading()
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

        
    // set all TextView elements of the count bar to the current values
    private static void refreshCountBar()
    {
        int seenCardCount = currentTag.getSeenCardCount();
        int thisLevelCount = seenCardCount;
            
        int progressBars[] = { R.id.study_progress, R.id.right1_progress, R.id.right2_progress,
                                   R.id.right3_progress, R.id.learned_progress };

        int cardCountViews[] = { R.id.study_num, R.id.right1_num, R.id.right2_num,
                                     R.id.right3_num, R.id.learned_num };

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
            final ProgressBar tempProgress = (ProgressBar)practiceLayout.findViewById( progressBars[i - 1] );
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
            TextView tempCount = (TextView)practiceLayout.findViewById( cardCountViews[i - 1] );
            tempCount.setText( Integer.toString( currentTag.cardLevelCounts.get(i) ) );

        }  // end for loop

    }  // end refreshCountBar()


    // load and display HTML for the meaning WebView
    private static void loadMeaning()
    {
        // get the WebView for displaying the answer
        NoHorizontalWebView meaningView = (NoHorizontalWebView)practiceLayout.findViewById(R.id.practice_webview);
        meaningView.getSettings().setSupportZoom(false);
        meaningView.setHorizontalScrollBarEnabled(false);
                
        // load the html/css header for the meaning view
        String header = null;
        if( XflashSettings.getStudyLanguage() == XflashSettings.LWE_STUDYLANGUAGE_JAPANESE )
        {
            header = LWECardHtmlHeader;
        }
        else
        {
            header = LWECardHtmlHeader_EtoJ;
        }

        // swap out the dfn declaration based on color scheme
        header = header.replace("##SIZECSS##", XflashSettings.getAnswerSizeCSS() );
        header = header.replace("##THEMECSS##", XflashSettings.getThemeCSS() );
            
        // set up the full web view data
        String data = header + currentCard.getMeaning() + LWECardHtmlFooter;
                
        // we cannot use WebView.loadData(String,String,String) because for reasons
        // not well articulated online, though apparently loadData presumes the string
        // is URI encoded and needs to be changed to URL encoding

        // use loadDataWithBaseURL() with a fake or null URL instead
        // http://groups.google.com/group/android-developers/browse_thread/thread/f70c3cb62ec2a97b/1d5e0cd326c14e0b 
        meaningView.loadDataWithBaseURL(null,data,"text/html","utf-8",null);

        // WebView background must be set to transparency
        // programatically or it won't work (known bug Android 2.2.x and up)
        // see - http://code.google.com/p/android/issues/detail?id=14749
        meaningView.setBackgroundColor(0x00000000);

    }  // end loadMeaning()


    // returns the valid Hot Head image resource based on
    // incoming percentage correct
    private static int getHHResource(int inPercent)
    {
        int hhArray[] = XflashSettings.getHHArray();

        int a = 100; 
        int iterator = 0;
        int resourceToReturn = 0;

        while( a >= 0 )
        {
            if ( ( inPercent <= a ) && ( inPercent > ( a - 10 ) ) )
            {
                resourceToReturn = hhArray[iterator];
                break;
            }
            
            a -= 10;
            ++iterator;
        }
  
        return resourceToReturn;

    }  // end getHHResource()

    
    // set click listeners for all relevant views
    private static void setClickListeners()
    {
        // listener for the count bar
        countBar.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                showSummary();
            }
        });
            

        // listener for the 'tap for answer' answer bar
        blankButton.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                PracticeFragment.reveal();
            }
        });

        // THE PRACTICE-MODE ANSWER BAR
            
        // set listeners for each of the reveal buttons
        int[] buttonIds = { R.id.optionblock_right, R.id.optionblock_wrong, 
                            R.id.optionblock_goaway };

        for(int i = 0; i < buttonIds.length; i++)
        {
            ImageButton tempButton = (ImageButton)practiceLayout.findViewById( buttonIds[i] );
            tempButton.setOnClickListener(practiceClickListener);
        }

        // THE BROWSE-MODE ANSWER BAR
            
        // set listeners for each of the browse buttons
        buttonIds = new int[] { R.id.browseblock_last, R.id.browseblock_next };

        for(int i = 0; i < 2; i++)
        {
            ImageButton tempButton = (ImageButton)practiceLayout.findViewById( buttonIds[i] );
            tempButton.setOnClickListener(browseClickListener);
        }

        // listener for the main scroll view
        practiceScrollBack.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                PracticeFragment.reveal();
            }
        });

        // listener for 'show reading' button
        showReadingButton.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                PracticeScreen.toggleReading();
            }
        });

        // listener for reading text 
        showReadingText.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                PracticeScreen.toggleReading();
            }
        });

        // listener for 'go right' button to example sentences
        rightArrow.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                PracticeFragment.goRight();
            }
        });

    }  // end setClickListeners()
        
        
    private static String LWECardHtmlHeader =
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />" +
"<style>" +
"body{ background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:center; line-height:21px; ##SIZECSS## font-weight:bold; font-family:Helvetica,sanserif; color:#fff; text-shadow:darkslategray 0px 1px 0px; } " +
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} " +
"#container{width:300px; display:table-cell; vertical-align:middle;text-align:center;} " + 
"ol{color:white; text-align:left; width:240px; margin:0px; margin-left:24px; padding-left:10px;} " +
"li{color:white; text-shadow:darkslategray 0px 1px 0px; margin:0px; margin-bottom:7px; line-height:17px;} " +
"##THEMECSS##" +
"</style></head>" +
"<body><div id='container'>";


    private static String LWECardHtmlHeader_EtoJ =
"<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />" +
"<style>" +
"body{ background-color: transparent; height:72px; display:table; margin:0px; padding:0px; text-align:center; line-height:21px; font-size:16px; font-weight:bold; font-family:Helvetica,sanserif; color:#fff; text-shadow:darkslategray 0px 1px 0px; } " +
"dfn{ text-shadow:none; font-weight:normal; color:#000; position:relative; top:-1px; font-family:verdana; font-size:10.5px; background-color:#C79810; line-height:10.5px; margin:4px 4px 0px 0px; height:14px; padding:2px 3px; -webkit-border-radius:4px; border:1px solid #F9F7ED; display:inline-block;} " + 
"#container{width:300px; display:table-cell; vertical-align:middle;text-align:center;font-size:32px; padding-left:3px; line-height:32px;} " + 
"ol{color:white; text-align:left; width:240px; margin:0px; margin-left:24px; padding-left:10px;} " +
"li{color:white; text-shadow:darkslategray 0px 1px 0px; margin:0px; margin-bottom:7px; line-height:17px;} " +
"##THEMECSS##" +
"</style></head>" +
"<body><div id='container'>";

    private static String LWECardHtmlFooter = "</div></body></html>";

    // click listener for answer bar buttons in practice mode
    private static View.OnClickListener practiceClickListener = new View.OnClickListener()
    {
        @Override
        public void onClick(View v)
        {
            PracticeFragment.practiceClick(v);
        }
    };

    // click listener for answer bar buttons in browse mode
    private static View.OnClickListener browseClickListener = new View.OnClickListener()
    {
        @Override
        public void onClick(View v)
        {
            PracticeFragment.browseClick(v);
        }
    };

}  // end PracticeScreen class declaration




