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
//  public static void setRight()
//  public static void setWrong()
//  public static void setGoAway()
//  public static void reveal()
//  public static void practiceClick(View  )
//  public static void browseClick(View  )
//  public static void goRight()
//
//  private static void launchBrowseCard(int  )
//
//  private void toggleCardStarred()
//  private void launchAddCard()
//  private void fixCardEmail()
//  private void setupObservers()
//  private void updateFromSubscriptionObserver(Object  )
//  private void updateFromActiveTagObserver()

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
import android.widget.RelativeLayout;

import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;
import com.longweekendmobile.android.xflash.model.UserHistoryPeer;

public class PracticeFragment extends Fragment
{
    private static final String MYTAG = "XFlash PracticeFragment";
    
    public static final int STUDYING_INDEX = 0;
    public static final int RIGHT1_INDEX = 1;
    public static final int RIGHT2_INDEX = 2;
    public static final int RIGHT3_INDEX = 3;
    public static final int LEARNED_INDEX = 4;
    
    private static Observer subscriptionObserver = null;
    private static Observer activeTagObserver = null;
    
    // made public for access in PracticeScreen
    public static int rightStreak = 0;
    public static int wrongStreak = 0;
    public static int numRight = 0;
    public static int numWrong = 0;
    public static int numViewed = 0;
    
    public static int practiceViewStatus = -1;

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

        // if there is no tag loaded, default to Long Weekend Favorites
        currentTag = XflashSettings.getActiveTag();           
        currentCard = (JapaneseCard)XflashSettings.getActiveCard();
        
        // set up view based on current study mode
        if( XflashSettings.getStudyMode() == XflashSettings.LWE_STUDYMODE_PRACTICE )    
        {
            // if we're not revealed, reset to blank (in case of mode change)
            if( practiceViewStatus != PracticeScreen.PRACTICE_VIEW_REVEAL )
            {
                practiceViewStatus = PracticeScreen.PRACTICE_VIEW_BLANK;
            }
        }
        else  
        {
            practiceViewStatus = PracticeScreen.PRACTICE_VIEW_BROWSE;
        } 
    
        // load all view elements and set up based on view status
        PracticeScreen.initialize(practiceLayout,currentTag,currentCard);
        PracticeScreen.setupPracticeView(practiceViewStatus);

        if( currentTag.needShowAllLearned() )
        {
            XflashAlert.fireTagLearned(currentTag);
        }

        // display dialog on first-run or update
        XflashSettings.updateCheck();
        //                   ^^^^ 
        // TODO - can we put this in Xflash so it isn't called every damn
        //      - time we load a new Card?  ( Fragments! Grar. )
        //      -
        //      - amusingly, this rampant detach/attach every time we swap to
        //      - a new card (and all associated heavy system/battery demands 
        //      - for view chnstruction/garbage collection) is wholly unnecessary 
        //      - for the core functionality of the app; the only purpose it
        //      - serves is to emulate the iPhone-esque animated transitions 
        //      - inside a tab. Otherwise we could just reset the views, AND
        //      - do away with the need to store activeTab/activeCard elsewhere
        
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

        if( TagPeer.cardIsMemberOfTag(currentCard,starredTag) )
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
        practiceViewStatus = PracticeScreen.PRACTICE_VIEW_BLANK;
    }


    // methods for PracticeFragment and ExampleSentence to respond
    // to user right / wrong/ goaway choices
    public static void setRight()
    {
        ++numRight;
        ++numViewed;
        ++rightStreak;
        wrongStreak = 0;
        UserHistoryPeer.recordCorrectForCard(currentCard,currentTag);

    }  // end setRight()

    public static void setWrong()
    {
        ++numWrong;
        ++numViewed;
        ++wrongStreak;
        rightStreak = 0;
        UserHistoryPeer.recordWrongForCard(currentCard,currentTag);
        
        // reset our all-learned flag
        currentTag.resetAllLearned();

    }  // end setWrong()

    public static void setGoAway()
    {
        ++numRight;
        ++numViewed;
        ++rightStreak;
        wrongStreak = 0;
        UserHistoryPeer.buryCard(currentCard,currentTag);

    }  // end setGoAway()


    // called by Xflash when someone clicks 'tap for answer'
    public static void reveal()
    {
        PracticeScreen.setupPracticeView(PracticeScreen.PRACTICE_VIEW_REVEAL);
    }

    
    // method called when any button in the options block is clicked
    public static void practiceClick(View v)
    {
        switch( v.getId() )
        {
            case R.id.optionblock_right:    setRight();
                                            break;
            
            case R.id.optionblock_wrong:    setWrong();
                                            break;

            case R.id.optionblock_goaway:   setGoAway();
                                            break;

            default:    Log.d(MYTAG,"ERROR - practiceClick() passed invalied button id");
        
        }  // end switch( practice button )

        // load the next practice view without adding to the back stack
        PracticeCardSelector.setNextPracticeCard(currentTag,currentCard);
        
        practiceViewStatus = PracticeScreen.PRACTICE_VIEW_BLANK;
        XflashScreen.setPracticeOverride();
        Xflash.getActivity().onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);

    }  // end practiceClick()

    
    // method called when any button in the options block is clicked
    public static void browseClick(View v)
    {
        switch( v.getId() )
        {
            case R.id.browseblock_last:     launchBrowseCard(XflashScreen.DIRECTION_CLOSE);
                                            break;
            
            case R.id.browseblock_next:     launchBrowseCard(XflashScreen.DIRECTION_OPEN);
                                            break;
        } 

    }  // end browseClick()

    
    // method called when user click to queue the extra screen
    public static void goRight()
    {
        // load the ExampleSentenceFragment to the fragment tab manager
        Xflash.getActivity().onScreenTransition("example_sentence",XflashScreen.DIRECTION_OPEN);
    }


    // set the card and screen transition for a browse click
    private static void launchBrowseCard(int inDirection)
    {
        PracticeCardSelector.setNextBrowseCard(currentTag,inDirection);
        Xflash.getActivity().onScreenTransition("practice",inDirection);
    } 


    // toggles a card's starred status from the options menu
    private void toggleCardStarred()
    {
        Tag starredTag = TagPeer.starredWordsTag();

        if( TagPeer.cardIsMemberOfTag(currentCard,starredTag) )
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
    
        if( activeTagObserver == null )
        {
            // create and define behavior for newTagObserver
            activeTagObserver = new Observer()
            {
                public void update(Observable obj,Object arg)
                {
                    updateFromActiveTagObserver();
                }
            };

            theNotifier.addActiveTagObserver(activeTagObserver);

        }  // end if( activeTagObserver == null )

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
                        practiceViewStatus = PracticeScreen.PRACTICE_VIEW_BLANK;
        
                        XflashScreen.setPracticeOverride();
                        Xflash.getActivity().onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);
                    }
                }
            } 

        }  // end if( card mod to active set ) 

    }  // end updateFromSubscriptionObserver()


    private void updateFromActiveTagObserver()
    {
        // when a new tag is set to active, reset all relevant values
        rightStreak = 0;
        wrongStreak = 0;
        numRight = 0;
        numWrong = 0;
        numViewed = 0;
    
        XflashScreen.resetPracticeScreen();

    }  // end updateFromStartStudyingObserver()


}  // end PracticeFragment class declaration





