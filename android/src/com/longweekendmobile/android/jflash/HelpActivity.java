package com.longweekendmobile.android.jflash;

//  HelpActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//  public void onResume()      @over
//
//  public void goAskUs(View  )
//
//  private void pullHelpTopic(long  )
//  private void fireAskusDialog()

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class HelpActivity extends Activity 
{
    private static final String MYTAG = "JFlash HelpActivity";
    
    private int localColor;
    private AlertDialog askDialog;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.help);

        // if we're just starting up, force load of color
        localColor = -1;

        // set our popup dialog instance to null
        askDialog = null;

        Resources res = getResources();
        String[] topics;
        
        // set topics[] to strings defined in resources xml
        // depending on whether we're in Jflash or Cflash
        if( com.longweekendmobile.android.jflash.JFApplication.IS_JFLASH )
        {
            topics = res.getStringArray(R.array.help_topics_japanese);
        }
        else
        {
            topics = res.getStringArray(R.array.help_topics_chinese);
        }

        // pick up the child of our ScrollView so we can add rows
        LinearLayout myLayout = (LinearLayout)findViewById(R.id.help_list);
        LayoutInflater inflater = (LayoutInflater)this.getSystemService(Context.LAYOUT_INFLATER_SERVICE); 
        
        int totalTopics = topics.length;
        int rowCount = 0;
        for(int i = 0; i < totalTopics; i++)
        {
            // inflate our exiting row resource (which is a RelativeLayout) for each 
            // row and tag the view with the row number of each particular help topic
            RelativeLayout toInflate = (RelativeLayout)inflater.inflate(R.layout.help_row,null);
            toInflate.setTag(rowCount);
            ++rowCount;
            
            // set the label
            TextView tempView = (TextView)toInflate.findViewById(R.id.help_label);
            tempView.setText( topics[i] );            

            // add a click listener
            toInflate.setOnClickListener( new OnClickListener()
            {
                public void onClick(View v) 
                {
                    // local private HelpActivity.pullHelpTopic()
                    int tempInt = (Integer)v.getTag(); 
                    pullHelpTopic(tempInt);
                }

            });
 
            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                myLayout.addView(divider);
            }
            // add the new label/row to the LinearLayout (inside the ScrollView)
            myLayout.addView(toInflate);    
        
        } // end for loop
        
    }  // end onCreate()


    @Override
    public void onResume()
    {
        super.onResume();

        // set the background to the current color scheme
        if( localColor != JFApplication.ColorManager.getColorScheme() )
        {
            // load the title bar elements and pass them to the color manager
            RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.help_heading);
            Button tempButton = (Button)findViewById(R.id.help_askusbutton);
            
            JFApplication.ColorManager.setupScheme(titleBar,tempButton);
        }
    }

 
    // onClick method for the "ask us" button - pops a dialog
    public void goAskUs(View v)
    {
        fireAskusDialog();
    }

    // calls a new child activity for the Activity group
    private void pullHelpTopic(int inId)
    {
        // set the ListView id of the topic selected
        // Bundle helpTopic = new Bundle();
        // helpTopic.putLong("help_topic",inId);

        Intent myIntent = new Intent( getParent(), HelpPageActivity.class);
        myIntent.putExtra("help_topic",inId);

        // call the main ActivityGroup of the Help tab,
        // ask it to start our Intent
        HelpActivityGroup parentActivity = (HelpActivityGroup)getParent();
        parentActivity.startChildActivity("HelpPageActivity", myIntent);
    }

    
    // TODO - this no longer works in the multitab scenario
    // set up all objects and listeners for the "ask us" dialog
    private void fireAskusDialog() {

        AlertDialog.Builder builder;

        // inflate the dialog layout into a View object
        LayoutInflater inflater = (LayoutInflater)this.getSystemService(LAYOUT_INFLATER_SERVICE);
        View layout = inflater.inflate(R.layout.askus_dialog, (ViewGroup)findViewById(R.id.askus_root));

        builder = new AlertDialog.Builder( getParent() );
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

    }  // end fireAskusDialog()


}  // end HelpActivity class declaration


