package com.longweekendmobile.android.jflash;

//  JflashSplash.java
//  jFlash
//
//  Created by Todd Presson on 2/4/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//

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

import com.longweekendmobile.android.jflash.model.LWEDatabase;

public class JflashSplash extends Activity
{
    private static final String MYTAG = "JFlash JflashSpalsh";
    private final Activity myContext = this;

    private boolean active;
    private int splashTime;
    
    private SplashReceiver myReceiver;
    
    // boolean for checking whether database is already open
    private boolean firedUp;
    
    // also for debugging
    private RelativeLayout myLayout;
    private LinearLayout DBupdateLayout; 

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        
        // set background to splash1 (Long Weekend label)
        setContentView(R.layout.splash);
        
        active = true;
        splashTime = 2000;
        firedUp = false;
        myLayout = (RelativeLayout)findViewById(R.id.splashback);
        DBupdateLayout = (LinearLayout)findViewById(R.id.debug_splash_frame);

        turnOnReceiver();

        // start a thread to pause the first screen for [splashtime] milliseconds
        // when it terminates, it calls goSplash2()
        Thread splashThread1 = new Thread()
        {
            @Override
            public void run()
            {
                try
                {
                    int waited = 0;
                    while( active && ( waited < splashTime ) )
                    {
                        sleep(100);
                        if(active)
                        {
                            waited += 100;
                        }
                    }
                }
                catch(Exception e)
                {
                    Log.d(MYTAG,"Exception in Splash1 pause:  " + e.toString() );
                }
                finally
                {
                    Runnable newRunnable = new Runnable()
                    {
                        @Override
                        public void run()
                        {
                            goSplash2();
                        }
                    };

                    // run on UI thread to have access to view elements
                    runOnUiThread(newRunnable);
                }
            }

        };  // end Thread declaration

        // start the thread we just declared
        splashThread1.start();

    }  // end onCreate()


    // change splash screens, check the database
    public void goSplash2()
    {
        // reset splash background to splash2 (Jflash label)
        RelativeLayout myLayout = (RelativeLayout)findViewById(R.id.splashback);
        myLayout.setBackgroundResource(R.drawable.splash2);
       
        DBupdateLayout.setVisibility(View.VISIBLE);
 
        // set our master database instance
        LWEDatabase tempDB = JFApplication.getDao();
            
        // check if our databases have been copied,
        // copy them if they haven't
        tempDB.asynchCopyDatabaseFromAPK();
    }

   
    // clean up splash and exit to Jflash
    public void wrapUp()
    {
        // start a thread to pause the first screen for [splashtime] milliseconds
        Thread splashThread2 = new Thread()
        {
            @Override
            public void run()
            {
                try
                {
                    int waited = 0;
                    while( active && ( waited < splashTime ) )
                    {
                        sleep(100);
                        if(active)
                        {
                            waited += 100;
                        }
                    }
                }
                catch(Exception e)
                {
                    Log.d(MYTAG,"Exception in spash2 pause:  " + e.toString() );
                }
                finally
                {
                    // without a specific override, Android chooses the animation
                    // to use as this activity closese and Jflash.class opens
                    // may or may not be unpredictable and require manual override
                    myContext.unregisterReceiver(myReceiver);
                    finish();
                    myContext.startActivity(new Intent(myContext,Jflash.class));
                    stop();
                }
            }

        };  // end Thread declaration

        splashThread2.start();
    }

 
    // turn on our BroadcastReceiver
    public void turnOnReceiver()
    {
        IntentFilter intentFilter;
        myReceiver = new SplashReceiver();

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

    }  // end turnOnReceiver()


    // our receiver class for broadcasts
    // TODO - database stuff temporary for debugging purposes
    protected class SplashReceiver extends BroadcastReceiver
    {
        @Override
        public void onReceive(Context context,Intent intent)
        {
            TextView tempView = new TextView(myContext);
            tempView.setTextSize((float)16);
            tempView.setTextColor(0xFF000000);
        
            if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_START))
            {
                tempView.setText("Copying db 1...");
                DBupdateLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_START2))
            {
                tempView.setText("Copying db 2...");                                
                DBupdateLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_SUCCESS))

            {
                tempView.setText("Copy Success");   
                DBupdateLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.COPY_FAILURE))
            {
                tempView.setText("Copy Failure");                                
                DBupdateLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.jflash.model.LWEDatabase.DATABASE_READY))
            {
                tempView.setText("Database Available!");                                
                DBupdateLayout.addView(tempView);
                
                // clean up splash and exit to Jflash
                wrapUp();   
                 
/*
                // TODO - on hold, code for opening and attaching databases
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

*/

            }  // end receive case DATABASE_READY

        }  // end onReceive()

    }  // end PracticeReceiver declaration





}  // end JflashSplash class declaration






/* 
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

