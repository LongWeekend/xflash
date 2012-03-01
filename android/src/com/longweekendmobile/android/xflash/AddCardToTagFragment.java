package com.longweekendmobile.android.xflash;

//  AddCardToTagFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/19/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void setIncomingCardId(int  )
//  public static void toggleWord(View  )
//  public static void addTag(Xflash  )
//
//  private static void refreshTagList()
//  private void setupObservers()
//  private void updateFromNewTagObserver(Object  )

import java.util.ArrayList;
import java.util.Observable;
import java.util.Observer;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
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
    // private static final String MYTAG = "XFlash AddCardToTagFragment";
    public static final int TAG_CARDS_CALLING = 0;
    public static final int SEARCH_CALLING = 1;

    private static FragmentActivity myContext = null;
    
    private static Observer newTagObserver = null;

    private static int incomingCardId; 
    private static JapaneseCard tagCard = null;
    private static JapaneseCard searchCard = null;
    private static JapaneseCard currentCard = null;
    private static LinearLayout userTagList = null;


    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        myContext = getActivity();
        setupObservers();

        // inflate our layout for the HelpPage fragment
        LinearLayout addCardLayout = (LinearLayout)inflater.inflate(R.layout.add_card, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)addCardLayout.findViewById(R.id.addcard_heading);
        ImageButton tempButton = (ImageButton)addCardLayout.findViewById(R.id.addcard_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,tempButton); 

        // set the currentCard according to which tab we're on
        String currentTabName = Xflash.getCurrentTabName();
            
        if( currentTabName == "tag" )
        {
            currentCard = tagCard;
        }
        else
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
            tempRow.setTag(tempTag);

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

    
    public static void setIncomingCardId(int inId,int calling)
    {
        incomingCardId = inId;
        
        if( calling == TAG_CARDS_CALLING )
        {
            tagCard = (JapaneseCard)CardPeer.retrieveCardByPK(incomingCardId);
        }
        else
        {
            searchCard = (JapaneseCard)CardPeer.retrieveCardByPK(incomingCardId);
        }

    }  // end setIncomingCardId()
   
    
    // method to subscribe/unsubscrible cards in user tags
    public static void toggleWord(View v)
    {
        // pull the layout row that was clicked on
        RelativeLayout tempRow = (RelativeLayout)userTagList.findViewWithTag( v.getTag() );

        // pull the tag that was clicked on
        Tag tempTag = (Tag)v.getTag();

        ImageView tempImage = (ImageView)tempRow.findViewById(R.id.addcard_row_checked);
        
        if( TagPeer.card(currentCard,tempTag) )
        {
            // if the card is already subscribed, remove it
            TagPeer.cancelMembership(currentCard,tempTag);
            tempImage.setVisibility(View.GONE);
        }
        else
        {
            // if the card is NOT subscribed, add it
            TagPeer.subscribeCard(currentCard,tempTag);
            tempImage.setVisibility(View.VISIBLE);
        }
       
    }  // end toggleWord()

 
    public static void addTag(Xflash inContext)
    {
        // start the 'add tag' activity as a modal
        Intent myIntent = new Intent(inContext,CreateTagActivity.class);
        myIntent.putExtra("card_id", currentCard.getCardId() );
        myIntent.putExtra("group_id", GroupPeer.topLevelGroup().getGroupId() );
 
        inContext.startActivity(myIntent);
    
    }  // end addTag()
   

    private static void refreshTagList()
    {
        LayoutInflater inflater = (LayoutInflater)myContext.getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        // clear all views on reload
        userTagList.removeAllViews();

        ArrayList<Tag> userTagArray = TagPeer.retrieveUserTagList();
        int rowCount = userTagArray.size();

        for(int i = 0; i < rowCount; i++)
        {
            Tag tempTag = userTagArray.get(i);

            RelativeLayout tempRow = (RelativeLayout)inflater.inflate(R.layout.addcard_row,null);
            tempRow.setTag(tempTag);

            // set the tag title
            TextView tempView = (TextView)tempRow.findViewById(R.id.addcard_row_tagname);
            tempView.setText( tempTag.getName() );

            // set the visibility for our check
            ImageView tempImage = (ImageView)tempRow.findViewById(R.id.addcard_row_checked);
            if( TagPeer.card(currentCard,tempTag) )
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
            userTagList.addView(tempRow);

        }  // end for loop

    }  // end refreshTagList()


    // method to set all relevant Observers
    // I'm uncomfortable with how nested this is
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

        }  // end if( newTagObserver == null )

        // a subscriptionObserver is not necessary for this fragment, as we do not
        // have a local cache for check marks and the view is redrawn on attachment
        
        XFApplication.getNotifier().addNewTagObserver(newTagObserver);

    }  // end setupObservers()
    

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
                                
                AddCardToTagFragment.refreshTagList();
            }
        }

    }  // end updateFromNewTagObserver()


}  // end AddCardToTagFragment class declaration





