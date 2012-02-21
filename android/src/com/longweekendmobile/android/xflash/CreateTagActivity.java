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

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.view.KeyEvent;
import android.widget.EditText;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

import com.longweekendmobile.android.xflash.model.Group;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class CreateTagActivity extends Activity
{
    private static final String MYTAG = "XFlash TagActivity";
   
    private static Group currentGroup;
    private EditText myEdit;
 
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.create_tag);
    
        // set our click listener for the edit text and request
        // focus
        myEdit = (EditText)findViewById(R.id.create_tag_text);
        myEdit.setOnEditorActionListener( new OnEditorActionListener() 
        {
            @Override
            public boolean onEditorAction(TextView v,int actionId,KeyEvent event) 
            {
                if( actionId == EditorInfo.IME_ACTION_DONE )
                {
                    // when they click 'done' on the keyboard, add the new
                    // group and exit
                    TagPeer.createTagNamed( myEdit.getText().toString() , currentGroup);
    
                    finish();
                }
                
                return false;
            }

        });
        myEdit.requestFocus();

        // launch with the keyboard displayed
        myEdit.postDelayed( new Runnable() 
        {
            @Override
            public void run() 
            {
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
        currentGroup = inGroup;
    }


}  // end TagActivity class declaration




