package com.longweekendmobile.android.xflash;

//  SearchFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnFocusChangeListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

public class SearchFragment extends Fragment
{
    private static final String MYTAG = "XFlash SearchFragment";
    
    private static LinearLayout searchLayout = null;
    private EditText mySearch = null;
    private InputMethodManager imm = null;

    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Search activity
        searchLayout = (LinearLayout)inflater.inflate(R.layout.search, container, false);
        mySearch = (EditText)searchLayout.findViewById(R.id.search_text);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)searchLayout.findViewById(R.id.search_heading);
        Button tempButton = (Button)searchLayout.findViewById(R.id.search_cancelbutton);
  
        XflashSettings.setupColorScheme(titleBar,tempButton);
        
        // get input method manager for keyboard transitions
        imm = (InputMethodManager)getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);

        // set our listeners
        mySearch.setOnFocusChangeListener(searchFocusListener);
        mySearch.setOnEditorActionListener(searchActionListener);

        // launch with the keyboard displayed
        mySearch.postDelayed( new Runnable()
        {
            @Override
            public void run()
            {
                mySearch.requestFocus();
            }
        },300);
        
        return searchLayout;

    }  // end onCreateView()


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

                return true;

            }  // end if( DONE was clicked )

            // do not consume event if it wasn't 'done'
            return false;
        }  

    };  // end searchActionListener


}  // end SearchFragment class declaration


