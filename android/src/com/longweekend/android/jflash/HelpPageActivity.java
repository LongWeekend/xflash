package com.longweekend.android.jflash;

//  HelpPageActivity.java
//  jFlash
//
//  Created by Todd Presson on 1/28/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//
//  public void goBackToHelp(View  )
//  public void helpNext(View  ) 

import android.app.Activity;
import android.content.res.Resources;
import android.os.Bundle;
import android.view.View;
import android.webkit.WebView;
import android.widget.TextView;
import android.util.Log;

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

        // accept extra passed from parent Activity
        helpTopic = this.getIntent().getIntExtra("help_topic",-1);

        Resources res = getResources();
        
        // pull the topics to display the title
        // depending on whether we're in Jflash or Cflash
        if( com.longweekend.android.jflash.JFApplication.IS_JFLASH )
        {
            topics = res.getStringArray(R.array.help_topics_japanese);
            helpFiles = res.getStringArray(R.array.help_files_japanese);
        }
        else
        {
            topics = res.getStringArray(R.array.help_topics_chinese);
            helpFiles = res.getStringArray(R.array.help_files_chinese);
        }

        // set the title bar
        TextView tempView = (TextView)findViewById(R.id.help_title);
        tempView.setText( topics[helpTopic] );         
    
        // get our WebView and disable pinch zoom
        helpDisplay = (WebView)findViewById(R.id.help_display);
        helpDisplay.getSettings().setSupportZoom(false); 

        // set the html body
        String localUrl = "file:///android_asset/JFlash/help/" + helpFiles[helpTopic];
        helpDisplay.loadUrl(localUrl);
        
        // WebView background must be set to transparency
        // programatically or it won't work (known bug Android 2.2.x and up)
        helpDisplay.setBackgroundColor(0x00000000);

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





