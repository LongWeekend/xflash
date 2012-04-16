package com.longweekendmobile.android.xflash;

//  AddCardToTagFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/19/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void loadCard(int  )
//  public static void dumpObservers()
//
//  private void toggleWord(View  )
//  private void addTag()
//  private void refreshTagList()
//  private void setupObservers()
//  private void updateFromNewTagObserver(Object  )

import java.util.ArrayList;
import java.util.Observable;
import java.util.Observer;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.GroupPeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class AddCardToTagFragment extends Fragment
{
    private static final String MYTAG = "XFlash AddCardToTagFragment";
    
    private static int incomingCardId; 
    private static JapaneseCard EScard = null;
    private static JapaneseCard tagCard = null;
    private static JapaneseCard searchCard = null;
    private static JapaneseCard currentCard = null;

    private LinearLayout userTagList = null;
    private static Observer newTagObserver = null;
    

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        setupObservers();

        // inflate our layout for the add-card fragment
        LinearLayout addCardLayout = (LinearLayout)inflater.inflate(R.layout.add_card, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)addCardLayout.findViewById(R.id.addcard_heading);
        ImageButton addTagButton = (ImageButton)addCardLayout.findViewById(R.id.addcard_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,addTagButton); 

        // set a click listener for the add Tag button
        addTagButton.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                addTag();
            }
        });

        // set the currentCard according to which tab we're on
        String currentTabName = Xflash.getCurrentTabName();
            
        if( currentTabName == "practice" )
        {
            currentCard = EScard;
        }
        else if( currentTabName == "tag" )
        {
            currentCard = tagCard;
        }
        else if( currentTabName == "search" )
        {
            currentCard = searchCard;
        }

        // set the word block
        TextView tempView = (TextView)addCardLayout.findViewById(R.id.addcard_word);
        tempView.setText( currentCard.getHeadword() );

        // set the reading block
        String tempString;
        if( XFApplication.IS_JFLASH )
        {
            tempString = currentCard.reading();
        }
        else
        {
            // for when we implement CFLASH
        }
        
        // set the meaning text for the card
        tempView = (TextView)addCardLayout.findViewById(R.id.addcard_reading);
        tempView.setText("[" + tempString + "]");

        tempView = (TextView)addCardLayout.findViewById(R.id.addcard_meaning);
        tempView.setText( currentCard.meaningWithoutMarkup() );

        // pull and display any user tags containing currentCard
        userTagList = (LinearLayout)addCardLayout.findViewById(R.id.addcard_usertags_list);
        refreshTagList();

        // pull and display any system tags containing currentCard
        LinearLayout tempList = (LinearLayout)addCardLayout.findViewById(R.id.addcard_systags_list);
        ArrayList<Tag> sysTagArray = TagPeer.retrieveSysTagListContainingCard(currentCard);
        
        int rowCount = sysTagArray.size();
        for(int i = 0; i < rowCount; i++)
        {
            Tag tempTag = sysTagArray.get(i);

            RelativeLayout tempRow = (RelativeLayout)inflater.inflate(R.layout.addcard_row,null);
            tempRow.setClickable(false);

            // set the tag title
            tempView = (TextView)tempRow.findViewById(R.id.addcard_row_tagname);
            tempView.setText( tempTag.getName() );

            // clear the check, as these cannot be modified
            ImageView tempImage = (ImageView)tempRow.findViewById(R.id.addcard_row_checked);
            tempImage.setVisibility(View.GONE);

            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                tempList.addView(divider);
            }
            
            tempList.addView(tempRow);

        }  // end for loop

        return addCardLayout;

    }  // end onCreateView()

    
    // called by various other fragments to initialize before opening
    public static void loadCard(int inId)
    {
        incomingCardId = inId;
        
        String currentTabName = Xflash.getCurrentTabName();
        
        if( currentTabName == "practice" )
        {
            EScard = (JapaneseCard)CardPeer.retrieveCardByPK(incomingCardId);
        }
        else if( currentTabName == "tag" )
        {
            tagCard = (JapaneseCard)CardPeer.retrieveCardByPK(incomingCardId);
        }
        else if( currentTabName == "search" )
        {
            searchCard = (JapaneseCard)CardPeer.retrieveCardByPK(incomingCardId);
        }
        else
        {
            throw new RuntimeException("AddCardToTagFragment.loadCard passed bad value: " + 
                                            Integer.toString(inId) );
        }

    }  // end loadCard()
   
    
    public static void dumpObservers()
    {
        newTagObserver = null;
    }


    // method to subscribe/unsubscrible cards in user tags
    private void toggleWord(View v)
    {
        // pull the layout row that was clicked on
        RelativeLayout tempRow = (RelativeLayout)userTagList.findViewWithTag( v.getTag() );

        // pull the tag that was clicked on
        Tag tempTag = (Tag)v.getTag();

        ImageView tempImage = (ImageView)tempRow.findViewById(R.id.addcard_row_checked);
        
        if( TagPeer.cardIsMemberOfTag(currentCard,tempTag) )
        {
            // if the card is already subscribed, remove it
            if( TagPeer.cancelMembership(currentCard,tempTag) )
            {
                // only adjust view if remove is successful
                tempImage.setVisibility(View.GONE);
            }
        }
        else
        {
            // if the card is NOT subscribed, add it
            TagPeer.subscribeCard(currentCard,tempTag);
            tempImage.setVisibility(View.VISIBLE);
        }
       
    }  // end toggleWord()

 
    // launch CreateTagActivity
    private void addTag()
    {
        // start the 'add tag' activity as a modal
        Intent myIntent = new Intent( Xflash.getActivity(), CreateTagActivity.class);
        myIntent.putExtra("card_id", currentCard.getCardId() );
        myIntent.putExtra("group_id", GroupPeer.topLevelGroup().getGroupId() );
 
        Xflash.getActivity().startActivity(myIntent);
    
    }  // end addTag()
   

    // redraws the list of user tags
    private void refreshTagList()
    {
        LayoutInflater inflater = (LayoutInflater)Xflash.getActivity().getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        // clear all views on reload
        userTagList.removeAllViews();

        // get a fresh user tag list and display
        ArrayList<Tag> userTagArray = TagPeer.retrieveUserTagList();
       
        int rowCount = userTagArray.size();

        Log.d(MYTAG,">   rowCount: " + rowCount);

        for(int i = 0; i < rowCount; i++)
        {
            Tag tempTag = userTagArray.get(i);

            // get a view for each row, tag it with the Tag it represents
            RelativeLayout tempRow = (RelativeLayout)inflater.inflate(R.layout.addcard_row,null);
            tempRow.setTag(tempTag);

            // set the tag title
            TextView tempView = (TextView)tempRow.findViewById(R.id.addcard_row_tagname);
            tempView.setText( tempTag.getName() );

            // set the visibility for our check
            ImageView tempImage = (ImageView)tempRow.findViewById(R.id.addcard_row_checked);
            if( TagPeer.cardIsMemberOfTag(currentCard,tempTag) )
            {
                tempImage.setVisibility(View.VISIBLE);
            }
            else
            {
                tempImage.setVisibility(View.GONE);
            }

            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                userTagList.addView(divider);
            }
            
            // add a click listener to each row
            tempRow.setOnClickListener( new View.OnClickListener()
            {
                @Override
                public void onClick(View v)
                {
                    toggleWord(v);
                }
            });
            
            userTagList.addView(tempRow);

        }  // end for loop

    }  // end refreshTagList()


    // method to set all relevant Observers
    private void setupObservers()
    {
        if( newTagObserver == null )
        {
            // create and define behavior for newTagObserver
            newTagObserver = new Observer()
            {
                public void update(Observable obj,Object arg)
                {
                    // if we were passed data with our notification
                    if( arg != null )
                    {
                        updateFromNewTagObserver(arg);
                    } 

                }  // end update()
            };

            XFApplication.getNotifier().addNewTagObserver(newTagObserver);
        
        }  // end if( newTagObserver == null )

        // a subscriptionObserver is not necessary for this fragment, as we do not
        // have a local cache for check marks and the view is redrawn on attachment
        
    }  // end setupObservers()
    

    // TODO - BUG update:
    //      - it works the first time the fragment is launched, in any
    //      - location, and works as many times as CreateTagActivity is called.
    //      - however, after user navigates away from AddCardToTagFragment
    //      - and then back to it (again, in any location) the view of user
    //      - tags now longer updates.
    //      -
    //      - we know for certain:  the fragment IS receiving the notification
    //      - and the refreshTagList() code IS executing.  We also know
    //      - the data has updated correctly:  refreshTagList() iterates
    //      - for an appropriate number of rows and DOES HAVE ACCESS to the
    //      - new tag that was just added
    //      -
    //      - However, for some reason yet to be determined, the view itself is
    //      - not refreshing.  (if the whole fragment is forced to refresh, then
    //      - the added data is visible)
    //  
    //      - what the crap.

    private void updateFromNewTagObserver(Object passedObject)
    {
        // get the Tag that was just added
        Tag theNewTag = (Tag)passedObject;
                        
        // only refresh if new tag was added to top level group
        if( theNewTag.groupId() == 0 )
        {
            int tempInt = XFApplication.getNotifier().getCardIdPassed();

            // if a card was passesd, that means the Tag was added
            // from a visible AddCardToTagFragment, update view
            if( tempInt != XflashNotification.NO_CARD_PASSED )
            {
                Card tempCard = CardPeer.retrieveCardByPK(tempInt);
                TagPeer.subscribeCard(tempCard,theNewTag);
                                
                refreshTagList();
            }
        }

    }  // end updateFromNewTagObserver()


}  // end AddCardToTagFragment class declaration





