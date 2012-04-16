package com.longweekendmobile.android.xflash;

//  OnAlarmReceiver.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  receiver to fire a reminder notification when queued by the
//  alarm service

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class OnAlarmReceiver extends BroadcastReceiver 
{
    @Override
    public void onReceive(Context context, Intent intent) 
    {
        ReminderNotification studyReminder = new ReminderNotification(context);

        // setup and fire our reminder notification
        studyReminder.setupReminder();
        studyReminder.fireReminder();
    }

}  // end OnAlarmReceiver class decleartion



