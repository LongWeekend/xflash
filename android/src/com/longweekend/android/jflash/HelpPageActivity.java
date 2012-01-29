package com.longweekend.android.jflash;

//  HelpPageActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/28/2012.
//  Copyright 2012 LONG WEEKEND INC.. All rights reserved.
//
//  public void onCreate()      @over
//
//  public void goBackToHelp(View  )
//  public void helpNext(View  ) 

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;
import android.content.res.Resources;
import android.util.Log;
import android.webkit.WebView;

public class HelpPageActivity extends Activity 
{
    private static final String MYTAG = "JFlash HelpPageActivity";
   
    private int helpTopic;
    private String[] topics;
    private String[] helpFiles;
    private WebView helpDisplay;
 
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.help_page);

        // accept bundle passed from parent Activity
        Bundle incoming = this.getIntent().getExtras();
        helpTopic = (int)incoming.getLong("help_topic");

        Resources res = getResources();
        
        // pull the topics to display the title
        // depending on whether we're in Jflash or Cflash
        if( com.longweekend.android.jflash.Jflash.IS_JFLASH )
        {
            topics = res.getStringArray(R.array.help_topics_japanese);
            helpFiles = res.getStringArray(R.array.help_files_japanese);
        }
        else
        {
            // topics = res.getStringArray(R.array.help_topics_chinese);
            // helpFiles = res.getStringArray(R.array.help_files_chinese);
        }

        
        // set the title bar
        TextView tempView = (TextView)findViewById(R.id.help_title);
        tempView.setText( topics[helpTopic] );         
    
        // TODO - couldn't disable zoom on WebView
        helpDisplay = (WebView)findViewById(R.id.help_display);
        
        // set the html body
        String localUrl = "file:///android_asset/JFlash/help/" + helpFiles[helpTopic];
        helpDisplay.loadUrl(localUrl);
    
    }  // end onCreate()


    // reset the content view to the main help screen
    public void goBackToHelp(View v)
    {
        finish();
    }
    
    // when the 'next' button is pressed
    public void helpNext(View v) 
    {
        // if we're not already at the last page
        if( helpTopic < ( helpFiles.length - 1 ) )
        {
            ++helpTopic;
           
            // change both the title bar and the page content
            TextView tempView = (TextView)findViewById(R.id.help_title);
            tempView.setText( topics[helpTopic] );

            String localUrl = "file:///android_asset/JFlash/help/" + helpFiles[helpTopic];
            helpDisplay.loadUrl(localUrl);
        }
    }


}  // end HelpPageActivity class declaration





