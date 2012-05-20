package com.longweekendmobile.android.xflash;

//  XflashSplash.java
//  XFlash
//
//  Created by Todd Presson on 2/4/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate(Bundle  )          @over
//
//  private void tossPreferences()          - debugging
//
//  public void clickPhone(View  )
//  public void clickSD(View  )
//  public void exitApp(View  )
//
//  private void startPhone()
//  private void startSD()
//  private int megsFree(File  ) 
//  private void showSplash2()
//  private void wrapUp()
//  private void splashError(boolean  )
//  private void turnOnReceiver()
//
//  protected class SplashReceiver extends BroadcastReceiver
//
//      public void onReceive(Context  ,Intent  )
//
//  private Thread splashThread1
//  private Thread splashThread2

import java.io.File;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.os.Bundle;
import android.os.Environment;
import android.os.StatFs;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.LWEDatabase;

public class XflashSplash extends Activity
{
    private static final String MYTAG = "XFlash XflashSpalsh";

    private static final boolean isDebugging = false;
    private static final int XFLASH_COPY_FAIL = 0;
    private static final int XFLASH_ATTACH_FAIL = 1;
    private static final int XFLASH_NO_SDCARD = 2;

    private final Activity myContext = this;
    private SplashReceiver myReceiver;

    // properties for managing the splash delay
    private int splashTime;
    
    // also for debugging
    private LinearLayout DBupdateLayout; 
    private LinearLayout DBtargetLayout;

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        // TODO - debugging, uncomment to wipe preferences after uninstall
        // tossPreferences();

        // set background to splash1 (Long Weekend label)
        setContentView(R.layout.splash);
        
        boolean noSDproblems = true;

        // set the splash delay based on whether we're debugging
        if( isDebugging )
        {
            splashTime = 200;
        }
        else
        {
            splashTime = 1200;
        } 

        turnOnReceiver();

        // initialize the dao based on database location
        int DBstatus = LWEDatabase.getDBStatus(); 
       
        // if this is their first run, ask where they would
        // like to copy/install the databases
        if( DBstatus == LWEDatabase.DATABASE_NO_EXIST )
        {
            DBtargetLayout = (LinearLayout)findViewById(R.id.select_db_target);
            DBtargetLayout.setVisibility(View.VISIBLE);

            // get free space for internal phone storage
            File tempFile = Environment.getDataDirectory();
            int phoneMegsFree = megsFree(tempFile);
            
            // show the user how much space they have (phone)
            TextView phoneFreeView = (TextView)findViewById(R.id.db_phonespace);
            phoneFreeView.setText( Integer.toString(phoneMegsFree) );

            // get free space for the SD card

            // note: this number is NOT the total space free on the SD card,
            //       rather it is the amount of space free for use in the
            //       app-specific directories that will also be cleared
            //       on uninstall.  Will that just confuse users?  Should we 
            //       check THIS number, but DISPLAY the full SD storage?
            tempFile = myContext.getExternalFilesDir(null);
            int sdMegsFree = 0;
            
            // get our external media state
            boolean sd = Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED);

            TextView sdFreeView = (TextView)findViewById(R.id.db_sdspace);
            if( sd )
            {
                // show the user how much space they have (SD card)
                sdMegsFree = megsFree(tempFile);
                sdFreeView.setText( Integer.toString(sdMegsFree) );
            }
            else
            {
                // that means the SD card is unavailable
                sdFreeView.setText("not found");
            }

            // turn off buttons if there isn't enough space to use them
            if( phoneMegsFree < 130 )
            {
                Button phoneButton = (Button)findViewById(R.id.dbtarget_phone_button);
                phoneButton.setEnabled(false);

                phoneFreeView.setTextColor(0xFFFF5555);
            }
            
            // counts for "not found" also, since sdMegsFree was
            // initialized to 0
            if( sdMegsFree < 130 )
            {
                Button sdButton = (Button)findViewById(R.id.dbtarget_sd_button);
                sdButton.setEnabled(false);

                sdFreeView.setTextColor(0xFFFF5555);
            }

