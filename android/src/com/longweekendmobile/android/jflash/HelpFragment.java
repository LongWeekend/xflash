package com.longweekendmobile.android.jflash;

//  HelpFragment.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//  public void onResume()                                              @over
//
//  public static AlertDialog getDialog()
//  public static void setDialog(AlertDialog  )

import android.app.AlertDialog;
import android.content.res.Resources;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class HelpFragment extends Fragment
{
    // private static final String MYTAG = "JFlash HelpFragment";
    
    // properties for handling color theme transition
    private int localColor;
    private LinearLayout helpLayout;
 
    private static AlertDialog askDialog;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        // if we're just starting up, force load of color
        localColor = -1;

        // set our popup dialog instance to null
        askDialog = null;
    } 


    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Tag activity and return it
        helpLayout = (LinearLayout)inflater.inflate(R.layout.help, container, false);

        // Resources object to pull our help topics
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
        LinearLayout myLayout = (LinearLayout)helpLayout.findViewById(R.id.help_list);
        
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
                    int tempInt = (Integer)v.getTag(); 
                    
                    Jflash.HelpFragment_pullHelpTopic(tempInt);
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

        return helpLayout;

    }  // end onCreateView

    @Override
    public void onResume()
    {
        super.onResume();

        // set the background to the current color scheme
        if( localColor != JFApplication.ColorManager.getColorScheme() )
        {
            // load the title bar elements and pass them to the color manager
            RelativeLayout titleBar = (RelativeLayout)helpLayout.findViewById(R.id.help_heading);
            Button tempButton = (Button)helpLayout.findViewById(R.id.help_askusbutton);
            
            JFApplication.ColorManager.setupScheme(titleBar,tempButton);
        }
        
    }


    // return the Dialog object for manipulation
    public static AlertDialog getDialog()
    {
        return askDialog;
    }

    public static void setDialog(AlertDialog inDialog)
    {
        askDialog = inDialog;
    }

}  // end HelpFragment class declaration



