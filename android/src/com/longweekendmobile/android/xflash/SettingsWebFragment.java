package com.longweekendmobile.android.xflash;

//  SettingsWebFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void setPage(int inPage)
//
//  private void reload()

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

public class SettingsWebFragment extends Fragment
{
    // private static final String MYTAG = "XFlash SettingsWebFragment";
    
    private WebView settingsWebDisplay;
    private ProgressDialog loadDialog;
 
    private static int currentPage = 0;

    
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Settings activity
        LinearLayout settingsWebLayout = (LinearLayout)inflater.inflate(R.layout.settings_web, container, false);

        // get the title bar and reload button and set them to the color theme
        RelativeLayout titleBar = (RelativeLayout)settingsWebLayout.findViewById(R.id.settings_web_heading);
        Button reloadButton = (Button)settingsWebLayout.findViewById(R.id.settings_web_reload);
        
        XflashSettings.setupColorScheme(titleBar,reloadButton);
        
        // set a click listener for the reload button
        reloadButton.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                reload();
            }
        });

        // our loading ProgressDialog
        final ProgressDialog tempDialog = new ProgressDialog(getActivity());
        loadDialog = tempDialog;
        loadDialog.setMessage(" Loading... ");
        
        // get the WebView and set it to kill the dialog when it's ready
        settingsWebDisplay = (WebView)settingsWebLayout.findViewById(R.id.settings_web_display);
        settingsWebDisplay.getSettings().setJavaScriptEnabled(true);
        settingsWebDisplay.setWebViewClient( new WebViewClient()
        {
            public void onPageFinished(WebView view,String url)
            {
                loadDialog.dismiss();
            }
        });

        // display the loading ProgressDialog and load the web page requested
        reload();

        return settingsWebLayout;

    }  // end onCreateView()


    public static void setPage(int inPage)
    {
        currentPage = inPage;
    }


    // loads the WebView depending on currentPage
    private void reload()
    {
        String tempUrl = null;

        if( currentPage == SettingsFragment.LOAD_TWITTER )
        {
            tempUrl = Xflash.getActivity().getResources().getString(R.string.lwe_twitter_url);
        }
        else
        {
            tempUrl = Xflash.getActivity().getResources().getString(R.string.lwe_facebook_url);
        }

        // re-show the loading dialog and reload the webpage
        loadDialog.show();
        settingsWebDisplay.loadUrl(tempUrl);

    }  // end reload()


}  // end SettingsWebFragment class declaration




