package com.longweekendmobile.android.xflash;

//  TagFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void addToplevelTag(Context  )
//  public static void openGroup(View  ,Xflash  )
//  public static void goAllCards(View  ,Xflash  )
//  public static void startStudying(View  ,Xflash  )
//  public static void fireEmptyTagDialog(Xflash  )

import java.util.ArrayList;

import android.app.AlertDialog;
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
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Group;
import com.longweekendmobile.android.xflash.model.GroupPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class TagFragment extends Fragment
{
    private static final String MYTAG = "XFlash TagFragment";
   
    private LinearLayout tagLayout;
    public static Group currentGroup = null;
    
    
    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, 
                             Bundle savedInstanceState) 
    {
        // inflate our layout for the Tag fragment and load our icon array
        tagLayout = (LinearLayout)inflater.inflate(R.layout.tag, container, false);
        int icons[] = XflashSettings.getIcons();

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)tagLayout.findViewById(R.id.tag_heading);
        ImageButton tempButton = (ImageButton)tagLayout.findViewById(R.id.tag_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,tempButton);
    
        // populate the main list of groups
        LinearLayout tempList = (LinearLayout)tagLayout.findViewById(R.id.main_group_list);
        RelativeLayout tempRow = null;
        ImageView tempRowImage = null;
        TextView tempView = null;
        
        // if the TagFragment is not set to a specific group, load top level
        if( currentGroup == null )
        {
            currentGroup = GroupPeer.topLevelGroup();
        }

        // set the title bar to the current group/tag
        tempView = (TextView)tagLayout.findViewById(R.id.tag_heading_text);
        tempView.setText( currentGroup.getGroupName() );

        // pull and display any groups owned by currentGroup
        ArrayList<Group> groupArray = GroupPeer.retrieveGroupsByOwner( currentGroup.getGroupId() );

        int rowCount = groupArray.size();
        for(int i = 0; i < rowCount; i++)
        {
            Group tempGroup = groupArray.get(i);
            
            tempRow = (RelativeLayout)inflater.inflate(R.layout.group_row,null);
            tempRow.setTag( tempGroup.getGroupId() );
      
            // set the group image
            tempRowImage = (ImageView)tempRow.findViewById(R.id.group_row_image);
            if( tempGroup.getRecommended() == 1 )
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_SPECIAL_FOLDER ] ); 
            }
            else
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_FOLDER ] ); 
            }


            // set the group title
            tempView = (TextView)tempRow.findViewById(R.id.group_row_top);
            tempView.setText( tempGroup.getGroupName() );

            // set the group set count
            StringBuilder tempBuilder = new StringBuilder();

            int tempInt = tempGroup.getChildGroupCount();
            if( tempInt > 0 )
            {
                tempBuilder.append(tempInt).append(" groups,  "); 
            }
            tempBuilder.append( tempGroup.getTagCount() ).append(" sets");
   
            tempView = (TextView)tempRow.findViewById(R.id.group_row_bottom);
            tempView.setText( tempBuilder.toString() );

            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                tempList.addView(divider);
            }
            tempList.addView(tempRow);

        }  // end for loop


        // pull and display any tags for currentGroup
        tempList = (LinearLayout)tagLayout.findViewById(R.id.main_tag_list);
        ArrayList<Tag> tagArray = currentGroup.childTags();
        rowCount = tagArray.size();

        // shuffle 'my starred words' to the top
        // TODO - I feel like there must be a better way to do this
        for(int i = 0; i < rowCount; i++)
        {
            Tag shuffleTag = tagArray.get(i);

            if( shuffleTag.getId() != Tag.STARRED_TAG_ID )
            {
                tagArray.remove(shuffleTag);
                tagArray.add(shuffleTag);
            }
        }

        for(int i = 0; i < rowCount; i++)
        {
            Tag tempTag = tagArray.get(i);
            
            tempRow = (RelativeLayout)inflater.inflate(R.layout.tag_row,null);
            tempRow.setTag( tempTag.getId() );
      
            // set the group image
            tempRowImage = (ImageView)tempRow.findViewById(R.id.tag_row_image);

            if( tempTag.getId() == Tag.STARRED_TAG_ID )
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_STARRED_TAG] );
            }
            else
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_TAG] );
            }

            // set the tag title
            tempView = (TextView)tempRow.findViewById(R.id.tag_row_top);
            tempView.setText( tempTag.getName() );

            // set the group set count
            tempView = (TextView)tempRow.findViewById(R.id.tag_row_bottom);
            tempView.setText( Integer.toString( tempTag.getCardCount() ) + " words");

            // clear the 'view' option if there are no cards in the tag
            tempView = (TextView)tempRow.findViewById(R.id.tag_row_click);
            if( tempTag.getCardCount() < 1 )
            {
                tempView.setVisibility(View.INVISIBLE);
            }
            else
            {
                tempView.setTag( tempTag.getId() ); 
            }

            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                tempList.addView(divider);
            }
            tempList.addView(tempRow);

        }  // end for loop

        // only display backup block on root view
        LinearLayout backupBlock = (LinearLayout)tagLayout.findViewById(R.id.tag_backup_block);
        if( ( currentGroup != null ) && currentGroup.isTopLevelGroup() )
        {
            backupBlock.setVisibility(View.VISIBLE);
        }
        else
        {
            backupBlock.setVisibility(View.GONE);
        }

        return tagLayout;

    }  // end onCreateView()


    // onClick for our PLUS button
    public static void addToplevelTag(Context inContext)
    {
        // start the 'add tag' activity as a modal
        CreateTagActivity.setCurrentGroup(currentGroup);

        inContext.startActivity(new Intent(inContext,CreateTagActivity.class));
    }


    public static void openGroup(View v,Xflash inContext)
    {
        XflashScreen.addTagStack();
        
        currentGroup = GroupPeer.retrieveGroupById( (int)(Integer)v.getTag() );
        
        inContext.onScreenTransition("tag",XflashScreen.DIRECTION_OPEN);
    }

    public static void goAllCards(View v,Xflash inContext)
    {
        int tempInt = (Integer)v.getTag();

        StudySetWordsFragment.setIncomingTagId(tempInt); 
        inContext.onScreenTransition("studyset_words",XflashScreen.DIRECTION_OPEN);
    }
    
    public static void startStudying(View v,Xflash inContext)
    {
        int incomingTagId = (Integer)v.getTag();
        Tag tempTag = TagPeer.retrieveTagById(incomingTagId);

        // if user is trying to open an empty tag
        if( tempTag.getCardCount() < 1 )
        {
            fireEmptyTagDialog(inContext);
        }
        else
        {
            Log.d(MYTAG,"start studying a tag!");
        }

    }  // end startStudying()

    
    public static void fireEmptyTagDialog(Xflash inContext)
    {
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder(inContext);

        String tempString = inContext.getResources().getString(R.string.emptyset_dialog_title);
        builder.setTitle(tempString);

        tempString = inContext.getResources().getString(R.string.emptyset_dialog_message);
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton("OK",null);
        
        builder.create().show();

    }  // end fireEmptyTagDialong()


}  // end TagFragment class declaration



