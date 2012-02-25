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
//  public static void refreshTagList()

import java.util.ArrayList;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
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
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class AddCardToTagFragment extends Fragment
{
    private static final String MYTAG = "XFlash AddCardToTagFragment";
   
    private static FragmentActivity myContext = null;
    
    private static int incomingCardId; 
    private static Card currentCard = null;
    private static LinearLayout userTagList = null;


    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        myContext = getActivity();

        // inflate our layout for the HelpPage fragment
        LinearLayout addCardLayout = (LinearLayout)inflater.inflate(R.layout.add_card, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)addCardLayout.findViewById(R.id.addcard_heading);
        ImageButton tempButton = (ImageButton)addCardLayout.findViewById(R.id.addcard_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,tempButton); 

        // only call from the database if our card has changed
        if( ( currentCard == null ) || ( currentCard.getCardId() != incomingCardId ) )
        {
            currentCard = CardPeer.retrieveCardByPK(incomingCardId);
        }
        
        // set the word block
        TextView tempView = (TextView)addCardLayout.findViewById(R.id.addcard_word);
        tempView.setText( currentCard.getHeadword() );

        tempView = (TextView)addCardLayout.findViewById(R.id.addcard_reading);
        tempView.setText( currentCard.getReading() );

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
            tempRow.setTag( tempTag.getId() );

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


    public static void setIncomingCardId(int inId)
    {
        incomingCardId = inId;
    }
   
    
    // method to subscribe/unsubscrible cards in user tags
    public static void toggleWord(View v)
    {
        // pull the layout row that was clicked on
        RelativeLayout tempRow = (RelativeLayout)userTagList.findViewWithTag( v.getTag() );

        // pull the tag that was clicked on
        int tempInt = (Integer)v.getTag();
        Tag tempTag = TagPeer.retrieveTagById(tempInt);

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
        CreateTagActivity.setWhoIsCalling(CreateTagActivity.SINGLE_CARD_CALLING);
        CreateTagActivity.setCurrentGroup( GroupPeer.topLevelGroup() );

        // tag the Intent with the id of the card we are calling from
        Intent myIntent = new Intent(inContext,CreateTagActivity.class);
        myIntent.putExtra("card_id", currentCard.getCardId() );
 
        inContext.startActivity(myIntent);
    }

    
    public static void refreshTagList()
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
            tempRow.setTag( tempTag.getId() );

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


}  // end AddCardToTagFragment class declaration





