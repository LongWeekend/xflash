package com.longweekendmobile.android.xflash;

//  TagCardsFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void loadTag(int  )
//  public static void startStudying(View  ,Xflash  )
//  public static void addCard(View  ,Xflash  )
//
//  private void setupObservers()
//  private void updateFromSubscriptionObserver()
//
//  private class CardAdapter extends ArrayAdapter<Card> 
//  private class AsyncLoadcards extends AsyncTask<Void, Void, Void>

import java.util.ArrayList;
import java.util.List;
import java.util.Observable;
import java.util.Observer;

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

public class TagCardsFragment extends Fragment
{
    private static final String MYTAG = "XFlash TagCardsFragment";
   
    private static Observer subscriptionObserver = null;
    
    private LinearLayout tagCardsLayout;
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
        setupObservers();

        // inflate our layout for the AllCardsPage fragment
        tagCardsLayout = (LinearLayout)inflater.inflate(R.layout.tag_cards, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)tagCardsLayout.findViewById(R.id.tagcards_heading);
        
        XflashSettings.setupColorScheme(titleBar); 

        // get the tag we're working with
        if( ( currentTag == null ) || ( currentTag.getId() != incomingTagId ) )
        {
            currentTag = TagPeer.retrieveTagById(incomingTagId);
            needLoad = true;
        }

        // set the title bar to the tag name we're looking at
        TextView tempView = (TextView)tagCardsLayout.findViewById(R.id.tagcards_heading_text);
        tempView.setText( currentTag.getName() );

        // get the header, tag it with the id of the current Tag, and add it to the ListView
        cardList = (ListView)tagCardsLayout.findViewById(R.id.tagcards_list);
        LinearLayout header = (LinearLayout)inflater.inflate(R.layout.tagcards_header,cardList,false);
        RelativeLayout realHeader = (RelativeLayout)header.findViewById(R.id.header_block);
        realHeader.setTag( currentTag.getId() );
        cardList.addHeaderView(header);
        
        // save the inflater for use in CardAdapter
        myInflater = inflater;
      
        // load the cards (if necessary)
        AsyncLoadcards tempLoad = new AsyncLoadcards();
        tempLoad.execute();
 
        return tagCardsLayout;

    }  // end onCreateView

    
    public static void setNeedLoad()
    {
        needLoad = true;
    }

    public static void loadTag(int inId)
    {
        incomingTagId = inId;
    }

    // the 'start studying' header of our ListView now directly calls 
    // TagFragment_startStudying() from Xflash, which calls
    // TagFragment.startStudying(View  ,Xflash  ) because it has the
    // exact same functionality.  Would it be better to have the xml
    // call THIS startStudying() and then call TagFragment from here?

/*
    public static void startStudying(View v,Xflash inContext)
    {
    }
*/

    public static void addCard(View v,Xflash inContext)
    {
        int tempInt = (Integer)v.getTag();

        AddCardToTagFragment.loadCard(tempInt);
        inContext.onScreenTransition("add_card",XflashScreen.DIRECTION_OPEN);
    }

   
    // method to set all relevant Observers
    private void setupObservers()
    {
        if( subscriptionObserver == null )
        {
            // create and define behavior for newTagObserver
            subscriptionObserver = new Observer()
            {
                public void update(Observable obj,Object arg)
                {
                    updateFromSubscriptionObserver();
                }  
            };

        }  // end if( subscriptionObserver == null )

        XFApplication.getNotifier().addSubscriptionObserver(subscriptionObserver);

    }  // end setupObservers()


    private void updateFromSubscriptionObserver()
    {
        // only refresh if modified card was in the tag we
        // are currently displaying
        if( currentTag.getId() == XFApplication.getNotifier().getTagIdPassed() )
        {
            TagCardsFragment.needLoad = true;
        }
    
    }  // end updateFromSubscriptionObserver()


    // custom adapter to appropriately fill the view for our ListView
    private class CardAdapter extends ArrayAdapter<Card> 
    {
        CardAdapter() 
        {
            super( getActivity(), R.layout.tagcards_row, (List<Card>)cardArray);
        }
        
        public View getView(int position, View convertView, ViewGroup parent) 
        {
            View row = convertView;
            
            if( row == null ) 
            {
                row = myInflater.inflate(R.layout.tagcards_row, parent, false);
            }
            
            Card tempCard = cardArray.get(position);

            if( tempCard.isFault )
            {
                tempCard.hydrate();
            }

            // set the word
            TextView tempView = (TextView)row.findViewById(R.id.tagcards_word);
            tempView.setText( tempCard.headwordIgnoringMode(true) );

            // set the meaning
            tempView = (TextView)row.findViewById(R.id.tagcards_meaning);
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
            // launch a loading dialog if it is required
            if( ( needLoad == true ) || ( cardArray == null ) )
            {
                cardLoadDialog = new ProgressDialog(getActivity());
                cardLoadDialog.setMessage( getResources().getString(R.string.tagcards_fetching) );
                cardLoadDialog.show();
            }
        }

        @Override
        protected Void doInBackground(Void... unused)
        {
            // get a list of faulted cards, reset the load flag
            // but only if our card is null or has changed
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

            // clear the progress dialog
            if( cardLoadDialog != null )
            {
                cardLoadDialog.dismiss();
                cardLoadDialog = null;
            }

        }  // end onPostExecute()

  
    }  // end AsyncLoadcards declaration

  
}  // end TagCardsFragment class declaration





