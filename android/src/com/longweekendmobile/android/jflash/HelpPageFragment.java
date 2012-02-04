package com.longweekendmobile.android.jflash;

//  HelpPageFragment.java
//  jFlash
//
//  Created by Todd Presson on 1/28/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
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
    private static LinearLayout helpPageLayout;

    private static int helpTopic;
    private static String[] topics;
    private static String[] helpFiles;
    private static NoHorizontalWebView helpDisplay;
 
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    }


    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        helpPageLayout = (LinearLayout)inflater.inflate(R.layout.help_page, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)helpPageLayout.findViewById(R.id.help_page_heading);
        Button tempButton1 = (Button)helpPageLayout.findViewById(R.id.help_backbutton);
        Button tempButton2 = (Button)helpPageLayout.findViewById(R.id.help_nextbutton);
 
        JFApplication.ColorManager.setupScheme(titleBar,tempButton1,tempButton2); 
        
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
    
        // get our (NoHorizontal)WebView and disable pinch zoom
        helpDisplay = (NoHorizontalWebView)helpPageLayout.findViewById(R.id.help_display);
        helpDisplay.getSettings().setSupportZoom(false); 
        helpDisplay.setHorizontalScrollBarEnabled(false);

        

        // set the html body
        String localUrl = "file:///android_asset/JFlash/help/" + helpFiles[helpTopic];
        helpDisplay.loadUrl(localUrl);
        
        // (NoHorizontal)WebView background must be set to transparency
        // programatically or it won't work (known bug Android 2.2.x and up)
        helpDisplay.setBackgroundColor(0x00000000);
        
        return helpPageLayout;
    }


    public static void setHelpTopic(int inTopic)
    {
        helpTopic = inTopic;
    }


    // when the 'next' button is pressed
    public static void helpNext()
    {
        // if we're not already at the last page
        if( helpTopic < ( topics.length - 1 ) )
        {
            ++helpTopic;

            // change both the title bar and the page content
            TextView tempView = (TextView)helpPageLayout.findViewById(R.id.help_page_title);
            tempView.setText( topics[helpTopic] );

            String localUrl = "file:///android_asset/JFlash/help/" + helpFiles[helpTopic];
            helpDisplay.loadUrl(localUrl);
        }

    }  // end HelpPageFragment_helpNext()


}  // end HelpPageFragment class declaration





