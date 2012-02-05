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
//  public void cancel(View v)

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.view.inputmethod.InputMethodManager;
import android.view.View;
import android.widget.EditText;
import android.widget.Button;
import android.widget.RelativeLayout;

public class CreateTagActivity extends Activity
{
    // private static final String MYTAG = "XFlash TagActivity";
   
    private int localColor;
    private EditText myEdit;
 
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.create_tag);
    
        // if we're just starting up, force load of color
        localColor = -1;

        // launch with the keyboard displayed
        myEdit = (EditText)findViewById(R.id.create_tag_text);
        myEdit.requestFocus();

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

        // set the background to the current color scheme
        if( localColor != XflashColor.getColorScheme() )
        {
            // load the title bar elements and pass them to the color manager
            RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.create_tag_heading);
            Button tempButton = (Button)findViewById(R.id.create_tag_cancelbutton);
            
            XflashColor.setupScheme(titleBar,tempButton);
        }
    }

    @Override
    public void onPause()
    {
        super.onPause();
        
        overridePendingTransition(R.anim.hold,R.anim.slideout_bottom);
    }

    public void cancel(View v)
    {
        finish();
    }


}  // end TagActivity class declaration




