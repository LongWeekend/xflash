package com.longweekendmobile.android.xflash;

//  UserFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void activateUser(View  ,Xflash  )
//  public static void editUser(View  ,Xflash  )

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
   
    // the view containing users
    private static LinearLayout userListLayout;

    private static ArrayList<User> userList;
    private static int switchUser;

    
    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        LinearLayout userLayout = (LinearLayout)inflater.inflate(R.layout.user, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)userLayout.findViewById(R.id.user_heading);
        ImageButton tempButton = (ImageButton)userLayout.findViewById(R.id.user_addbutton);
        XflashSettings.setupColorScheme(titleBar,tempButton); 

        // load the users from DB and display
        userList = UserPeer.getUsers();
        userListLayout = (LinearLayout)userLayout.findViewById(R.id.user_list);
       
        int numUsers = userList.size();
        int tempCurrentUser = XflashSettings.getCurrentUserId();

        // add the layout for each user
        for(int i = 0; i < numUsers; i++)
        {
            int tempId = userList.get(i).getUserId();

            // inflate our exiting row resource and tag the view with the user id
            RelativeLayout toInflate = (RelativeLayout)inflater.inflate(R.layout.user_row,null);
            toInflate.setTag(tempId);

            // set the label, and tag it with our display row id
            TextView tempView = (TextView)toInflate.findViewById(R.id.user_label);
            tempView.setText( userList.get(i).getUserNickname() );
            tempView.setTag(R.id.user_rowtag,i);
       
            // tag the edit button with the user id
            tempView = (TextView)toInflate.findViewById(R.id.user_editbutton);
            tempView.setTag(R.id.user_idtag,tempId);
 
            // set the background/edit button based on whether this is our active user
            if( tempId == tempCurrentUser )
            {
                toInflate.setBackgroundResource(R.color.selected_row);
                tempView.setTextColor(0xFFFFFFFF);
            }
            
            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                userListLayout.addView(divider);
            }
            
            // add the new label/row to the LinearLayout (inside the ScrollView)
            userListLayout.addView(toInflate);
                
        }  // end for loop
       
        return userLayout;

    }  // end onCreateView()


    // fires the alert to change the active user
    public static void activateUser(View v,Xflash incoming)
    {
        final Xflash inContext = incoming;
        int tempIndex = (Integer)v.getTag(R.id.user_rowtag);
        String tempName = userList.get(tempIndex).getUserNickname();
        
        // if they clicked to activate the already active user, do nothing
        if( ( tempIndex + 1) == XflashSettings.getCurrentUserId() )
        {
            return;
        } 

        // set a class property so the AlertDialog knows which user was clicked
        switchUser = userList.get(tempIndex).getUserId();
        
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder(inContext);
        builder.setTitle("Activate User");
        builder.setMessage("Set the active user to " + tempName + "?");
        
        // on postive response, set the new active user
        builder.setPositiveButton("OK", new DialogInterface.OnClickListener()
        {
            public void onClick(DialogInterface dialog,int which)
            {
                // set the new user and return to settings
                XflashSettings.setCurrentUserId(switchUser);
                inContext.onScreenTransition("settings",XflashScreen.DIRECTION_CLOSE);
            }
       });
        
        // on negative response, do nothing
        builder.setNegativeButton("Cancel",null);

        builder.create().show();

    }  // end activateUser()


    public static void editUser(View v,Xflash inContext)
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
            EditUserFragment.setIncomingEditId( (Integer)v.getTag(R.id.user_idtag) ); 
            EditUserFragment.setNew(false);
        } 

        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_EDIT_USER);
        inContext.onScreenTransition("edit_user",XflashScreen.DIRECTION_OPEN); 
    }


}  // end UserFragment class declaration





