package com.longweekendmobile.android.xflash;

//  XflashSplash.java
//  XFlash
//
//  Created by Todd Presson on 2/4/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.

import android.app.Activity;
import android.app.AlertDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Resources;
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
    private static final boolean XFLASH_COPY_FAIL = false;
    private static final boolean XFLASH_ATTACH_FAIL = true;

    private final Activity myContext = this;
    private SplashReceiver myReceiver;

    // properties for managing the splash delay
    private int splashTime;
    
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
                    while( waited < splashTime )
                    {
                        sleep(100);
                        waited += 100;
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
                    while( waited < splashTime )
                    {
                        sleep(100);
                        waited += 100;
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

    }  // end wrapUp()


    // handles informing user of a fatal error relating to database initialization
    public void splashError(boolean inError)
    {
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder(myContext);
        
        Resources res = getResources();

        if( inError == XFLASH_COPY_FAIL )
        {
            builder.setTitle( res.getString(R.string.copyerror_title) );
            builder.setMessage( res.getString(R.string.copyerror_body) );
        }
        else if( inError == XFLASH_ATTACH_FAIL )
        {
            builder.setTitle( res.getString(R.string.attacherror_title) );
            builder.setMessage( res.getString(R.string.attacherror_body) );
        }

        // exit the app when they're done
        builder.setPositiveButton("bummer", new DialogInterface.OnClickListener()
        {
            public void onClick(DialogInterface dialog,int which)
            {
                finish();
            }
        });

        // show error dialog and exit the app
        builder.create().show();

    }  // end splashError()

 
    // turn on our BroadcastReceiver
    public void turnOnReceiver()
    {
        IntentFilter intentFilter;
        myReceiver = new SplashReceiver();

        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START2);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START3);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_SUCCESS);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_FAILURE);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.DATABASE_READY);
        registerReceiver(myReceiver,intentFilter);

    }  // end turnOnReceiver()


    // our receiver class for broadcasts
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
            else if( intent.getAction().equals(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START2))
            {
                tempView.setText("Copying db 3...");                                
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
            
                // display an error dialog and exit
                splashError(XFLASH_COPY_FAIL);
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
                
                        // THIS IS WHERE WE ARE ACTUALLY EXITING THE SPLASH
                        // SCREEN SUCCESSFULLY AND STARTING THE APP

                        // if everything copied/attached properly, clean
                        // up splash and exit to Xflash
                        wrapUp();   
                    }
                    else
                    {
                        // if they database exists copied to the phone, but failed
                        // to attach extra DBs for some reason or another
                        
                        // display an error dialog and exit
                        splashError(XFLASH_ATTACH_FAIL);
                    } 
                }
                catch (Exception e)
                {
                    Log.d(MYTAG,"Exception caught attaching DB:  " + e.toString() );
                }
                
            }  // end receive case DATABASE_READY

        }  // end onReceive()

    }  // end PracticeReceiver declaration


}  // end XflashSplash class declaration





