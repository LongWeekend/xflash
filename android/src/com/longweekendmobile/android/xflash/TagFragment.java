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
//  public static void goTagCards(View  ,Xflash  )
//  public static void startStudying(View  ,Xflash  )
//  public static void fireEmptyTagDialog(Xflash  )
//  public static void refreshTagList()

import java.util.ArrayList;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnLongClickListener;
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
   
    private static FragmentActivity myContext = null;
    
    public static Group currentGroup = null;
    private static LinearLayout tagList = null;
   
 
    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, 
                             Bundle savedInstanceState) 
    {
        myContext = getActivity();

        // inflate our layout for the Tag fragment and load our icon array
        LinearLayout tagLayout = (LinearLayout)inflater.inflate(R.layout.tag, container, false);
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

        }  // end for loop (groups)


        // pull and display any tags for currentGroup
        tagList = (LinearLayout)tagLayout.findViewById(R.id.main_tag_list);
        refreshTagList();

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


    // a long-click listener for deletion of user tags
    private static OnLongClickListener userTagLongClick = new OnLongClickListener() 
    {
        @Override
        public boolean onLongClick(View v) 
        {
            final int tempInt = (Integer)v.getTag();
            final Tag tempTag = TagPeer.retrieveTagById(tempInt);

            // set and fire our AlertDialog
            AlertDialog.Builder builder = new AlertDialog.Builder(myContext);
            builder.setTitle("Delete Tag?");
            builder.setMessage("Are you sure you want to delete the study set \"" + tempTag.getName() + "\"?");

            // on postive response, set the new active user
            builder.setPositiveButton("OK", new DialogInterface.OnClickListener()
            {
                public void onClick(DialogInterface dialog,int which)
                {
                    TagPeer.deleteTag(tempTag);
                    
                    // TODO - adjust this to just remove the single view
                    refreshTagList();
                }
            });

            // on negative response, do nothing
            builder.setNegativeButton("Cancel",null);

            builder.create().show();

            return true;
        }

    };  // end OnLongClickListener declaration 


    // onClick for our PLUS button
    public static void addToplevelTag(Context inContext)
    {
        // start the 'add tag' activity as a modal
        CreateTagActivity.setWhoIsCalling(CreateTagActivity.TAG_FRAGMENT_CALLING);
        CreateTagActivity.setCurrentGroup(currentGroup);

        inContext.startActivity(new Intent(inContext,CreateTagActivity.class));
    }


    public static void openGroup(View v,Xflash inContext)
    {
        XflashScreen.addTagStack();
        
        currentGroup = GroupPeer.retrieveGroupById( (int)(Integer)v.getTag() );
        
        inContext.onScreenTransition("tag",XflashScreen.DIRECTION_OPEN);
    }

    public static void goTagCards(View v,Xflash inContext)
    {
        int tempInt = (Integer)v.getTag();

        TagCardsFragment.setIncomingTagId(tempInt); 
        inContext.onScreenTransition("tag_cards",XflashScreen.DIRECTION_OPEN);
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


    // pull and display any tags for currentGroup
    public static void refreshTagList()
    {
        LayoutInflater inflater = (LayoutInflater)myContext.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        int icons[] = XflashSettings.getIcons();

        // clear views on reload
        tagList.removeAllViews();

        // TODO - I feel like there MUST be a better way to do this
        ArrayList<Tag> rawTagArray = currentGroup.childTags();
        ArrayList<Tag> userTagArray = new ArrayList<Tag>();
        
        // the ArrayList we will actually use to populate the view
        ArrayList<Tag> shuffleArray = new ArrayList<Tag>();
        
        // shuffle 'my starred words' to the top, user tags to the bottom
        int rowCount = rawTagArray.size();
        for(int i = 0; i < rowCount; i++)
        {
            Tag shuffleTag = rawTagArray.get(i);

            // add the starred words tag at the start
            if( shuffleTag.getId() == Tag.STARRED_TAG_ID )
            {
                shuffleArray.add(0,shuffleTag);
            }
            else
            {
                // if it is a system tag, add it straight to
                // the shuffle array, otherwise hold on to it
                if( shuffleTag.isEditable() )
                {
                    userTagArray.add(shuffleTag);
                }
                else
                {
                    shuffleArray.add(shuffleTag);
                }
            }
        }

        // add user tags back in at the bottom
        rowCount = userTagArray.size();
        if( rowCount > 0 )
        {
            for(int i = 0; i < rowCount; i++)
            {
                shuffleArray.add( userTagArray.get(i) );
            } 
        }

        // now the ArrayList of tags to views, add to the layout
        rowCount = shuffleArray.size();
        for(int i = 0; i < rowCount; i++)
        {
            Tag tempTag = shuffleArray.get(i);
            
            RelativeLayout tempRow = (RelativeLayout)inflater.inflate(R.layout.tag_row,null);
            tempRow.setTag( tempTag.getId() );
     
            // if this is a user tag, set a long-click listener for deletion
            if( tempTag.isEditable() )
            {
                tempRow.setOnLongClickListener(userTagLongClick);
            }
 
            // set the group image
            ImageView tempRowImage = (ImageView)tempRow.findViewById(R.id.tag_row_image);

            if( tempTag.getId() == Tag.STARRED_TAG_ID )
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_STARRED_TAG] );
            }
            else
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_TAG] );
            }

            // set the tag title
            TextView tempView = (TextView)tempRow.findViewById(R.id.tag_row_top);
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
                tagList.addView(divider);
            }
            tagList.addView(tempRow);

        }  // end for loop 

    }  // end refreshTagList()


}  // end TagFragment class declaration



