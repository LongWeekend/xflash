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
//  public static void setCurrentGroup(Group  )
//
//  private void keyboardDone()

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Group;
import com.longweekendmobile.android.xflash.model.GroupPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class CreateTagActivity extends Activity
{
    private static final String MYTAG = "XFlash CreateTagActivity";
   
    // private static Group currentGroup;
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


    public static void setCurrentGroup(Group inGroup)
    {
        // currentGroup = inGroup;
    }

    
    // called by the action listener on our EditText keyboard, when 'done' is pressed
    private void keyboardDone()
    {
        Intent myIntent = getIntent();
        Group currentGroup = null;

        int tempGroupId = myIntent.getIntExtra("group_id",-100);

        if( tempGroupId == -100 )
        {
            Log.d(MYTAG,">>> no group passed");
        }
        else
        {
            currentGroup = GroupPeer.retrieveGroupById(tempGroupId);
        }

        // when they click 'done' on the keyboard, add the new group and exit
        Tag theNewTag = TagPeer.createTagNamed( myEdit.getText().toString() , currentGroup);
         
        int tempCardId = myIntent.getIntExtra("card_id",XflashNotification.NO_CARD_PASSED);
        
        XflashNotification theNotifier = XFApplication.getNotifier();
        theNotifier.setCardIdPassed(tempCardId); 
        theNotifier.newTagBroadcast(theNewTag);

    }  // end keyboardDone()

    
    // the listener for when 'done' is clicked on the keyboard
    private TextView.OnEditorActionListener createTagActionListener = new TextView.OnEditorActionListener() 
    {
        @Override
        public boolean onEditorAction(TextView v,int actionId,KeyEvent event) 
        {
            if( actionId == EditorInfo.IME_ACTION_DONE )
            {
                keyboardDone();
                finish();
                    
                return true;

            }  // end if( DONE was clicked )
                
            // do not consume event if it wasn't 'done'
            return false;
        }  

    };  // end createTagActionListener

    

}  // end CreateTagActivity class declaration




