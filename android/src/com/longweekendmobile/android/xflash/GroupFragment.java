package com.longweekendmobile.android.xflash;

//  GroupFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void addToplevelTag(Context  )

import java.util.ArrayList;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.ImageView;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Group;
import com.longweekendmobile.android.xflash.model.GroupPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class GroupFragment extends Fragment
{
    private static final String MYTAG = "XFlash GroupFragment";
   
    private LinearLayout groupLayout;
    
    // an array of drawable IDs for the icons, populated 
    // dynamically based on the current color scheme
    private int icons[];


    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, 
                             Bundle savedInstanceState) 
    {
        // inflate our layout for the Group fragment and load our icon array
        groupLayout = (LinearLayout)inflater.inflate(R.layout.group, container, false);
        icons = XflashSettings.getIcons();

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)groupLayout.findViewById(R.id.group_heading);
        ImageButton tempButton = (ImageButton)groupLayout.findViewById(R.id.group_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,tempButton);
    
        // populate the main list of groups
        LinearLayout groupList = (LinearLayout)groupLayout.findViewById(R.id.main_group_list);
        RelativeLayout tempRow = null;
        ImageView tagRowImage = null;
        TextView tempView = null;
        
        // pull system-owned groups
        ArrayList<Group> groupArray = GroupPeer.retrieveGroupsByOwner(0);

        int tempInt = groupArray.size();
        for(int i = 0; i < tempInt; i++)
        {
            Group tempGroup = groupArray.get(i);
            
            tempRow = (RelativeLayout)inflater.inflate(R.layout.tag_row,null);
            tempRow.setTag( tempGroup.getGroupId() );
      
            // set the group image
            tagRowImage = (ImageView)tempRow.findViewById(R.id.tag_row_image);
            if( tempGroup.getRecommended() == 1 )
            {
                tagRowImage.setImageResource( icons[XflashSettings.LWE_ICON_SPECIAL_FOLDER ] ); 
            }
            else
            {
                tagRowImage.setImageResource( icons[XflashSettings.LWE_ICON_FOLDER ] ); 
            }


            // set the group title
            tempView = (TextView)tempRow.findViewById(R.id.tag_row_top);
            tempView.setText( tempGroup.getGroupName() );

            // set the group set count
            tempView = (TextView)tempRow.findViewById(R.id.tag_row_bottom);
            tempView.setText( Integer.toString( tempGroup.getTagCount() ) + " sets");

            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                groupList.addView(divider);
            }
            groupList.addView(tempRow);
        }

        groupList = (LinearLayout)groupLayout.findViewById(R.id.fav_tag_list);

        // display the 'My Starred Words' tag
        tempRow = (RelativeLayout)inflater.inflate(R.layout.tag_row,null);
    
        // set the image
        tagRowImage = (ImageView)tempRow.findViewById(R.id.tag_row_image);
        tagRowImage.setImageResource( icons[XflashSettings.LWE_ICON_STARRED_TAG ] ); 
         
        // set the tag label
        tempView = (TextView)tempRow.findViewById(R.id.tag_row_top);
        tempView.setText("My Starred Words");
    
        // set the tag information
        tempView = (TextView)tempRow.findViewById(R.id.tag_row_bottom);
        tempView.setTextColor(0xFFFF0000);
        tempView.setText("NOT IMPLEMENTED");

        groupList.addView(tempRow);

        // display the 'Long Weekend Favorites' tag
        tempRow = (RelativeLayout)inflater.inflate(R.layout.tag_row,null);
        Tag tempTag = TagPeer.retrieveTagById(124);
 
        // set the image
        tagRowImage = (ImageView)tempRow.findViewById(R.id.tag_row_image);
        tagRowImage.setImageResource( icons[XflashSettings.LWE_ICON_TAG ] ); 
         
        // set the tag label
        tempView = (TextView)tempRow.findViewById(R.id.tag_row_top);
        tempView.setText( tempTag.getName() );
    
        // set the tag information
        tempView = (TextView)tempRow.findViewById(R.id.tag_row_bottom);
        tempView.setText( Integer.toString( tempTag.getCardCount() ) + " Words");

        groupList.addView(tempRow);


 
        return groupLayout;

    }  // end onCreateView()


    // onClick for our PLUS button
    public static void addToplevelTag(Context inContext)
    {
        // start the 'add tag' activity as a modal
        inContext.startActivity(new Intent(inContext,CreateTagActivity.class));
    }

}  // end GroupFragment class declaration


