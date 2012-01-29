package com.longweekend.android.jflash;

//  XflashGroupActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/28/2012.
//  Copyright 2012 LONG WEEKEND INC.. All rights reserved.
//
//  a generic ActivityGroup extension for Jflash/Cflash
//
//  public void onCreate()      @over
//
//  public void finishFromChild(Activity  )             @over
//  public void startChildActivity(String  ,Intent  )   @over

import java.util.ArrayList;

import android.app.Activity;
import android.app.ActivityGroup;
import android.app.LocalActivityManager;
import android.content.Intent;
import android.os.Bundle;
import android.view.Window;

public class XflashGroupActivity extends ActivityGroup
{
    // private static final String MYTAG = "JFlash HelpGroupActivity";
    
    private ArrayList<String> myIdList;
    

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    
        // keep a String list of running Activity IDs
        if( myIdList == null )
        {
            myIdList = new ArrayList<String>();
        }
    }


    // automatically called when a child Activity calls finish()
    @Override
    public void finishFromChild(Activity child)
    {
        LocalActivityManager manager = getLocalActivityManager();
        
        int index = myIdList.size() - 1;
        
        // code for killing our activity group if no more children
        if (index < 1) 
        {
            finish();
            return;
        }
        
        // remove the ending Activity from memory
        manager.destroyActivity(myIdList.get(index),true);
        myIdList.remove(index);

        // pull the name of the previously running Activity
        index--;
        String lastId = myIdList.get(index);
        
        // and restart/reload the previously running Activity, since
        // we are now returning to it
        Intent lastIntent = manager.getActivity(lastId).getIntent();
        Window newWindow = manager.startActivity(lastId, lastIntent);
        setContentView(newWindow.getDecorView());

    }  // end finishFromChild() 


    // start child method that is called from any Activity that
    // inherits from XflashGroupActivity.class
    public void startChildActivity(String Id,Intent intent)
    {
        // fire up the intended child Activity
        Window window = getLocalActivityManager().startActivity(Id,intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP));
        
        if ( window != null )
        { 
            // if it worked, add it to the list of running Activities
            // and set the main view
            myIdList.add(Id);
            setContentView(window.getDecorView());
        }
    }


}  // end HelpGroupActivity class declaration






