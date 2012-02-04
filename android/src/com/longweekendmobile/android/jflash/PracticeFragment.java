package com.longweekendmobile.android.jflash;

//  PracticeFragment.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//  public void onResume()                                              @over

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

public class PracticeFragment extends Fragment
{
    // private static final String MYTAG = "JFlash PracticeFragment";
    
    // properties for handling color theme transitions
    private RelativeLayout practiceLayout;

    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    }


    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate the layout for our practice activity and return it
        practiceLayout = (RelativeLayout)inflater.inflate(R.layout.practice, container, false);
        
        return practiceLayout;
    }
  

    // this is a bad place to take care of this, just temporary for debugging
    @Override
    public void onResume()
    {
        super.onResume();
        
        // load the title bar elements and pass them to the color manager
        RelativeLayout practiceBack = (RelativeLayout)practiceLayout.findViewById(R.id.practice_mainlayout);

        JFApplication.ColorManager.setupPracticeBack(practiceBack);
    
    }  // end onResume()

}  // end PracticeFragment class declaration





/*
    RIPPED FROM FUNCTIONALITY - MUST BE MOVED TO Jflash.class

    private PracticeReceiver myReceiver;
    
    // boolean for checking whether database is already open
    private boolean firedUp;
    
    // also for debugging
    private LinearLayout myLayout;
   

FROM ONCREATE
        
        firedUp = false;
        myReceiver = null;

        myLayout = (LinearLayout)findViewById(R.id.mainlayout);

END FROM ONCREATE



FROM ONRESUME

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
    
END FROM ONRESUME

 
    public void pop1(View v) {

        Card myCard = new Card();
        myCard.setCardId(12204);
        myCard.hydrate();

        // new commit
        // TextView tempView = (TextView)findViewById(R.id.tempview);
        // tempView.setText( myCard.meaningWithoutMarkup() );
    }


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
        
*/

    // our receiver class for broadcasts
    // TODO - database stuff temporary for debugging purposes
/*
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
               }
                catch (Exception e)
                {
                    Log.d(MYTAG,"Exception caught attaching DB:  " + e.toString() );
                }
            }

        }  // end onReceive()

    }  // end PracticeReceiver declaration

*/




