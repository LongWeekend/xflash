package com.longweekend.android.jflash;

//  HelpActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 LONG WEEKEND INC.. All rights reserved.

import android.app.AlertDialog;
import android.app.ListActivity;
import android.content.Intent;
import android.content.res.Resources;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;

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

        Resources res = getResources();
        String[] topics;
        
        // set the ListActivity to strings defined in resources xml
        // depending on whether we're in Jflash or Cflash
        if( com.longweekend.android.jflash.Jflash.IS_JFLASH )
        {
            topics = res.getStringArray(R.array.help_topics_japanese);
        }
        else
        {
            // topics = res.getStringArray(R.array.help_topics_chinese);
        }

        setListAdapter(new ArrayAdapter<String>(this,R.layout.help_row,
                                                R.id.help_label,topics));
        askDialog = null;

    }  // end onCreate()

    
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

        // set the "Visit Site" button 
        Button tempButton = (Button)askDialog.findViewById(R.id.sitebutton);
        tempButton.setOnClickListener( new OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                Intent myIntent = new Intent(Intent.ACTION_VIEW,
                    Uri.parse("http://getsatisfaction.com/longweekend")); 
                
                startActivity(myIntent); 
                
                // dismiss, so we'll return to the overall help screen
                HelpActivity.this.askDialog.dismiss();
            }
        });    

        // set the "Send Email" button 
        tempButton = (Button)askDialog.findViewById(R.id.emailbutton);
        tempButton.setOnClickListener( new OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                Intent myIntent  = new Intent(Intent.ACTION_SEND);
                myIntent.putExtra(android.content.Intent.EXTRA_EMAIL, new String[]{ "support@longweekendmobile.com" });
                myIntent.putExtra(android.content.Intent.EXTRA_SUBJECT,"Please make this awesome.");
                
                // I believe this is the current email MIME?
                myIntent.setType("message/rfc5322"); 
 
                startActivity(myIntent);
                
                // dismiss, so we'll return to the overall help screen
                HelpActivity.this.askDialog.dismiss();
            }
        });    

        // set the "No Thanks" button
        tempButton = (Button)askDialog.findViewById(R.id.closebutton);
        tempButton.setOnClickListener( new OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                HelpActivity.this.askDialog.dismiss();
            }
        });    

    }  // end goAskUs()



}  // end HelpActivity class declaration


