package com.longweekendmobile.android.jflash;

//  PracticeActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.jflash.model.Card;
import com.longweekendmobile.android.jflash.model.LWEDatabase;

public class PracticeActivity extends Activity
{
    private static final String MYTAG = "JFlash PracticeActivity";
    
    private PracticeReceiver myReceiver;

    // boolean for checking whether database is already open
    private boolean firedUp;

    private int localColor;

    // also for debugging
    private LinearLayout myLayout;

    public void pop1(View v) {

        Card myCard = new Card();
        myCard.setCardId(12204);
        myCard.hydrate();

        // new commit
//        TextView tempView = (TextView)findViewById(R.id.tempview);
//        tempView.setText( myCard.meaningWithoutMarkup() );
    }

    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.practice);

        // if we're just starting up, force load of color
        localColor = -1;
        
        firedUp = false;
        myReceiver = null;

        // asdf
        myLayout = (LinearLayout)findViewById(R.id.mainlayout);
        
    }


    // this is a bad place to take care of this, just temporary for debugging
    @Override
    public void onResume()
    {
        super.onResume();
        
        // set the background to the current color scheme
        if( localColor != JFApplication.ColorManager.getColorScheme() )
        {
            // load the title bar elements and pass them to the color manager
            RelativeLayout practiceBack = (RelativeLayout)findViewById(R.id.practice_mainlayout);

            JFApplication.ColorManager.setupPracticeBack(practiceBack);
        }
        
        // if our receiver isn't running, start it
        if( myReceiver == null )
        {
            IntentFilter intentFilter;
            myReceiver = new PracticeReceiver();

            intentFilter = new IntentFilter(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_START);
            registerReceiver(myReceiver,intentFilter);
            
            intentFilter = new IntentFilter(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_START2);
            registerReceiver(myReceiver,intentFilter);
            
            intentFilter = new IntentFilter(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_SUCCESS);
            registerReceiver(myReceiver,intentFilter);
            
            intentFilter = new IntentFilter(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_FAILURE);
            registerReceiver(myReceiver,intentFilter);
            
            intentFilter = new IntentFilter(com.longweekendmobile.android.jflash.model.LWEDatabase.DATABASE_READY);
            registerReceiver(myReceiver,intentFilter);
        }
        
        // if our database is not set up, get it started and open it
        if( !firedUp )
        {
            // set our master database instance
            LWEDatabase tempDB = JFApplication.getDao();
            
            // check if our databases have been copied,
            // copy them if they haven't
            tempDB.asynchCopyDatabaseFromAPK();
        }
    
    }  // end onResume()


    @Override
    public void onPause()
    {
        super.onPause();

        if( myReceiver != null )
        {
            unregisterReceiver(myReceiver);
            myReceiver = null;
        }
    }


    @Override
    public void onDestroy()
    {
        super.onDestroy();

        LWEDatabase tempDB = JFApplication.getDao();
        tempDB.detachDatabase();
        tempDB.closeDatabase();
    }
        

    // our receiver class for broadcasts
    // TODO - database stuff temporary for debugging purposes
    protected class PracticeReceiver extends BroadcastReceiver
    {
        @Override
        public void onReceive(Context context,Intent intent)
        {
            TextView tempView = new TextView(context);

            if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_START))
            {
                tempView.setText("Copying db 1...");
                myLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_START2))
            {
                tempView.setText("Copying db 2...");                                
                myLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_SUCCESS))
            {
                tempView.setText("Copy Success");   
                myLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_FAILURE))
            {
                tempView.setText("Copy Failure");                                
                myLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.DATABASE_READY))
            {
                try
                {
                    LWEDatabase tempDB = JFApplication.getDao();
                    firedUp = tempDB.attachDatabase();
/*          
                    if( firedUp )
                    {
                        Button tempButton = (Button)findViewById(R.id.testbutton);
                        tempButton.setVisibility(View.VISIBLE); 
    
                        tempView.setText("Database attached");
                        myLayout.addView(tempView);
                    }
                    else
                    {
                        tempView.setText("Database attach failed");
                        myLayout.addView(tempView);
                    } 
*/
               }
                catch (Exception e)
                {
                    Log.d(MYTAG,"Exception caught attaching DB:  " + e.toString() );
                }
            }

        }  // end onReceive()

    }  // end PracticeReceiver declaration



}  // end PracticeActivity class declaration


