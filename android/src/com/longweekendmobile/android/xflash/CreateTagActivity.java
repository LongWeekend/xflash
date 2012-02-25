package com.longweekendmobile.android.xflash;

//  CreateTagActivity.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//  public void onResume()      @over
//  public void onPause()       @over
//
//  public static void setWhoIsCalling(int  )
//  public static void setCurrentGroup(Group  )

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.Group;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class CreateTagActivity extends Activity
{
    private static final String MYTAG = "XFlash TagActivity";
   
    public static final int TAG_FRAGMENT_CALLING = 0;
    public static final int SINGLE_CARD_CALLING = 1;
 
    private static int whoIsCalling = -1;
    private static Group currentGroup;
    private EditText myEdit;
 
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.create_tag);
    
        // set our click listener for the edit text and request focus
        myEdit = (EditText)findViewById(R.id.create_tag_text);
        myEdit.setOnEditorActionListener(createTagActionListener);

        // launch with the keyboard displayed
        myEdit.postDelayed( new Runnable() 
        {
            @Override
            public void run() 
            {
                myEdit.requestFocus();
                InputMethodManager keyboard = (InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE);
                keyboard.showSoftInput(myEdit,0);
            }
        },300);

    }  // end onCreate()

    @Override
    public void onResume()
    {
        super.onResume();
        overridePendingTransition(R.anim.slidein_bottom,R.anim.hold);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.create_tag_heading);
            
        XflashSettings.setupColorScheme(titleBar);
    }

    @Override
    public void onPause()
    {
        super.onPause();
        
        overridePendingTransition(R.anim.hold,R.anim.slideout_bottom);
    }

    
    // the listener for when 'done' is clicked on the keyboard
    private TextView.OnEditorActionListener createTagActionListener = new TextView.OnEditorActionListener() 
    {
        @Override
        public boolean onEditorAction(TextView v,int actionId,KeyEvent event) 
        {
            if( actionId == EditorInfo.IME_ACTION_DONE )
            {
                // when they click 'done' on the keyboard, add the new
                // group and exit
                Tag theNewTag = TagPeer.createTagNamed( myEdit.getText().toString() , currentGroup);
                    
                // refresh the appropriate tag list
                if( whoIsCalling == TAG_FRAGMENT_CALLING )
                {
                    TagFragment.setNeedLoad();
                    TagFragment.refreshTagList();
                }
                else if( whoIsCalling == SINGLE_CARD_CALLING )
                {
                    // if called from a specific card, add that card to the new tag
                    int tempCardId = getIntent().getIntExtra("card_id",-1);
                    Card tempCard = CardPeer.retrieveCardByPK(tempCardId);
    
                    TagPeer.subscribeCard(tempCard,theNewTag);
                        
                    AddCardToTagFragment.refreshTagList();
                }

                finish();
                    
                return true;

            }  // end if( DONE was clicked )
                
            // do not consume event if it wasn't 'done'
            return false;
        }  

    };  // end createTagActionListener

    
    public static void setWhoIsCalling(int inCalling)
    {
        if( inCalling < 0 )
        {
            Log.d(MYTAG,"ERROR - setWhoIsCalling() called with:  " + inCalling);
        }

        whoIsCalling = inCalling;
    } 

    public static void setCurrentGroup(Group inGroup)
    {
        currentGroup = inGroup;
    }


}  // end CreateTagActivity class declaration




