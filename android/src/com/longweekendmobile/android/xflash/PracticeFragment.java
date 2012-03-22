package com.longweekendmobile.android.xflash;

//  PracticeFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//  public void onDestroyView()                                         @over
//  public void onCreateOptionsMenu(Menu  ,MenuInflater  )              @over
//  public void onPrepareOptionsMenu(Menu  )                            @over
//  public boolean onOptionsItemSelected(MenuItem  )                    @over
//
//  public static void setPracticeBlank()
//
//  private static void reveal()
//  private static void toggleReading()
//  private static void practiceClick(View  )
//  private static void browseClick(View  )
//  private static void launchBrowseCard(int  )
//  private static void goRight()
//
//  private void toggleCardStarred()
//  private void launchAddCard()
//  private void fixCardEmail()
//  private void setupObservers()
//  private void updateFromSubscriptionObserver()
//
//  private static class PracticeScreen
//
//      public  static void initialize()
//      public  static void dump()
//      public  static void refreshCountBar()
//      public  static void setupPracticeView(int  )
//      public  static void setAnswerBar(int  )
//      public  static void toggleReading()
//      private static void loadMeaning()
//      private static void setClickListeners()

import java.util.Observable;
import java.util.Observer;

import android.content.Intent;
import android.content.res.Resources;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.ExampleSentencePeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.LWEDatabase;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;
import com.longweekendmobile.android.xflash.model.UserHistoryPeer;

public class PracticeFragment extends Fragment
{
    private static final String MYTAG = "XFlash PracticeFragment";
    
    public static final int PRACTICE_VIEW_BLANK = 0;
    public static final int PRACTICE_VIEW_BROWSE = 1;
    public static final int PRACTICE_VIEW_REVEAL = 2;

    public static final int STUDYING_INDEX = 0;
    public static final int RIGHT1_INDEX = 1;
    public static final int RIGHT2_INDEX = 2;
    public static final int RIGHT3_INDEX = 3;
    public static final int LEARNED_INDEX = 4;
    
    private static Observer subscriptionObserver = null;
    
    private static int[] cardCounts = { 1, 2, 3, 4, 5 };
    
    private static int percentageRight = 100;
    private static int rightStreak = 0;
    private static int wrongStreak = 0;
    private static int numRight = 0;
    private static int numWrong = 0;
    private static int numViewed = 0;
    
    private static int practiceViewStatus = -1;

    private static RelativeLayout practiceLayout;

    private static Tag currentTag = null;
    private static JapaneseCard currentCard = null;

    
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // allow this fragment to open the options menu via hardware button
        setHasOptionsMenu(true);

        setupObservers();
       
        // inflate the layout for our practice activity
        practiceLayout = (RelativeLayout)inflater.inflate(R.layout.practice, container, false);

        // TODO - we always need to load currentCard, but not currentTag
        //
        //      - I could make a new broadcast and listener so PracticeFragment
        //      - only loads a new Tag when someone calls XflashAlert.startStudying(),
        //      - but I feel that would more than cancel any optimization gained
        //      - by not making this call
        
        // if there is no tag loaded, default to Long Weekend Favorites
        currentTag = XflashSettings.getActiveTag();           
        currentCard = (JapaneseCard)XflashSettings.getActiveCard();
        
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

   
    @Override
    public void onDestroyView()
    {
        super.onDestroyView();

        // free static layout resources
        // TODO - temporary fix, would be preferable to refactor 
        //      - PracticeScreen to use no static layout varables
        practiceLayout = null;
        PracticeScreen.dump();

    }  // end onDestroyView()


    @Override
    public void onCreateOptionsMenu(Menu menu,MenuInflater inflater) 
    {
        // inflate our options menu from xml
        inflater.inflate(R.menu.practice_options, menu);
    }


    @Override
    public void onPrepareOptionsMenu(Menu menu)
    {
        // set the starred menu item based on current card status
        MenuItem starredItem = (MenuItem)menu.findItem(R.id.pm_toggle_starred);
        Tag starredTag = TagPeer.starredWordsTag();

        if( TagPeer.card(currentCard,starredTag) )
        {
            starredItem.setTitle(R.string.pm_starred_yes);
        }
        else
        {
            starredItem.setTitle(R.string.pm_starred_no);
        }
    
    }  // end onPrepareOptionsMenu()
  

    @Override
    public boolean onOptionsItemSelected(MenuItem item) 
    {
        switch( item.getItemId() ) 
        {
            case R.id.pm_toggle_starred:    toggleCardStarred();
                                            return true;
            case R.id.pm_add_tag:           launchAddCard();
                                            return true;
            case R.id.pm_tweet:             Log.d(MYTAG,"> pm_tweet clicked");
                                            Log.d(MYTAG,".");
                                            return true;
            case R.id.pm_fix:               fixCardEmail();
                                            return true;

        }  // end switch
        
        // if the item clicked does not match our items, pass it up
        return( super.onOptionsItemSelected(item) );

    }  // end onOptionsItemSelected()


    // called by ExampleSentenceFragment to reset the view
    public static void setPracticeBlank()
    {
        practiceViewStatus = PRACTICE_VIEW_BLANK;
    }


