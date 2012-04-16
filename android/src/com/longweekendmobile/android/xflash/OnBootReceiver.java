package com.longweekendmobile.android.xflash;

//  OnBootReceiver.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  a receiver called on device boot to reset any necessary
//  study reminder alarms

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

public class OnBootReceiver extends BroadcastReceiver 
{
    // private static final String MYTAG = "XFlash OnBootReceiver";
  
    @Override
    public void onReceive(Context context, Intent intent) 
    {
        // get a Context, get the SharedPreferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        boolean remindersOn = settings.getBoolean("remindersOn",false);

        // if we have a reminder to set, do so
        if( remindersOn )
        {
            long alarmTime = settings.getLong("alarmTime",(long)-1);

            if( alarmTime > 0 )
            {
                // create an PendingIntent for our alarm
                Intent myIntent = new Intent(context, OnAlarmReceiver.class);
                PendingIntent alarmIntent = PendingIntent.getBroadcast(context, 0, myIntent, PendingIntent.FLAG_ONE_SHOT);

                // get the phone's alarm manager
                AlarmManager aMgr = (AlarmManager)context.getSystemService(Context.ALARM_SERVICE);
                aMgr.set(AlarmManager.RTC, alarmTime, alarmIntent);
            }
            
        }

    }  // end onReceive()


}  // end OnAlarmReceiver class decleartion






