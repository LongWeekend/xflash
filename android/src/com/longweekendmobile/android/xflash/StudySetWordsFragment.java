package com.longweekendmobile.android.xflash;

//  StudySetWordsFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import java.util.ArrayList;
import java.util.List;

import android.app.ProgressDialog;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class StudySetWordsFragment extends Fragment
{
    private static final String MYTAG = "XFlash StudySetWordsFragment";
   
    // properties for handling color theme transitions
    private LinearLayout studySetWordsLayout;
    private ListView cardList;
    private LayoutInflater myInflater;

    private static boolean needLoad = false;
    private static int incomingTagId;
    private static Tag currentTag = null;

    private static ArrayList<Card> cardArray = null;
    private static ProgressDialog cardLoadDialog = null;
 
    
    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the AllCardsPage fragment
        studySetWordsLayout = (LinearLayout)inflater.inflate(R.layout.studyset_words, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)studySetWordsLayout.findViewById(R.id.studysetwords_heading);
        
        XflashSettings.setupColorScheme(titleBar); 

        // get the tag we're working with
        currentTag = TagPeer.retrieveTagById(incomingTagId);

        // set the title bar to the tag name we're looking at
        TextView tempView = (TextView)studySetWordsLayout.findViewById(R.id.studysetwords_heading_text);
        tempView.setText( currentTag.getName() );

        // get the header, tag it with the id of the current Tag, and add it to the ListView
        cardList = (ListView)studySetWordsLayout.findViewById(R.id.studysetwords_list);
        LinearLayout header = (LinearLayout)inflater.inflate(R.layout.studysetwords_header,cardList,false);
        RelativeLayout realHeader = (RelativeLayout)header.findViewById(R.id.header_block);
        realHeader.setTag( currentTag.getId() );
        cardList.addHeaderView(header);
        
        // save the inflater for use in CardAdapter
        myInflater = inflater;
      
        // load the cards (if necessary)
        AsyncLoadcards tempLoad = new AsyncLoadcards();
        tempLoad.execute();
 
        return studySetWordsLayout;

    }  // end onCreateView

    
    public static void setNeedLoad()
    {
        needLoad = true;
    }

    public static void setIncomingTagId(int inId)
    {
        incomingTagId = inId;
        needLoad = true;
    }

    public static void startStudying(View v,Xflash inContext)
    {
        Log.d(MYTAG,">>> start studying clicked for Tag: " + (Integer)v.getTag() );
    }

    public static void singleCard(View v,Xflash inContext)
    {
        int tempInt = (Integer)v.getTag();

        SingleCardFragment.setIncomingCardId(tempInt);
        inContext.onScreenTransition("single_card",XflashScreen.DIRECTION_OPEN);
    }

    
    // custom adapter to appropriately fill the view for our ListView
    private class CardAdapter extends ArrayAdapter<Card> 
    {
        CardAdapter() 
        {
            super( getActivity(), R.layout.studysetwords_row, (List)cardArray);
        }
        
        public View getView(int position, View convertView, ViewGroup parent) 
        {
            View row = convertView;
            
            if( row == null ) 
            {
                row = myInflater.inflate(R.layout.studysetwords_row, parent, false);
            }
            
            Card tempCard = cardArray.get(position);

            if( tempCard.isFault )
            {
                tempCard.hydrate();
            }

            // set the word
            TextView tempView = (TextView)row.findViewById(R.id.studysetwords_word);
            tempView.setText( tempCard.getHeadword() );

            // set the meaning
            tempView = (TextView)row.findViewById(R.id.studysetwords_meaning);
            tempView.setText( tempCard.meaningWithoutMarkup() );
           
            // tag each row with the card id it represents
            row.setTag( tempCard.getCardId() );
 
            return row;
        }

    }  // end CardAdapter class declaration

 
    // our Async class for loading cards from the database
    private class AsyncLoadcards extends AsyncTask<Void, Void, Void>
    {
        @Override
        protected void onPreExecute()
        {
            // if the Tag is larger than an arbitrary size, display
            // the dialog on the presumption that the load will take
            // a few seconds while the app just sits there
            if( currentTag.getCardCount() > 200 && 
                ( ( needLoad == true ) || ( cardArray == null ) ) )
            {
                cardLoadDialog = new ProgressDialog(getActivity());
                cardLoadDialog.setMessage(" Fetching cards... ");
                cardLoadDialog.show();
            }
        }

        @Override
        protected Void doInBackground(Void... unused)
        {
            // get a list of faulted cards, reset the load flag
            if( ( needLoad == true ) || ( cardArray == null ) )
            {
                cardArray = CardPeer.retrieveFaultedCardsForTag(currentTag);
       
                needLoad = false;
            }
 
            return null;
 
        }  // end doInBackground()


        @Override
        protected void onPostExecute(Void unused)
        {
            // set our card info into the ListView
            CardAdapter theAdapter = new CardAdapter();
            cardList.setAdapter(theAdapter);

            if( cardLoadDialog != null)
            {
                cardLoadDialog.dismiss();
            }
    
        }  // end onPostExecute()

  
    }  // end AsyncLoadcards declaration

  
}  // end StudySetWordsFragment class declaration