            // set the body text
            TextView bodyText = (TextView)findViewById(R.id.db_target_body);
            if( ( phoneMegsFree < 130 ) && ( sdMegsFree < 130 ) )
            {
                // if they're out of space, say so
                bodyText.setText( getResources().getString(R.string.db_target_nospace) ); 

                // hide the target button block
                LinearLayout chooseBlock = (LinearLayout)findViewById(R.id.db_choose_block);
                chooseBlock.setVisibility(View.GONE);

                // show the OK button to exit
                Button noSpaceButton = (Button)findViewById(R.id.db_nospace_button);
                noSpaceButton.setVisibility(View.VISIBLE);
            }
            else
            {
                // if they DO have adequate space to install
                bodyText.setText( getResources().getString(R.string.db_target_explain) ); 
            }
        }
        else
        {
            // if the databases are installed, initialize
            if( DBstatus == LWEDatabase.DATABASE_PHONE )
            {
                startPhone();
            }
            else
            {
                // if our databases are on the SD card, make sure it's 
                // available for use
                noSDproblems = Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED);

                if( noSDproblems )
                {
                    // if we're good to go, initialize to the SD card
                    startSD();
                }
                else
                {
                    // if we can't get the card, alert user and exit
                    splashError(XFLASH_NO_SDCARD);
                }
            }
        
            // code catch to stop the app from starting 
            // LWEDatabase.asynchCopy...() while we're displaying a fatal
            // error to the user
            if( noSDproblems )
            {
                // and pause the flash screen
                splashThread1.start();
            }
        }

    }  // end onCreate()

    
    // TODO - debugging, wipe preferences
    private void tossPreferences()
    {
        // set the new color in the Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.clear();
        editor.commit();

        throw new RuntimeException("tossed");

    }  // end tossPreferences()

    // install the databases on the phone's internal memory
    public void clickPhone(View v)
    {
        DBtargetLayout.setVisibility(View.GONE);
        
        startPhone();
        showSplash2();

    }  // end clickPhone()

    
    // install the databases on the SD card internal memory
    public void clickSD(View v)
    {
        DBtargetLayout.setVisibility(View.GONE);
        
        startSD();
        showSplash2();

    }  // end clickSD()

    
    // exit the app because something failed
    public void exitApp(View v)
    {
        myContext.unregisterReceiver(myReceiver);
        finish();
    }

    
    // initialize the DAO to the phone's local storage
    private void startPhone()
    {
        XFApplication.initializeDaoPhone();
        XFApplication.getDao().setLocation(LWEDatabase.DATABASE_PHONE);
    }


    // initialize the DAO to the SD card
    private void startSD()
    {
        XFApplication.initializeDaoSDcard();
        XFApplication.getDao().setLocation(LWEDatabase.DATABASE_SDCARD);
    }


    // returns the number of MB available in the data storage
    // unit containing the path pointed to by inFile
    private int megsFree(File inFile) 
    {
        StatFs stat = new StatFs( inFile.getPath() );

        long bytesFree = (long)stat.getBlockSize() * (long)stat.getAvailableBlocks();
        
        return (int)( bytesFree / (1024 * 1024) );

    }  // end megsFree()

    
    // change splash screens, check the database (install if necessary)
    private void showSplash2()
    {
        // reset splash background to splash2 (Xflash label)
        RelativeLayout myLayout = (RelativeLayout)findViewById(R.id.splashback);
        myLayout.setBackgroundResource(R.drawable.splash2);
      
        boolean databaseIsInstalled = XFApplication.getDao().checkDatabase();

        // only display the loading screen if we need to copy databases
        if( !databaseIsInstalled )
        {
            // nab the loading view 
            RelativeLayout loadBack = (RelativeLayout)findViewById(R.id.loading_splash_frame);
            loadBack.setVisibility(View.VISIBLE);

            // pull a layout for our Receiver to add views to as it
            // gets updates from the DAO copy
            DBupdateLayout = (LinearLayout)findViewById(R.id.load_messages);
            
            // check if our databases have been copied,
            // copy them if they haven't
            XFApplication.getDao().asynchCopyDatabaseFromAPK();
        }
        else
        {
            wrapUp();
        }

    }  // end showSplash2()

   
    // clean up splash and exit to Xflash
    private void wrapUp()
    {
        splashThread2.start();
    
    }  // end wrapUp()


    // handles informing user of a fatal error relating to database initialization
    private void splashError(int inError)
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
        else if( inError == XFLASH_NO_SDCARD )
        {
            builder.setTitle( res.getString(R.string.nosd_title) );
            builder.setMessage( res.getString(R.string.nosd_body) );
        }

        // exit the app when they're done
        builder.setPositiveButton( res.getString(R.string.just_ok), new DialogInterface.OnClickListener()
        {
            public void onClick(DialogInterface dialog,int which)
            {
                exitApp(null);
            }
        });

        // show error dialog and exit the app
        builder.create().show();

    }  // end splashError()

 
    // turn on our BroadcastReceiver
    private void turnOnReceiver()
    {
        IntentFilter intentFilter;
        myReceiver = new SplashReceiver();

        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START2);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START3);
        registerReceiver(myReceiver,intentFilter);
            
        intentFilter = new IntentFilter(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START4);
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
            tempView.setTextColor(0xFFFFFFFF);
        
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
            else if( intent.getAction().equals(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START3))
            {
                tempView.setText("Copying db 3...");                                
                DBupdateLayout.addView(tempView);
            }
            else if( intent.getAction().equals(com.longweekendmobile.android.xflash.model.LWEDatabase.COPY_START4))
            {
                tempView.setText("Copying db 4...");                                
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
                    boolean firedUp = tempDB.attachDatabase(LWEDatabase.DB_CARD);
   
                    if( firedUp )
                    {
                        tempView.setText("Database attached");
                        DBupdateLayout.addView(tempView);
            
                        tempView = new TextView(myContext);
                        tempView.setTextSize((float)16);
                        tempView.setTextColor(0xFFFFFFFF);
            
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


    // start a thread to pause the first screen for [splashtime] milliseconds
    // when it terminates, it calls showSplash2()
    private Thread splashThread1 = new Thread()
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
                        showSplash2();
                    }
                };

                // run on UI thread to have access to view elements
                runOnUiThread(newRunnable);
            }
        }

    };  // end splashThread1 declaration


    // start a thread to pause the first screen for [splashtime] milliseconds
    private Thread splashThread2 = new Thread()
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
            }
        }

    };  // end splashThread2 declaration


}  // end XflashSplash class declaration





