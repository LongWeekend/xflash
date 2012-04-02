package com.longweekendmobile.android.xflash;

//  UserFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  private void drawUserList()
//  private void activateUser(View  )
//  private void editUser(View  )
//  private void deleteUser(View  )

import java.util.ArrayList;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.res.Resources;
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
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.User;
import com.longweekendmobile.android.xflash.model.UserPeer;

public class UserFragment extends Fragment
{
    private static final String MYTAG = "XFlash UserFragment";
   
    private ArrayList<User> userList;
    private LinearLayout userListLayout;
    private LayoutInflater myInflater;

    private int switchUser;
    
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        myInflater = inflater;
        
        // inflate our layout for the HelpPage fragment
        LinearLayout userLayout = (LinearLayout)inflater.inflate(R.layout.user, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)userLayout.findViewById(R.id.user_heading);
        ImageButton addUserButton = (ImageButton)userLayout.findViewById(R.id.user_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,addUserButton); 

        // set a click listener for the add user button
        addUserButton.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                editUser(v);
            }
        });

        // populate the user list
        userListLayout = (LinearLayout)userLayout.findViewById(R.id.user_list);
        drawUserList();

        return userLayout;

    }  // end onCreateView()


    // draws the user list
    private void drawUserList()
    {
        // load the users from DB and display
        userList = UserPeer.getUsers();
       
        int numUsers = userList.size();
        int tempCurrentUser = XflashSettings.getCurrentUserId();

        // add the layout for each user
        for(int i = 0; i < numUsers; i++)
        {
            int tempId = userList.get(i).getUserId();

            // inflate our exiting row resource
            RelativeLayout userRow = (RelativeLayout)myInflater.inflate(R.layout.user_row,null);

            // set the label, tag it with our display row id, and set a click listener
            TextView tempView = (TextView)userRow.findViewById(R.id.user_label);
            tempView.setTag(i);
            tempView.setText( userList.get(i).getUserNickname() );

            tempView.setOnClickListener(activateListener);
            tempView.setOnLongClickListener(userLongClick);
       
            // tag the edit button with the user id, set a click listener
            tempView = (TextView)userRow.findViewById(R.id.user_editbutton);
            tempView.setTag(tempId);
            tempView.setOnClickListener(editListener); 
            
            // set the background/edit button based on whether this is our active user
            if( tempId == tempCurrentUser )
            {
                tempView.setTextColor(0xFFFFFFFF);
                
                // set background based on row
                if( i == 0 )
                {
                    // top row, top corners rounded
                    userRow.setBackgroundResource(R.drawable.userrow_selected_top);
                }
                else if( i == ( numUsers - 1 ) )
                {
                    // bottom row, bottom corners rounded
                    userRow.setBackgroundResource(R.drawable.userrow_selected_bottom);
                }
                else
                {
                    // middle row, no corners rounded
                    userRow.setBackgroundResource(R.drawable.userrow_selected);
                }
            
            }  // end if( this is the current user )
            
            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)myInflater.inflate(R.layout.divider,null);
                userListLayout.addView(divider);
            }
            
            // add the new label/row to the LinearLayout (inside the ScrollView)
            userListLayout.addView(userRow);
                
        }  // end for loop

    }  // end drawUserList()


    // fires the alert to change the active user
    private void activateUser(View v)
    {
        int tempIndex = (Integer)v.getTag();
        String tempName = userList.get(tempIndex).getUserNickname();
       
        // if they clicked to activate the already active user, do nothing
        if( userList.get(tempIndex).getUserId()  == XflashSettings.getCurrentUserId() )
        {
            return;
        } 

        // set a class property so the AlertDialog knows which user was clicked
        switchUser = userList.get(tempIndex).getUserId();
        
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );
        builder.setTitle("Activate User");
        builder.setMessage("Set the active user to " + tempName + "?");
        
        // on postive response, set the new active user
        builder.setPositiveButton( Xflash.getActivity().getResources().getString(R.string.just_ok) , 
                                   new DialogInterface.OnClickListener()
        {
            public void onClick(DialogInterface dialog,int which)
            {
                // set the new user
                XflashSettings.setCurrentUserId(switchUser);
                
                // reset the active Tag to the new user
                Tag activeTag = XflashSettings.getActiveTag();
                activeTag.populateCards();
                activeTag.setCurrentIndex(0);
                
                // TODO - kind of a hack, we're using an active tag broadcast to
                //      - get practice to reset its current study counts.  But 
                //      - that shouldn't be a problem, because no no else is
                //      - listening for that notification
                XFApplication.getNotifier().activeTagBroadcast();
                
                // return to settings
                Xflash.getActivity().onScreenTransition("settings",XflashScreen.DIRECTION_CLOSE);
            }
        });
        
        // on negative response, do nothing
        builder.setNegativeButton("Cancel",null);

        builder.create().show();

    }  // end activateUser()


    private void editUser(View v)
    {
        // set up EditUserFragment for whether we're editing or adding
        if( v.getId() == R.id.user_addbutton )
        {
            EditUserFragment.setNew(true);
        }
        else
        {
            // set EditUserFragment.incomingEditId to the user id we tagged to this
            // row's editbutton
            EditUserFragment.loadUser( (Integer)v.getTag() ); 
        } 

        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_EDIT_USER);
        Xflash.getActivity().onScreenTransition("edit_user",XflashScreen.DIRECTION_OPEN); 

    }  // end editUser()


    private void deleteUser(View v)
    {
        final int userRowIndex = (Integer)v.getTag();
        final User tempUser = userList.get(userRowIndex);

        Resources res = Xflash.getActivity().getResources();

        // quick exit if they are trying to delete the default user
        // or the active user
        if( ( tempUser.getUserId() == XflashSettings.LWE_DEFAULT_USER ) ||
            ( tempUser.getUserId() == XflashSettings.getCurrentUserId() ) )
        {
            XflashAlert.deleteUserError(tempUser);

            return;
        }

        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );
        builder.setTitle( res.getString(R.string.user_deleteuser_title) );
        builder.setMessage( res.getString(R.string.user_deleteuser_message) + " \"" + tempUser.getUserNickname() + "\"?");

        // on postive response, delete the user
        builder.setPositiveButton( res.getString(R.string.just_ok), new DialogInterface.OnClickListener()
        {
            public void onClick(DialogInterface dialog,int which)
            {
                // remove the user from the database
                tempUser.deleteUser();
                
                // redraw the user list view
                userListLayout.removeAllViews();
                    drawUserList();
            }
        });

        // on negative response, do nothing
        builder.setNegativeButton("Cancel",null);

        builder.create().show();

    }  // end deleteUser()


    // click listener for the user row edit button
    private View.OnClickListener editListener = new View.OnClickListener()
    {
        @Override
        public void onClick(View v)
        {
            editUser(v);
        }
    };

    // click listener for the user row - activates user
    private View.OnClickListener activateListener = new View.OnClickListener()
    {
        @Override
        public void onClick(View v)
        {
            activateUser(v);
        }
    };

    // a long-click listener for deletion of user tags
    private View.OnLongClickListener userLongClick = new View.OnLongClickListener()
    {
        @Override
        public boolean onLongClick(View v)
        {
            deleteUser(v);

            // consume the long-click event
            return true;
        }
    };


}  // end UserFragment class declaration





