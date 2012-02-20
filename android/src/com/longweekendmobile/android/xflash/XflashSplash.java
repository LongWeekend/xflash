package com.longweekendmobile.android.xflash;

//  XflashSplash.java
//  XFlash
//
//  Created by Todd Presson on 2/4/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

import android.app.Activity;
import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.LWEDatabase;

public class XflashSplash extends Activity
{
    private static final String MYTAG = "XFlash XflashSpalsh";

    private static final boolean isDebugging = true;

    private final Activity myContext = this;

    private boolean active;
    private int splashTime;
    
    private SplashReceiver myReceiver;
    
    // boolean for checking whether database is already open
    private boolean firedUp;
    
    // also for debugging
    private LinearLayout DBupdateLayout; 

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        // set background to splash1 (Long Weekend label)
        setContentView(R.layout.splash);
        
        if( isDebugging )
        {
            splashTime = 200;
        }
        else
        {
            splashTime = 2000;
        } 

        active = true;
        firedUp = false;
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
        // reset splash background to splash2 (Xflash label)
        RelativeLayout myLayout = (RelativeLayout)findViewById(R.id.splashback);
        myLayout.setBackgroundResource(R.drawable.splash2);
       
        DBupdateLayout.setVisibility(View.VISIBLE);
 
        // set our master database instance
        LWEDatabase tempDB = XFApplication.getDao();
            
        // check if our databases have been copied,
        // copy them if they haven't
        tempDB.asynchCopyDatabaseFromAPK();
    }

   
    // clean up splash and exit to Xflash
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
                    // to use as this activity closese and Xflash.class opens
                    // may or may not be unpredictable and require manual override
                    myContext.unregisterReceiver(myReceiver);
                    finish();
                    myContext.startActivity(new Intent(myContext,Xflash.class));
                    // deprecated stop();
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

        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START2);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_SUCCESS);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_FAILURE);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.DATABASE_READY);
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
        
            if( intent.getAction().equals(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START))
            {
                tempView.setText("Copying db 1...");
                DBupdateLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START2))
            {
                tempView.setText("Copying db 2...");                                
                DBupdateLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_SUCCESS))

            {
                tempView.setText("Copy Success");   
                DBupdateLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_FAILURE))
            {
                // if the database fails to copy over successfully, they're probably
                // running low on space on their phone
                tempView.setText("Copy Failure");                                
                DBupdateLayout.addView(tempView);

                // set and fire our AlertDialog
                AlertDialog.Builder builder = new AlertDialog.Builder(myContext);
                builder.setTitle( getResources().getString(R.string.copyerror_title) );
                builder.setMessage( getResources().getString(R.string.copyerror_body) );

                // on postive response, set the new active user
                builder.setPositiveButton("bummer", new DialogInterface.OnClickListener()
                {
                    public void onClick(DialogInterface dialog,int which)
                    {
                        finish();
                    }
               });

                // show error dialog and exit the app
                builder.create().show();
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.xflash.model.LWEDatabase.DATABASE_READY))
            {
                // when the database is ready to go, attach the CARD database
                try
                {
                    LWEDatabase tempDB = XFApplication.getDao();
                    firedUp = tempDB.attachDatabase();
                    
                    if( firedUp )
                    {
                        tempView.setText("Database attached");
                        DBupdateLayout.addView(tempView);
            
                        tempView = new TextView(myContext);
                        tempView.setTextSize((float)16);
                        tempView.setTextColor(0xFF000000);
            
                        tempView.setText("Database Available!");
                        DBupdateLayout.addView(tempView);
                    }
                    else
                    {
                        tempView.setText("Database attach failed");
                        DBupdateLayout.addView(tempView);
            
                        tempView = new TextView(myContext);
                        tempView.setTextSize((float)16);
                        tempView.setTextColor(0xFF000000);
            
                        tempView.setText("Database BROKEN!");
                        DBupdateLayout.addView(tempView);
                    } 
                }
                catch (Exception e)
                {
                    Log.d(MYTAG,"Exception caught attaching DB:  " + e.toString() );
                }
                
                // clean up splash and exit to Xflash
                wrapUp();   
                 

            }  // end receive case DATABASE_READY

        }  // end onReceive()

    }  // end PracticeReceiver declaration


}  // end XflashSplash class declaration





