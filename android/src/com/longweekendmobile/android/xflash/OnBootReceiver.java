package com.longweekendmobile.android.xflash;

//  OnBootReceiver.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  a receiver called on device boot to reset any necessary
//  study reminder alarms

// TODO - need to create functionality to reset our alarm to an approriate
//      - time, based on when it was initially set.

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

public class OnBootReceiver extends BroadcastReceiver 
{
    private static final String MYTAG = "XFlash OnBootReceiver";
  
    @Override
    public void onReceive(Context context, Intent intent) 
    {
        Log.d(MYTAG,">>> Inside boot receiver for study reminders");
        
        // get a Context, get the SharedPreferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        boolean remindersOn = settings.getBoolean("remindersOn",false);

        if( remindersOn )
        {
            Log.d(MYTAG,">   The reminders are set to on, but we aren't doing anything!");
        }

    }  // end onReceive()

}  // end OnAlarmReceiver class decleartion
