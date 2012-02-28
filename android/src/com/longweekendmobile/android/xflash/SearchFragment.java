package com.longweekendmobile.android.xflash;

//  SearchFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import java.util.ArrayList;
import java.util.List;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class SearchFragment extends Fragment
{
    private static final String MYTAG = "XFlash SearchFragment";
    
    private static LinearLayout searchLayout = null;
    private static EditText mySearch = null;
    private static LayoutInflater myInflater;
    private InputMethodManager imm = null;
    private ListView searchList;

    private static Tag starredTag;
    private static ProgressDialog searchDialog = null;
    private static ArrayList<Card> searchResults = null;
    private static ArrayList<Card> membershipCacheArray = null;

    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // save the inflater, input manager, and starred words tag for later use
        myInflater = inflater;
        starredTag = Tag.starredWordsTag();
        imm = (InputMethodManager)getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);

        // inflate our layout for the Search activity
        searchLayout = (LinearLayout)inflater.inflate(R.layout.search, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)searchLayout.findViewById(R.id.search_heading);
        Button tempButton = (Button)searchLayout.findViewById(R.id.search_cancelbutton);
  
        XflashSettings.setupColorScheme(titleBar,tempButton);
        
        // set our listeners
        mySearch = (EditText)searchLayout.findViewById(R.id.search_text);
        mySearch.setOnFocusChangeListener(searchFocusListener);
        mySearch.setOnEditorActionListener(searchActionListener);

        // get the ListView to display results
        searchList = (ListView)searchLayout.findViewById(R.id.search_list);

        // if we have existing results from a prior search, display them on load
        if( searchResults != null )
        {
            SearchAdapter theAdapter = new SearchAdapter();
            searchList.setAdapter(theAdapter);
        }
        else
        {
            // launch with the keyboard displayed if there are no
            // previously existing search results
            mySearch.postDelayed( new Runnable()
            {
                @Override
                public void run()
                {
                    mySearch.requestFocus();
                }
            },300);
        }
     
        return searchLayout;

    }  // end onCreateView()

    @Override
    public void onPause()
    {
        super.onPause();

        // flush the cache array when the search fragment is paused
        membershipCacheArray = null;
    }

    public static void addCard(View v,Xflash inContext)
    {
        int tempInt = (Integer)v.getTag();
        Log.d(MYTAG,">>> card clicked in SearchFragment");
        Log.d(MYTAG,"> card id:  " + tempInt);
    }

    
    // modify the 'starred' status of the clicked Card
    public static void toggleStar(View v)
    {
        Card tempCard = (Card)v.getTag();
        ImageView starImage = (ImageView)v;

        boolean isMember = false;

        // check whether this card is already starred
        if( membershipCacheArray != null )
        {
            if( membershipCacheArray.size() > 0 )
            {
                isMember = checkMembershipCacheForCard(tempCard); 
            }
        }
        else
        {
            isMember = TagPeer.card(tempCard,starredTag); 
        }
  

        if(isMember)
        {
            // if the card is currently starred, remove
            TagPeer.cancelMembership(tempCard,starredTag);
            membershipCacheArray.remove(tempCard);    
            starImage.setImageResource(R.drawable.star_deselected);
        }
        else
        {
            // if it is NOT starred, add
            TagPeer.subscribeCard(tempCard,starredTag);
            membershipCacheArray.add(tempCard);
            starImage.setImageResource(R.drawable.star_selected);
        }
 
        // inform TagFragment that the starred words tag has changed
        // TODO - bad solution, temporary
        // TagFragment.setNeedLoad();
        // TagCardsFragment.setNeedLoad();

    }  // end toggleStar()


    // checks the local cache for starred status, or creates it
    private static boolean checkMembershipCacheForCard(Card inCard)
    {
        if( membershipCacheArray == null )
        {
            // if the cache array hasn't be loaded, do so
            membershipCacheArray = CardPeer.retrieveFaultedCardsForTag(starredTag);
        }
        
        return membershipCacheArray.contains(inCard);

    }  // end checkMembershipCacheForCard()

    
    // display keyboard on focus, hide when focus leaves
    private EditText.OnFocusChangeListener searchFocusListener = new EditText.OnFocusChangeListener()
    {
        @Override
        public void onFocusChange(View v, boolean hasFocus)
        {
            if(hasFocus)
            {
                // show keyboard
                imm.showSoftInput(mySearch,0);
            }
            else
            {
                // hide keyboard
                imm.hideSoftInputFromWindow(mySearch.getWindowToken(),0);
            }
        }

    };  // end searchFocusListener 


    private TextView.OnEditorActionListener searchActionListener =  new TextView.OnEditorActionListener()
    {
        @Override
        public boolean onEditorAction(TextView v,int actionId,KeyEvent event)
        {
            if( actionId == EditorInfo.IME_ACTION_DONE )
            {
                // when they click 'done' on the keyboard,
                // search and hide keyboard
                mySearch.clearFocus();

                AsyncSearch tempSearch = new AsyncSearch();
                tempSearch.execute();

                return true;

            }  // end if( DONE was clicked )

            // do not consume event if it wasn't 'done'
            return false;
        }  

    };  // end searchActionListener


    // our Async class for loading cards from the database
    private class AsyncSearch extends AsyncTask<Void, Void, Void>
    {
        @Override
        protected void onPreExecute()
        {
            // display a loading dialog
            searchDialog = new ProgressDialog(getActivity());
            searchDialog.setMessage(" Searching... ");
            searchDialog.show();
        }

        
        @Override
        protected Void doInBackground(Void... unused)
        {
            String searchString = mySearch.getText().toString();

            searchResults = CardPeer.searchCardsForKeyword(searchString);            
           
            // if we got no results and there was no 'deep search,' do
            // one automatically
            if( ( searchResults.size() == 0 ) && ( !searchString.endsWith("?") ) )
            {
                String newSearch = searchString + "?";
                searchResults = CardPeer.searchCardsForKeyword(newSearch);
            }

            return null;
        }

        @Override
        protected void onPostExecute(Void unused)
        {
            // set our returned card info into the ListView
            SearchAdapter theAdapter = new SearchAdapter();
            searchList.setAdapter(theAdapter);
            
            // clear the progress dialog
            searchDialog.dismiss();
        }  

    
    }  // end AsyncSearch declaration


    // custom adapter to appropriately fill the view for our ListView
    private class SearchAdapter extends ArrayAdapter<Card>
    {
        SearchAdapter()
        {
            super( getActivity(), R.layout.search_row, (List<Card>)searchResults);
        }

        public View getView(int position, View convertView, ViewGroup parent)
        {
            View row = convertView;

            if( row == null )
            {
                row = myInflater.inflate(R.layout.search_row, parent, false);
            }

            JapaneseCard tempCard = (JapaneseCard)searchResults.get(position);

            if( tempCard.isFault )
            {
                tempCard.hydrate();
            }

            // set the star image and tag with the card id for toggle
            ImageView starImage = (ImageView)row.findViewById(R.id.search_row_image);
            if( checkMembershipCacheForCard(tempCard) )
            {
                starImage.setImageResource(R.drawable.star_selected);
            }
            else
            {
                starImage.setImageResource(R.drawable.star_deselected);
            }
            
            // tag the star image with our card id for toggling
            starImage.setTag(tempCard);

            // set the word
            TextView tempView = (TextView)row.findViewById(R.id.search_row_top);
            tempView.setText( tempCard.headwordIgnoringMode(true) );

            // set the meaning
            tempView = (TextView)row.findViewById(R.id.search_row_middle);
            tempView.setText( tempCard.reading() );
            
            // set the meaning
            tempView = (TextView)row.findViewById(R.id.search_row_bottom);
            tempView.setText( tempCard.meaningWithoutMarkup() );

            // tag each row with the card id it represents
            row.setTag( tempCard.getCardId() );

            return row;
        }

    }  // end SearchAdapter class declaration


}  // end SearchFragment class declaration


