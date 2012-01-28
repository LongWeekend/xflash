package com.longweekend.android.jflash;

//  HelpActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 LONG WEEKEND INC.. All rights reserved.

import android.app.Dialog;
import android.app.AlertDialog;
import android.app.ListActivity;
import android.content.Context;
import android.content.res.Resources;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ArrayAdapter;

public class HelpActivity extends ListActivity
{
    private static final String MYTAG = "JFlash HelpActivity";
    
    // dialog object for our "ask us" button
    private AlertDialog askDialog;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.help);

        // set the ListActivity to strings defined in resources xml
        Resources res = getResources();
        String[] topics = res.getStringArray(R.array.help_topics);
        setListAdapter(new ArrayAdapter<String>(this,R.layout.help_row,
                                                R.id.help_label,topics));
    
        askDialog = null;
    }

    
    // onClick method for the "ask us" button - pops a dialog
    public void goAskUs(View v) {
        
        AlertDialog.Builder builder;

        // inflate the dialog layout into a View object
        LayoutInflater inflater = (LayoutInflater)this.getSystemService(LAYOUT_INFLATER_SERVICE);
        View layout = inflater.inflate(R.layout.askus_dialog, (ViewGroup)findViewById(R.id.askus_root));

        builder = new AlertDialog.Builder(this);
        builder.setView(layout);
            
        askDialog = builder.create();
        askDialog.show();

        // we cannot reference our buttons until after the dialog.show()
        // method has been called - otherwise they don't "exist"

        // set functionality for the "No Thanks" button
        Button closeButton = (Button)askDialog.findViewById(R.id.closebutton);
        closeButton.setOnClickListener(new OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                HelpActivity.this.askDialog.dismiss();
            }
        });    

    }  // end goAskUs()



}  // end HelpActivity class declaration


