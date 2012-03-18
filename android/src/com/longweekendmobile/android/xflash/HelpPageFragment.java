package com.longweekendmobile.android.xflash;

//  HelpPageFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/28/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void setHelpTopic(int  )
//
//  private void goBackToHelp()
//  private void helpNext()

import android.content.res.Resources;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class HelpPageFragment extends Fragment 
{
    // private static final String MYTAG = "XFlash HelpPageFragment";
   
    private Button nextButton = null;
    private TextView helpPageTitle = null;

    private static int helpTopic;
    private String[] topics;
    private String[] helpFiles;
    private NoHorizontalWebView helpDisplay;
 

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        LinearLayout helpPageLayout = (LinearLayout)inflater.inflate(R.layout.help_page, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)helpPageLayout.findViewById(R.id.help_page_heading);
        nextButton = (Button)helpPageLayout.findViewById(R.id.help_nextbutton);

        XflashSettings.setupColorScheme(titleBar,nextButton); 
        
        // set a click listener for the next button
        nextButton.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                helpNext();
            }
        });

        
        // Resources object necessary to pull help topics
        Resources res = getResources();
        
        // pull the topics to display the title
        // depending on whether we're in Jflash or Cflash
        if( com.longweekendmobile.android.xflash.XFApplication.IS_JFLASH )
        {
            topics = res.getStringArray(R.array.help_topics_japanese);
            helpFiles = res.getStringArray(R.array.help_files_japanese);
        }
        else
        {
            topics = res.getStringArray(R.array.help_topics_chinese);
            helpFiles = res.getStringArray(R.array.help_files_chinese);
        }

        // if we're on the last topic, kill the 'next' button
        if( helpTopic == ( topics.length - 1 ) )
        {
            nextButton.setVisibility(View.INVISIBLE);
        }

        // set the title bar text to the current help topic
        helpPageTitle = (TextView)helpPageLayout.findViewById(R.id.help_page_title);
        helpPageTitle.setText( topics[helpTopic] );         
    
        // get our (NoHorizontal)WebView and disable pinch zoom
        helpDisplay = (NoHorizontalWebView)helpPageLayout.findViewById(R.id.help_display);
        helpDisplay.getSettings().setSupportZoom(false); 
        helpDisplay.setHorizontalScrollBarEnabled(false);

        // set the html body
        String localUrl = res.getString(R.string.help_topics_path) + helpFiles[helpTopic];
        helpDisplay.loadUrl(localUrl);
        
        // (NoHorizontal)WebView background must be set to transparency
        // programatically or it won't work (known bug Android 2.2.x and up)
        // see - http://code.google.com/p/android/issues/detail?id=14749
        helpDisplay.setBackgroundColor(0x00000000);
        
        return helpPageLayout;

    }  // end onCreateView()


    public static void setHelpTopic(int inTopic)
    {
        helpTopic = inTopic;
    }


    // when the 'next' button is pressed
    private void helpNext()
    {
        // if we're not already at the last page
        if( helpTopic < ( topics.length - 1 ) )
        {
            ++helpTopic;

            // change both the title bar and the page content
            helpPageTitle.setText( topics[helpTopic] );

            String localUrl = "file:///android_asset/JFlash/help/" + helpFiles[helpTopic];
            helpDisplay.loadUrl(localUrl);
        }

        // if we're on the last topic, kill the 'next' button
        if( helpTopic == ( topics.length - 1 ) )
        {
            nextButton.setVisibility(View.INVISIBLE);
        }

    }  // end helpNext()


}  // end HelpPageFragment class declaration





