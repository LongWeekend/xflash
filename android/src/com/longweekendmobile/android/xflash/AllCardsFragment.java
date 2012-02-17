package com.longweekendmobile.android.xflash;

//  AllCardsFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import java.util.List;
import java.util.ArrayList;

import android.graphics.PorterDuff;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.RadioGroup;
import android.widget.RadioGroup.OnCheckedChangeListener;
import android.widget.RelativeLayout;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;
import android.widget.TextView;
import android.util.Log;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class AllCardsFragment extends Fragment
{
    private static final String MYTAG = "XFlash AllCardsFragment";
   
    // properties for handling color theme transitions
    private static LinearLayout allCardsLayout;

    private static int incomingTagId;
    private Tag currentTag = null;

    private LayoutInflater myInflater;
    private ArrayList<Card> cardArray;
 
    
    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the AllCardsPage fragment
        allCardsLayout = (LinearLayout)inflater.inflate(R.layout.all_cards, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)allCardsLayout.findViewById(R.id.allcards_heading);
        
        XflashSettings.setupColorScheme(titleBar); 

        // get the tag we're working with
        currentTag = TagPeer.retrieveTagById(incomingTagId);

        // set the title bar to the tag name we're looking at
        TextView tempView = (TextView)allCardsLayout.findViewById(R.id.allcards_heading_text);
        tempView.setText( currentTag.getName() );

        // TODO - android book page 159
        
        // get the header, tag it with the id of the current Tag, and add it to the ListView
        ListView cardList = (ListView)allCardsLayout.findViewById(R.id.allcards_list);
        RelativeLayout header = (RelativeLayout)inflater.inflate(R.layout.allcards_header,cardList,false);
        header.setTag( currentTag.getId() );
        cardList.addHeaderView(header);
        
        // get all of our cards for the current tag and hydrate
        cardArray = CardPeer.retrieveFaultedCardsForTag(currentTag);
        
        int tempInt = cardArray.size();
        for(int i = 0; i < tempInt; i++)
        {
            cardArray.get(i).hydrate();
        }
 
        // set our card info into the ListView
        CardAdapter theAdapter = new CardAdapter();
        cardList.setAdapter(theAdapter);

        // save the inflater for use in CardAdapter
        myInflater = inflater;
        
        return allCardsLayout;

    }  // end onCreateView

    
    public static void setIncomingTagId(int inId)
    {
        incomingTagId = inId;
    }

    public static void startStudying(View v,Xflash inContext)
    {
        Log.d(MYTAG,">>> start studying clicked for Tag: " + (Integer)v.getTag() );
    }

    public static void singleCard(View v,Xflash inContext)
    {
        Log.d(MYTAG,">>> single card clicked for Card: " + (Integer)v.getTag() );
    }

    class CardAdapter extends ArrayAdapter<Card> 
    {
        CardAdapter() 
        {
            super( getActivity(), R.layout.allcards_row, (List)cardArray);
        }
        
        public View getView(int position, View convertView, ViewGroup parent) 
        {
            View row = convertView;
            
            if( row == null ) 
            {
                row = myInflater.inflate(R.layout.allcards_row, parent, false);
            }
            
            Card tempCard = cardArray.get(position);

            // set the word
            TextView tempView = (TextView)row.findViewById(R.id.allcards_word);
            tempView.setText( tempCard.getHeadword() );

            // set the meaning
            tempView = (TextView)row.findViewById(R.id.allcards_meaning);
            tempView.setText( tempCard.meaningWithoutMarkup() );
           
            // tag each row with the card id it represents
            row.setTag( tempCard.getCardId() );
 
            return row;
        }

    }  // end CardAdapter class declaration

  
}  // end AllCardsFragment class declaration





