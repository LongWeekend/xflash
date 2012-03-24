package com.longweekendmobile.android.xflash;

//  UserFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  private void activateUser(View  )
//  private void editUser(View  )

import java.util.ArrayList;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.User;
import com.longweekendmobile.android.xflash.model.UserPeer;

public class UserFragment extends Fragment
{
    // private static final String MYTAG = "XFlash UserFragment";
   
    private ArrayList<User> userList;
    private LinearLayout userListLayout;

    private int switchUser;
    
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
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

        // load the users from DB and display
        userList = UserPeer.getUsers();
        userListLayout = (LinearLayout)userLayout.findViewById(R.id.user_list);
       
        int numUsers = userList.size();
        int tempCurrentUser = XflashSettings.getCurrentUserId();

        // add the layout for each user
        for(int i = 0; i < numUsers; i++)
        {
            int tempId = userList.get(i).getUserId();

            // inflate our exiting row resource
            RelativeLayout userRow = (RelativeLayout)inflater.inflate(R.layout.user_row,null);

            // set the label, tag it with our display row id, and set a click listener
            TextView tempView = (TextView)userRow.findViewById(R.id.user_label);
            tempView.setTag(i);
            tempView.setText( userList.get(i).getUserNickname() );
            tempView.setOnClickListener(activateListener);
       
            // tag the edit button with the user id, set a click listener
            tempView = (TextView)userRow.findViewById(R.id.user_editbutton);
            tempView.setTag(tempId);
            tempView.setOnClickListener(editListener); 
            
            // set the background/edit button based on whether this is our active user
            if( tempId == tempCurrentUser )
            {
                userRow.setBackgroundResource(R.color.selected_row);
                tempView.setTextColor(0xFFFFFFFF);
            }
            
            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                userListLayout.addView(divider);
            }
            
            // add the new label/row to the LinearLayout (inside the ScrollView)
            userListLayout.addView(userRow);
                
        }  // end for loop
       
        return userLayout;

    }  // end onCreateView()


    // fires the alert to change the active user
    public void activateUser(View v)
    {
        int tempIndex = (Integer)v.getTag();
        String tempName = userList.get(tempIndex).getUserNickname();
        
        // if they clicked to activate the already active user, do nothing
        if( ( tempIndex + 1) == XflashSettings.getCurrentUserId() )
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
                // set the new user and return to settings
                XflashSettings.setCurrentUserId(switchUser);
                Xflash.getActivity().onScreenTransition("settings",XflashScreen.DIRECTION_CLOSE);
            }
        });
        
        // on negative response, do nothing
        builder.setNegativeButton("Cancel",null);

        builder.create().show();

    }  // end activateUser()


    public void editUser(View v)
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


}  // end UserFragment class declaration





