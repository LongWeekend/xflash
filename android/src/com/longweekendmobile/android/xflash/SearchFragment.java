package com.longweekendmobile.android.xflash;

//  SearchFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//  public void onPause()                                               @over
//
//  private void popKeyboard()
//  private void addCard(View  )
//  private void toggleStar(View  )
//  private void performSearch()
//
//  private boolean checkMembershipCacheForCard(Card  )
//
//  private class AsyncSearch extends AsyncTask<Void, Void, Void>
//  private class SearchAdapter extends ArrayAdapter<Card>

import java.util.ArrayList;
import java.util.List;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.LWEDatabase;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class SearchFragment extends Fragment
{
    // private static final String MYTAG = "XFlash SearchFragment";
    
    private EditText mySearch = null;
    private LayoutInflater myInflater;
    private InputMethodManager imm = null;
    private TextView noResults = null;
    private ListView searchList;

    private Tag starredTag;
    private ProgressDialog searchDialog = null;
    private ArrayList<Card> searchResults = null;
    private ArrayList<Card> membershipCacheArray = null;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // save the inflater, input manager, and starred words tag for later use
        myInflater = inflater;
        starredTag = TagPeer.starredWordsTag();
        imm = (InputMethodManager)Xflash.getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);

        // inflate our layout for the Search activity
        LinearLayout searchLayout = (LinearLayout)inflater.inflate(R.layout.search, container, false);
        noResults = (TextView)searchLayout.findViewById(R.id.no_searchresults);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)searchLayout.findViewById(R.id.search_heading);
        XflashSettings.setupColorScheme(titleBar);
        
        // set our listeners
        mySearch = (EditText)searchLayout.findViewById(R.id.search_text);
        mySearch.setOnEditorActionListener(searchActionListener);

        // get the ListView to display results
        searchList = (ListView)searchLayout.findViewById(R.id.search_list);

        // if we have existing results from a prior search, display them on load
        if( ( searchResults != null ) && ( searchResults.size() > 0 ) )
        {
            SearchAdapter theAdapter = new SearchAdapter();
            searchList.setAdapter(theAdapter);
        }
        else
        {
            // launch with the keyboard displayed if there are no
            // previously existing search results
            popKeyboard();
        }
     
        // turn on fading edge on scroll
        searchList.setVerticalFadingEdgeEnabled(true);
        
        return searchLayout;

    }  // end onCreateView()

    
    @Override
    public void onPause()
    {
        super.onPause();

        // TODO - this forces the adapter to reload the starred words tag into
        //        the cache array when the user returns to this view. Is it 
        //        necessary/desirable to eliminate this forced refresh and rely 
        //        on Observer notifications to maintain the cacheArray instead?
        
        // flush the cache array when the search fragment is paused
        membershipCacheArray = null;

    }  // end onPause

   
    // show the keyboard
    private void popKeyboard()
    {
        mySearch.postDelayed( new Runnable()
        {
            @Override
            public void run()
            {
                mySearch.requestFocus();
                imm.showSoftInput(mySearch,0);
            }
        },300);

    }  // end popKeyboard()

    
    // launch AddCardToTagFragment
    private void addCard(View v)
    {
        int tempInt = (Integer)v.getTag();

        AddCardToTagFragment.loadCard(tempInt);
        Xflash.getActivity().onScreenTransition("search_add_card",XflashScreen.DIRECTION_OPEN);
    }

    
    // modify the 'starred' status of the clicked Card
    private void toggleStar(View v)
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
            isMember = TagPeer.cardIsMemberOfTag(tempCard,starredTag); 
        }
  

        // if the card is currently starred, remove
        if(isMember)
        {
            if( TagPeer.cancelMembership(tempCard,starredTag) ) 
            {
                // only adjust search view if remove is successful
                membershipCacheArray.remove(tempCard);    
                starImage.setImageResource(R.drawable.star_deselected);
            }
        }
        else
        {
            // if it is NOT starred, add
            TagPeer.subscribeCard(tempCard,starredTag);
            membershipCacheArray.add(tempCard);
            starImage.setImageResource(R.drawable.star_selected);
        }
 
    }  // end toggleStar()


    // performs the actual search
    private void performSearch()
    {
        // when they click 'done' on the keyboard,
        // search and hide keyboard
        mySearch.clearFocus();
        noResults.setVisibility(View.GONE);

        AsyncSearch tempSearch = new AsyncSearch();
        tempSearch.execute();

        imm.hideSoftInputFromWindow(mySearch.getWindowToken(),0);

    }  // end performSearch


    // checks the local cache for starred status, or creates it
    private boolean checkMembershipCacheForCard(Card inCard)
    {
        if( membershipCacheArray == null )
        {
            // if the cache array hasn't be loaded, do so
            membershipCacheArray = CardPeer.retrieveFaultedCardsForTag(starredTag);
        }
        
        return membershipCacheArray.contains(inCard);

    }  // end checkMembershipCacheForCard()

    
    // our Async class for loading cards from the database
    private class AsyncSearch extends AsyncTask<Void, Void, Void>
    {
        @Override
        protected void onPreExecute()
        {
            // display a loading dialog
            searchDialog = new ProgressDialog( Xflash.getActivity() );
            searchDialog.setMessage(" Searching... ");
            searchDialog.show();
        
            // attach the search database
            boolean attachSuccess = XFApplication.getDao().attachDatabase(LWEDatabase.DB_FTS); 
            if( !attachSuccess )
            {
                throw new RuntimeException(">>> ERROR SearchFragment.AsynchSearch - attach failed");
            }

        }  // end onPreExecute()

        
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
            // detach the search database
            XFApplication.getDao().detachDatabase(LWEDatabase.DB_FTS); 
            
            // set our returned card info into the ListView
            SearchAdapter theAdapter = new SearchAdapter();
            searchList.setAdapter(theAdapter);
            
            // clear the progress dialog
            searchDialog.dismiss();

            // re-show the keyboard if there were no results
            if( searchResults.size() == 0 )
            {
                noResults.setVisibility(View.VISIBLE);
                popKeyboard();
            }

        }  // end onPostExecute()
    
    }  // end AsyncSearch declaration


    // custom adapter to appropriately fill the view for our ListView
    private class SearchAdapter extends ArrayAdapter<Card>
    {
        SearchAdapter()
        {
            super( Xflash.getActivity(), R.layout.search_row, (List<Card>)searchResults);
        }

        public View getView(int position, View convertView, ViewGroup parent)
        {
            // try to pull a recycled view
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

            // set click listener for the whole row, and the star
            row.setOnClickListener(rowListener);
            starImage.setOnClickListener(starListener);
            
            return row;
        }

    }  // end SearchAdapter class declaration


    // when a search-card row is clicked, fire AddCardToTagFragment
    private View.OnClickListener rowListener = new View.OnClickListener()
    {
        @Override
        public void onClick(View v)
        {
            addCard(v);
        }
    };

   
    // when a star is clicked on, toggle 'starred tag' status
    private View.OnClickListener starListener = new View.OnClickListener()
    {
        @Override
        public void onClick(View v)
        {
            toggleStar(v);
        }
    };

    
    // listener to perform a search when 'done' is pressed on the keyboard
    private TextView.OnEditorActionListener searchActionListener =  new TextView.OnEditorActionListener()
    {
        @Override
        public boolean onEditorAction(TextView v,int actionId,KeyEvent event)
        {
            if( actionId == EditorInfo.IME_ACTION_SEARCH )
            {
                performSearch();
                
                return true;

            }  // end if( DONE was clicked )

            // do not consume event if it wasn't 'done'
            return false;
        }  

    };  // end searchActionListener


}  // end SearchFragment class declaration


