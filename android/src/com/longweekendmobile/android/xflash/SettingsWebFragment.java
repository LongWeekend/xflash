package com.longweekendmobile.android.xflash;

//  SettingsWebFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static LinearLayout getSettingsLayout()

import android.app.ProgressDialog;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.Toast;

public class SettingsWebFragment extends Fragment
{
    // private static final String MYTAG = "XFlash SettingsWebFragment";
    private static LinearLayout settingsWebLayout;
    private static WebView settingsWebDisplay;
    private static ProgressDialog loadDialog;
 
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
        // inflate our layout for the Settings activity
        settingsWebLayout = (LinearLayout)inflater.inflate(R.layout.settings_web, container, false);

        // set the title bar to the current color scheme
        // this Activity does not need the onResume check present in
        // all other activities, because this Activity will never
        // start with an unexpected color change
        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)settingsWebLayout.findViewById(R.id.settings_web_heading);
        Button tempButton = (Button)settingsWebLayout.findViewById(R.id.settings_web_reload);
 
        XflashSettings.setupColorScheme(titleBar,tempButton);
 
        // our loading ProgressDialog
        final ProgressDialog tempDialog = new ProgressDialog(getActivity());
        loadDialog = tempDialog;
        
        // get the WebView and display the appropriate web page
        settingsWebDisplay = (WebView)settingsWebLayout.findViewById(R.id.settings_web_display);
        settingsWebDisplay.getSettings().setJavaScriptEnabled(true);
        settingsWebDisplay.setWebViewClient( new WebViewClient()
        {
            public void onPageFinished(WebView view,String url)
            {
                loadDialog.dismiss();
            }
        });

        // display the loading ProgressDialog and load the web page requested, 
        // also called when reload button is pressed
        reload();

        return settingsWebLayout;

    }  // end onCreateView()


    // calls a new view activity for fragment tab layout 
    public static void reload()
    {
        String tempUrl = null;

        if( SettingsFragment.isTwitter )
        {
            tempUrl = "http://twitter.com/long_weekend/";
        }
        else
        {
            tempUrl = "http://m.facebook.com/pages/Japanese-Flash/111141367918";
        }

        // re-show the loading dialog and reload the webpage
        loadDialog.show();
        settingsWebDisplay.loadUrl(tempUrl);
    }


}  // end SettingsWebFragment class declaration




