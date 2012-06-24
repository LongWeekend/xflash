package com.longweekendmobile.android.xflash;

//  ReminderFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public void toggleReminders()
//
//  private class SpinnerListener implements AdapterView.OnItemSelectedListener 

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.Spinner;
import android.widget.TextView;

public class ReminderFragment extends Fragment
{
    private static final String MYTAG = "XFlash ReminderFragment";
   
    private TextView reminderValue = null;
    private Spinner daySpinner = null;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Reminder fragment
        LinearLayout reminderLayout = (LinearLayout)inflater.inflate(R.layout.reminder, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)reminderLayout.findViewById(R.id.reminder_heading);
        XflashSettings.setupColorScheme(titleBar); 

        // set the text for the reminder setting
        reminderValue = (TextView)reminderLayout.findViewById(R.id.reminder_value);
        reminderValue.setText( XflashSettings.getReminderText() );

        // set a click listener to toggle reminders
        RelativeLayout tempLayout = (RelativeLayout)reminderLayout.findViewById(R.id.reminder_toggle_block);
        tempLayout.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                toggleReminders();
            }
        });

        // array for reminder days spinner values (1-10)
        String[] spinnerValues = new String[10];
        for(int i = 1; i <= 10; i++)
        {
            spinnerValues[i - 1] = Integer.toString(i);
        }

        // create the adapter for our spinner to use
        ArrayAdapter<String> aa = new ArrayAdapter<String>( Xflash.getActivity(), android.R.layout.simple_spinner_item, spinnerValues);
        aa.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        
        // get the spinner
        daySpinner = (Spinner)reminderLayout.findViewById(R.id.day_spinner);
        
        // set everything up for the spinner (adapter, starting position, listener)
        daySpinner.setAdapter(aa);
        daySpinner.setSelection( ( XflashSettings.getReminderCount() - 1), false );
        daySpinner.setOnItemSelectedListener( new SpinnerListener() );

        // if the reminders are already set to off, disable the spinner
        if( !XflashSettings.getRemindersOn() )
        {
            daySpinner.setEnabled(false);
        }

        return reminderLayout;

    }  // end onCreateView()


    // toggle the reminder status on/off
    public void toggleReminders()
    {
        XflashSettings.toggleReminders();
        reminderValue.setText( XflashSettings.getReminderText() );

        // toggle whether the spinner is available
        if( XflashSettings.getRemindersOn() )
        {
            daySpinner.setEnabled(true);
        }
        else
        {
            daySpinner.setEnabled(false);
        }

    }  // end toggleReminders()


    // selection listener to set a new reminder count
    private class SpinnerListener implements AdapterView.OnItemSelectedListener 
    {
        public void onItemSelected(AdapterView<?> parent,View view, int pos, long id) 
        {
            int countToSet = (int)( id + 1 );
            
            XflashSettings.setReminderCount(countToSet);
        }

        public void onNothingSelected(AdapterView<?> parent) 
        {
            // do nothing
        }

    }  // end SpinnerListener class declaration


}  // end ReminderFragment class declaration





