package com.longweekendmobile.android.xflash;

//  TagCardsFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void setNeedLoad()
//  public static void loadTag(int  )
//  public static void dumpObservers()
//
//  private void editTag()
//  private void addCard(View  )
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
import com.longweekendmobile.android.xflash.model.GroupPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class TagCardsFragment extends Fragment
{
    // private static final String MYTAG = "XFlash TagCardsFragment";
   
    private static boolean needLoad = false;
    private static int incomingTagId;
    
    private LayoutInflater myInflater;
    private LinearLayout tagCardsLayout;
    private ListView cardList;

    // static so we don't unnecessarily make databaase calls
    private static Tag currentTag = null;
    private static ArrayList<Card> cardArray = null;
 
    private ProgressDialog cardLoadDialog = null;

    private static Observer subscriptionObserver = null;
    private static Observer newTagObserver = null;    
    
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

        // get the headers, buried in a wrapper
        cardList = (ListView)tagCardsLayout.findViewById(R.id.tagcards_list);
        LinearLayout header = (LinearLayout)inflater.inflate(R.layout.tagcards_header,cardList,false);
        
        // tag the 'start studying' header with the currentTag id, add a click listener
        RelativeLayout studyHeader = (RelativeLayout)header.findViewById(R.id.tagcards_header_startstudying);
        
        studyHeader.setTag( currentTag.getId() );
        studyHeader.setOnClickListener( new View.OnClickListener()
        {
            public void onClick(View v)
            {
                // XflashAlert.startStudying(v);

                int tagId = (Integer)v.getTag();
                Tag tempTag = TagPeer.retrieveTagById(tagId);

                XflashSettings.setActiveTag(tempTag);
                Xflash.getTabHost().setCurrentTabByTag("practice");
            }
        });

        // get the 'edit set details' header
        RelativeLayout editHeader = (RelativeLayout)header.findViewById(R.id.tagcards_header_editset);
        
        // if we're looking at a use tag, set a click listener to cue the EditTagDetailsFragment
        // else, hide the view
        if( currentTag.isEditable() )
        {
            editHeader.setTag( currentTag.getId() );
            editHeader.setOnClickListener( new View.OnClickListener()
            {
                public void onClick(View v)
                {
                    editTag();
                }
            });

            studyHeader.setBackgroundResource( XflashSettings.getTopByColor() );
            editHeader.setBackgroundResource( XflashSettings.getBottomByColor() );
        }
        else
        {
            editHeader.setVisibility(View.GONE);
            studyHeader.setBackgroundResource( XflashSettings.getSingleByColor() );
        }

        // assign the header to our ListView of cards
        cardList.addHeaderView(header);
        
        // save the inflater for use in CardAdapter
        myInflater = inflater;
      
        // load the cards (if necessary)
        AsyncLoadcards tempLoad = new AsyncLoadcards();
        tempLoad.execute();
 
        // turn on fading edges on scroll
        cardList.setVerticalFadingEdgeEnabled(true);
        
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

    public static void dumpObservers()
    {
        subscriptionObserver = null;
    }


    // launch CreateTagActivity in edit mode
    private void editTag()
    {
        // set relevant data statically, since we need to use a Fragment
        EditTagFragment.setTagToEdit(currentTag);
        EditTagFragment.setGroupId( GroupPeer.topLevelGroup().getGroupId() );
        EditTagFragment.setCardId( XflashNotification.NO_CARD_PASSED );
        // EditTagFragment.setActivityContext(null);
 
        Xflash.getActivity().onScreenTransition("edit_tag",XflashScreen.DIRECTION_OPEN);
    
    }  // end editTag()
   
    
    // launches AddCardToTagFragment
    private void addCard(View v)
    {
        int tempInt = (Integer)v.getTag();

        AddCardToTagFragment.loadCard(tempInt);
        Xflash.getActivity().onScreenTransition("add_card",XflashScreen.DIRECTION_OPEN);
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

            XFApplication.getNotifier().addSubscriptionObserver(subscriptionObserver);
        
        }  // end if( subscriptionObserver == null )

        if( newTagObserver == null )
        {
            // create and define behavior for newTagObserver
            newTagObserver = new Observer()
            {
                public void update(Observable obj,Object arg)
                {
                    updateFromNewTagObserver(arg);
                }  
            };

            XFApplication.getNotifier().addNewTagObserver(newTagObserver);
        
        }  // end if( subscriptionObserver == null )

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


    private void updateFromNewTagObserver(Object passedObject)
    {
        // get the Tag that was just added
        Tag theNewTag = (Tag)passedObject;

        // only refresh the name if new tag notification came from 
        // the Tag we're currently displaying
        if( theNewTag.getId() == currentTag.getId() ) 
        {
            // reset the currentTag, since its name has changed
            // in the database
            currentTag = TagPeer.retrieveTagById(incomingTagId);
            
            // set the title bar to the tag name we're looking at
            TextView tempView = (TextView)tagCardsLayout.findViewById(R.id.tagcards_heading_text);
            tempView.setText( currentTag.getName() );
        }

    }  // end updateFromNewTagObserver()


    // custom adapter to appropriately fill the view for our ListView
    private class CardAdapter extends ArrayAdapter<Card> 
    {
        CardAdapter() 
        {
            super( getActivity(), R.layout.tagcards_row, (List<Card>)cardArray);
        }
        
        public View getView(int position, View convertView, ViewGroup parent) 
        {
            // try for a recycled view
            View row = convertView;
            
            if( row == null ) 
            {
                row = myInflater.inflate(R.layout.tagcards_row, parent, false);
            }
            
            // set the background according to position
            if( cardArray.size() == 1 )
            {
                // if they're only one card, round all corners
                row.setBackgroundResource( XflashSettings.getSingleByColor() );
            }
            else if( position == 0 )
            {
                // top row, top corners rounded
                row.setBackgroundResource( XflashSettings.getTopByColor() );
            }
            else if( position == ( cardArray.size() - 1 ) )
            {
                // bottom row, bottom corners rounded
                row.setBackgroundResource( XflashSettings.getBottomByColor() );
            }
            else
            {
                // middle row, no corners
                row.setBackgroundResource( XflashSettings.getMiddleByColor() );
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
           
            // tag each row with the card id it represents and set a click listener
            row.setTag( tempCard.getCardId() );
            row.setOnClickListener( new View.OnClickListener()
            {
                @Override
                public void onClick(View v)
                {
                    addCard(v);
                }
            });
 
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