    // called by Xflash when someone clicks 'tap for answer'
    private static void reveal()
    {
        PracticeScreen.setupPracticeView(PRACTICE_VIEW_REVEAL);
    }

    
    // method called when any button in the options block is clicked
    private static void practiceClick(View v)
    {
        switch( v.getId() )
        {
            case R.id.optionblock_right:    ++numRight;
                                            ++numViewed;
                                            ++rightStreak;
                                            wrongStreak = 0;
                                            UserHistoryPeer.recordCorrectForCard(currentCard,currentTag);
                                            break;
            
            case R.id.optionblock_wrong:    ++numWrong;
                                            ++numViewed;
                                            ++wrongStreak;
                                            rightStreak = 0;
                                            UserHistoryPeer.recordWrongForCard(currentCard,currentTag);
                                            break;

            case R.id.optionblock_goaway:   ++numRight;
                                            ++numViewed;
                                            ++rightStreak;
                                            wrongStreak = 0;
                                            UserHistoryPeer.buryCard(currentCard,currentTag);
                                            break;

            default:    Log.d(MYTAG,"ERROR - practiceClick() passed invalied button id");
        
        }  // end switch( practice button )

        // load the next practice view without adding to the back stack
        practiceViewStatus = PRACTICE_VIEW_BLANK;
        PracticeCardSelector.setNextPracticeCard(currentTag,currentCard);
        
        XflashScreen.setPracticeOverride();
        Xflash.getActivity().onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);

    }  // end practiceClick()


    // method called when any button in the options block is clicked
    private static void browseClick(View v)
    {
        switch( v.getId() )
        {
            case R.id.browseblock_last:     launchBrowseCard(XflashScreen.DIRECTION_CLOSE);
                                            break;
            
            case R.id.browseblock_next:     launchBrowseCard(XflashScreen.DIRECTION_OPEN);
                                            break;
        } 

    }  // end browseClick()

    
    // set the card and screen transition for a browse click
    private static void launchBrowseCard(int inDirection)
    {
        PracticeCardSelector.setNextBrowseCard(currentTag,inDirection);
        Xflash.getActivity().onScreenTransition("practice",inDirection);
    } 


    // method called when user click to queue the extra screen
    private static void goRight()
    {
        // load the ExampleSentenceFragment to the fragment tab manager
        ExampleSentenceFragment.loadCard(currentCard,cardCounts);
        Xflash.getActivity().onScreenTransition("example_sentence",XflashScreen.DIRECTION_OPEN);
    }


    // toggles a card's starred status from the options menu
    private void toggleCardStarred()
    {
        Tag starredTag = TagPeer.starredWordsTag();

        if( TagPeer.card(currentCard,starredTag) )
        {
            TagPeer.cancelMembership(currentCard,starredTag);
        }
        else
        {
            TagPeer.subscribeCard(currentCard,starredTag);
        }

    }  // end toggleCarddStarred()

    
    // launches a model AddCardActivty from the options menu
    private void launchAddCard()
    {
        // load the card to AddCardToTagFragment, as it is the layout
        // and functionality for AddCardActivity
        AddCardToTagFragment.loadCard( currentCard.getCardId() );

        Xflash myContext = Xflash.getActivity();

        // launch the Activity - modal
        Intent myIntent = new Intent(myContext,AddCardActivity.class);
        myContext.startActivity(myIntent);

    }  // end launchAddCard()
    
   
    // creates an email to notify Long Weekend about an error and 
    // launches it as a send-email intent
    private void fixCardEmail()
    {
        Resources res = Xflash.getActivity().getResources();
        
        Intent myIntent  = new Intent(Intent.ACTION_SEND);

        // set the email target
        myIntent.putExtra(android.content.Intent.EXTRA_EMAIL, new String[]{ "fix-card@longweekendmobile.com" });
        
        // set the email subject 
        String emailSubject = res.getString(R.string.fixcard_subject);
        myIntent.putExtra(android.content.Intent.EXTRA_SUBJECT,emailSubject);
        
        // set the email body - this is hard to read
        String emailBody = res.getString(R.string.fixcard_bodytop) 
                              + "  " + currentCard.getCardId() + "\n";
        emailBody = emailBody + res.getString(R.string.fixcard_bodyheadword) 
                              + "  " + currentCard.getJustHeadword() + "\n";
        emailBody = emailBody + res.getString(R.string.fixcard_bodymeaning) 
                              + "  " + currentCard.meaningWithoutMarkup() + "\n";
        emailBody = emailBody + res.getString(R.string.fixcard_bodytagid) 
                              + "  " + currentTag.getId() + "\n";
        emailBody = emailBody + res.getString(R.string.fixcard_bodytagname) 
                              + "  " + currentTag.getName() + "\n\n";

        myIntent.putExtra(android.content.Intent.EXTRA_TEXT,emailBody);

        // I believe this is the current email MIME?
        myIntent.setType("message/rfc5322");

        Xflash.getActivity().startActivity(myIntent);

    }  // end fixCardEmail()
    
   
    private void setupObservers()
    {
        XflashNotification theNotifier = XFApplication.getNotifier();

        if( subscriptionObserver == null )
        {
            // create and define behavior for newTagObserver
            subscriptionObserver = new Observer()
            {
                public void update(Observable obj,Object arg)
                {
                    updateFromSubscriptionObserver(arg);
                }
            };

            theNotifier.addSubscriptionObserver(subscriptionObserver);

        }  // end if( subscriptionObserver == null )

    }  // end setupObservers()


    private void updateFromSubscriptionObserver(Object passedObject)
    {
        XflashNotification theNotifier = XFApplication.getNotifier();
        
        // only concern ourselves if the active tag changed
        if( currentTag.getId() == theNotifier.getTagIdPassed() )
        {
            JapaneseCard theCard = (JapaneseCard)passedObject;
            theCard.hydrate();

            if( theNotifier.getCardWasAdded() )
            {
                currentTag.addCardToActiveSet(theCard);
            }
            else
            {
                // if the card was removed from the active set
                currentTag.removeCardFromActiveSet(theCard);

                // if they are removing the card we're actually showing,
                // get a new card
                if( currentCard.equals(theCard) )
                {
                    PracticeCardSelector.setNextPracticeCard(currentTag,currentCard);
                    
                    // if we're actually on the practice tab right now, force
                    // reload of new card
                    if( practiceLayout != null )
                    {
                        practiceViewStatus = PRACTICE_VIEW_BLANK;
        
                        XflashScreen.setPracticeOverride();
                        Xflash.getActivity().onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);
                    }
                }
            } 

        }  // end if( card mod to active set ) 

    }  // end updateFromSubscriptionObserver()


    
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
        private static RelativeLayout practiceBack = null;
        private static RelativeLayout practiceScrollBack = null;
        private static TextView headwordView = null;
        private static TextView hhView = null;
        private static TextView showReadingText = null;

        public static void initialize()
        {
            // load the title bar and background elements and pass them to the color manager
            practiceBack = (RelativeLayout)PracticeFragment.practiceLayout.findViewById(R.id.practice_mainlayout);
            XflashSettings.setupPracticeBack(practiceBack);

            practiceScrollBack = (RelativeLayout)PracticeFragment.practiceLayout.findViewById(R.id.practice_scroll_back);
        
            // load the progress count bar
            countBar = (LinearLayout)practiceLayout.findViewById(R.id.count_bar);
           
            // load the show-reading button
            showReadingButton = (ImageButton)PracticeFragment.practiceLayout.findViewById(R.id.practice_showreadingbutton);
            
            // load the show-reading text
            showReadingText = (TextView)PracticeFragment.practiceLayout.findViewById(R.id.practice_readingtext);
            showReadingText.setText( currentCard.reading() );
            
            // load the headword view - variable based on study language in Card.java
            headwordView = (TextView)PracticeFragment.practiceLayout.findViewById(R.id.practice_headword);
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
            tempPracticeInfo.setText( PracticeFragment.currentTag.getName() );

            // load the tag card count
            String tempString = null;
            if( practiceViewStatus != PRACTICE_VIEW_BROWSE )
            {
                tempString = Integer.toString( ( currentTag.getCardCount() - 
                                                 currentTag.getSeenCardCount() ) );
            }
            else
            {
                tempString = Integer.toString( PracticeFragment.currentTag.getCurrentIndex() + 1 );
            }

            tempString = tempString + " / ";
            tempString = tempString + Integer.toString( PracticeFragment.currentTag.getCardCount() );

            tempPracticeInfo = (TextView)practiceLayout.findViewById(R.id.practice_tag_count);
            tempPracticeInfo.setText(tempString);

            // set all of our click listeners
            PracticeScreen.setClickListeners();
            
        }  // end PracticeScreen.initialize()
       
        
        // dumps all static variables dealing with layout
        public static void dump()
        {
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
            }

        }  // end refreshCountBar()


        // set all widgets to the card-hidden state
        public static void setupPracticeView(int inViewMode)
        {
            if( inViewMode == PRACTICE_VIEW_BLANK )
            {
                // set up for blank view
                hhImage.setVisibility(View.VISIBLE);
                hhBubble.setVisibility(View.VISIBLE);
                hhView.setText( Integer.toString( PracticeFragment.percentageRight ) + "%" );
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
                hhView.setText( Integer.toString( PracticeFragment.percentageRight ) + "%" );
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

            practiceViewStatus = inViewMode;
            setAnswerBar(practiceViewStatus);
            refreshCountBar();
        
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


        // set click listeners for all relevant views
        private static void setClickListeners()
        {
            // listener for the 'tap for answer' answer bar
            blankButton.setOnClickListener( new View.OnClickListener()
            {
                @Override
                public void onClick(View v)
                {
                    reveal();
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
                    reveal();
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
                    goRight();
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
                practiceClick(v);
            }
        };

        // click listener for answer bar buttons in browse mode
        private static View.OnClickListener browseClickListener = new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                browseClick(v);
            }
        };

    }  // end PracticeScreen class declaration


}  // end PracticeFragment class declaration





