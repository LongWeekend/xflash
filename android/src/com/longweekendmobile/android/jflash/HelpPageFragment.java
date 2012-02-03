package com.longweekendmobile.android.jflash;

//  HelpPageFragment.java
//  jFlash
//
//  Created by Todd Presson on 1/28/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//  public void onResume()                                              @over
//
//  public static LinearLayout getHelpPageLayout()
//  public static WebView getHelpDisplay()
//
//  public static int getNumTopics()
//  public static String getSingleTopic(int  )
//  public static String getSingleFilename(int  )
//
//  public static int getHelpTopic()
//  public static void setHelpTopic(int  )
//  public static void incrementHelpTopic()

import android.content.res.Resources;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class HelpPageFragment extends Fragment 
{
    // private static final String MYTAG = "JFlash HelpPageFragment";
   
    // properties for handling color theme transitions
    private int localColor;
    private static LinearLayout helpPageLayout;

    private static int helpTopic;
    private static String[] topics;
    private static String[] helpFiles;
    private static WebView helpDisplay;
 
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        // if we're just starting up, force load of color
        localColor = -1;
    }


    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Tag activity and return it
        helpPageLayout = (LinearLayout)inflater.inflate(R.layout.help_page, container, false);

        // Resources object necessary to pull help topics
        Resources res = getResources();
        
        // pull the topics to display the title
        // depending on whether we're in Jflash or Cflash
        if( com.longweekendmobile.android.jflash.JFApplication.IS_JFLASH )
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
        TextView tempView = (TextView)helpPageLayout.findViewById(R.id.help_page_title);
        tempView.setText( topics[helpTopic] );         
    
        // get our WebView and disable pinch zoom
        helpDisplay = (WebView)helpPageLayout.findViewById(R.id.help_display);
        helpDisplay.getSettings().setSupportZoom(false); 
        helpDisplay.setHorizontalScrollBarEnabled(false);

        // set the html body
        String localUrl = "file:///android_asset/JFlash/help/" + helpFiles[helpTopic];
        helpDisplay.loadUrl(localUrl);
        
        // WebView background must be set to transparency
        // programatically or it won't work (known bug Android 2.2.x and up)
        helpDisplay.setBackgroundColor(0x00000000);
        
        return helpPageLayout;
    }


    @Override
    public void onResume()
    {
        super.onResume();

        // set the background to the current color scheme
        if( localColor != JFApplication.ColorManager.getColorScheme() )
        {
            // load the title bar elements and pass them to the color manager
            RelativeLayout titleBar = (RelativeLayout)helpPageLayout.findViewById(R.id.help_page_heading);
            Button tempButton1 = (Button)helpPageLayout.findViewById(R.id.help_backbutton);
            Button tempButton2 = (Button)helpPageLayout.findViewById(R.id.help_nextbutton);
 
            JFApplication.ColorManager.setupScheme(titleBar,tempButton1,tempButton2); 
        }
    }


    // helper methods so the page can be updated from the onClick
    // method in Jflash
    public static LinearLayout getHelpPageLayout()
    {
        return helpPageLayout;
    }

    public static WebView getHelpDisplay()
    {
        return helpDisplay;
    }
    public static int getNumTopics()
    {
        return topics.length;
    }

    public static String getSingleTopic(int inTopic)
    {
        return topics[inTopic];
    } 

    public static String getSingleFilename(int inFilename)
    {
        return helpFiles[inFilename];
    } 

    public static int getHelpTopic()
    {
        return helpTopic;
    }

    public static void setHelpTopic(int inTopic)
    {
        helpTopic = inTopic;
    }

    public static void incrementHelpTopic()
    {
        ++helpTopic;
    }



}  // end HelpPageFragment class declaration




