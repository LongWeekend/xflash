package com.longweekendmobile.android.xflash;

//  SingleCardFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/19/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import java.util.ArrayList;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.util.Log;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.GroupPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class SingleCardFragment extends Fragment
{
    private static final String MYTAG = "XFlash SingleCardFragment";
   
    private static int incomingCardId; 
    private static Card currentCard = null;

    private static LinearLayout userTagList = null;

    
    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        LinearLayout singleCardLayout = (LinearLayout)inflater.inflate(R.layout.single_card, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)singleCardLayout.findViewById(R.id.singlecard_heading);
        ImageButton tempButton = (ImageButton)singleCardLayout.findViewById(R.id.singlecard_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,tempButton); 

        currentCard = CardPeer.retrieveCardByPK(incomingCardId);

        // set the word block
        TextView tempView = (TextView)singleCardLayout.findViewById(R.id.singlecard_word);
        tempView.setText( currentCard.getHeadword() );

        tempView = (TextView)singleCardLayout.findViewById(R.id.singlecard_reading);
        tempView.setText( currentCard.getReading() );

        tempView = (TextView)singleCardLayout.findViewById(R.id.singlecard_meaning);
        tempView.setText( currentCard.meaningWithoutMarkup() );

        // pull and display any user tags containing currentCard
        userTagList = (LinearLayout)singleCardLayout.findViewById(R.id.singlecard_usertags_list);
        ArrayList<Tag> tagArray = TagPeer.retrieveUserTagList();
        int rowCount = tagArray.size();

        for(int i = 0; i < rowCount; i++)
        {
            Tag tempTag = tagArray.get(i);

            RelativeLayout tempRow = (RelativeLayout)inflater.inflate(R.layout.singlecard_row,null);
            tempRow.setTag( tempTag.getId() );

            // set the tag title
            tempView = (TextView)tempRow.findViewById(R.id.singlecard_row_tagname);
            tempView.setText( tempTag.getName() );

            // set the visibility for our check
            ImageView tempImage = (ImageView)tempRow.findViewById(R.id.singlecard_row_checked);
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


        // pull and display any system tags containing currentCard
        LinearLayout tempList = (LinearLayout)singleCardLayout.findViewById(R.id.singlecard_systags_list);
        tagArray = TagPeer.retrieveSysTagListContainingCard(currentCard);
        rowCount = tagArray.size();

        for(int i = 0; i < rowCount; i++)
        {
            Tag tempTag = tagArray.get(i);

            RelativeLayout tempRow = (RelativeLayout)inflater.inflate(R.layout.singlecard_row,null);
            tempRow.setClickable(false);
            tempRow.setTag( tempTag.getId() );

            // set the tag title
            tempView = (TextView)tempRow.findViewById(R.id.singlecard_row_tagname);
            tempView.setText( tempTag.getName() );

            // clear the check, as these cannot be modified
            ImageView tempImage = (ImageView)tempRow.findViewById(R.id.singlecard_row_checked);
            tempImage.setVisibility(View.GONE);

            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                tempList.addView(divider);
            }
            tempList.addView(tempRow);

        }  // end for loop



        return singleCardLayout;

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

        ImageView tempImage = (ImageView)tempRow.findViewById(R.id.singlecard_row_checked);
        
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
       
        // inform the study set words fragment that it may have been changed
        StudySetWordsFragment.setNeedLoad();
 
    }  // end toggleWord()

 
    public static void addTag(Xflash inContext)
    {
        // start the 'add tag' activity as a modal
        CreateTagActivity.setCurrentGroup( GroupPeer.topLevelGroup() );

        inContext.startActivity(new Intent(inContext,CreateTagActivity.class));
    }


}  // end SingleCardFragment class declaration





