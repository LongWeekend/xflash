package com.longweekendmobile.android.xflash;

//  ReminderFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//

// TODO - need to add functionality so user can change the number
//      - of days for the reminder setting

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class ReminderFragment extends Fragment
{
    // private static final String MYTAG = "XFlash ReminderFragment";
   
    TextView reminderValue = null;
    
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        LinearLayout reminderLayout = (LinearLayout)inflater.inflate(R.layout.reminder, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)reminderLayout.findViewById(R.id.reminder_heading);
        XflashSettings.setupColorScheme(titleBar); 

        // set the text for the reminder setting
        reminderValue = (TextView)reminderLayout.findViewById(R.id.reminder_value);
        reminderValue.setText( XflashSettings.getReminderText() );

        // set the text for the reminder day count
        TextView tempView = (TextView)reminderLayout.findViewById(R.id.reminder_day_value);
        tempView.setText( Integer.toString( XflashSettings.getReminderCount() ) );

        RelativeLayout tempLayout = (RelativeLayout)reminderLayout.findViewById(R.id.reminder_toggle_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                toggleReminders();
            }
        });

        return reminderLayout;

    }  // end onCreateView()


    // toggle the reminder status on/off
    public void toggleReminders()
    {
        XflashSettings.toggleReminders();

        reminderValue.setText( XflashSettings.getReminderText() );

    }  // end toggleReminders()


}  // end ReminderFragment class declaration





