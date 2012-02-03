package com.longweekendmobile.android.jflash;

//  TagFragment.java
//  jFlash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//  public void onResume()                                              @over

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.ImageView;
import android.widget.TextView;

public class TagFragment extends Fragment
{
    // private static final String MYTAG = "JFlash TagFragment";
    
    // properties for handling color theme transitions
    private int localColor;
    private LinearLayout tagLayout;

    /** Called when the fragment is first created. */
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
        tagLayout = (LinearLayout)inflater.inflate(R.layout.tag, container, false);
       
        // populate the main list of tags
        LinearLayout tempTagList = (LinearLayout)tagLayout.findViewById(R.id.main_tag_list);

        RelativeLayout myTagRow = (RelativeLayout)inflater.inflate(R.layout.tag_row,null);
    
        ImageView tagRowImage = (ImageView)myTagRow.findViewById(R.id.tag_row_image);
        tagRowImage.setImageResource(R.drawable.folder_icon_red); 

        TextView tempView = (TextView)myTagRow.findViewById(R.id.tag_row_top);
        tempView.setText("Here is a tag title");
    
        tempView = (TextView)myTagRow.findViewById(R.id.tag_row_bottom);
        tempView.setText("12 sets?");

        tempTagList.addView(myTagRow);

        // populate the list of 'favorite' tags
        tempTagList = (LinearLayout)tagLayout.findViewById(R.id.fav_tag_list);

        myTagRow = (RelativeLayout)inflater.inflate(R.layout.tag_row,null);
    
        tagRowImage = (ImageView)myTagRow.findViewById(R.id.tag_row_image);
        tagRowImage.setImageResource(R.drawable.folder_icon_red); 
         
        tempView = (TextView)myTagRow.findViewById(R.id.tag_row_top);
        tempView.setText("Favorites tag title");
    
        tempView = (TextView)myTagRow.findViewById(R.id.tag_row_bottom);
        tempView.setText("2 sets?");


 
        return tagLayout;
    }

   
    @Override
    public void onResume()
    {
        super.onResume();

        // set the background to the current color scheme
        if( localColor != JFApplication.ColorManager.getColorScheme() )
        {
            // set the background to the current color scheme
            if( localColor != JFApplication.ColorManager.getColorScheme() )
            {
                // load the title bar elements and pass them to the color manager
                RelativeLayout titleBar = (RelativeLayout)tagLayout.findViewById(R.id.tag_heading);
                ImageButton tempButton = (ImageButton)tagLayout.findViewById(R.id.tag_addbutton);

                JFApplication.ColorManager.setupScheme(titleBar,tempButton);
            }
        }

    }  // end onResume()

    

}  // end TagFragment class declaration


