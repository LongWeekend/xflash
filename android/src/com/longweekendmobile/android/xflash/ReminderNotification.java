package com.longweekendmobile.android.xflash;

//  ReminderNotification.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public ReminderNotification()
//
//  public void setupReminder()
//  public void fireReminder()

// note - this method has generally been deprecated in favor of using
//      - a Notification.Builder object to construct notifications, 
//      - however it is not available until API 11 and is not
//      - included in the compatibility pack

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;

public class ReminderNotification
{
    private static final int reminderId = 0;
    
    private Notification reminderNotification;
    private Context myContext;
    
    public ReminderNotification(Context inContext)
    {
        myContext = inContext;

    }  // end constructor()


    // initialzie a reminder object
    public void setupReminder()
    {
        Resources res = myContext.getResources();
        
        // create our PendingIntent to launch Xflash if clicked in
        // the expanded notification
        Intent xflashIntent = new Intent( myContext, XflashSplash.class);
        PendingIntent launchXflash = PendingIntent.getActivity( myContext, 0, xflashIntent, PendingIntent.FLAG_ONE_SHOT);
        
        int icon = R.drawable.reminder;
        String ticker = res.getString(R.string.reminder_ticker);

        // create the notification object - see note above
        reminderNotification = new Notification(icon, ticker, System.currentTimeMillis() );

        String title = res.getString(R.string.reminder_title);
        String content = res.getString(R.string.reminder_content);
        
        // TODO - insert code to change to user-defined number of days to wait
        content = content.replace("##NUMDAYS##","4");

        // define the expanded notification behavior - see note above
        reminderNotification.setLatestEventInfo(myContext, title, content, launchXflash);

        reminderNotification.flags = Notification.FLAG_AUTO_CANCEL;

    }  // end setupReminder()


    // display the reminder in the status bar
    public void fireReminder()
    {
        NotificationManager mgr = (NotificationManager)myContext.getSystemService(Context.NOTIFICATION_SERVICE);

        mgr.notify(reminderId,reminderNotification);

    }  // end fireReminder()


}  // end ReminderNotification class declaration


