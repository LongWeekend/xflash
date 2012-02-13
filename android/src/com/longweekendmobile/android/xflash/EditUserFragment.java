package com.longweekendmobile.android.xflash;

//  EditUserFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public void setSaveButton()
//  public static void select(Xflash  )
//  public static void save(Xflash  )
//  public static void setNew(boolean  )
//  public static void setIncomingEditId(int  )

import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.User;
import com.longweekendmobile.android.xflash.model.UserPeer;

public class EditUserFragment extends Fragment
{
    // private static final String MYTAG = "XFlash EditUserFragment";
   
    private static LinearLayout editUserLayout;
    
    private static boolean isNew;
    private static EditText myEdit;
    private Button saveButton;
    
    // if we're editing, the user id and previous nickname for the user selected
    private static int incomingEditId = 1;
    private static User myUser;
    private String oldName;
 

    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        editUserLayout = (LinearLayout)inflater.inflate(R.layout.edit_user, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)editUserLayout.findViewById(R.id.edit_user_heading);
        XflashSettings.setupColorScheme(titleBar); 
        
        TextView editLabel = (TextView)editUserLayout.findViewById(R.id.edit_user_label); 
        myEdit = (EditText)editUserLayout.findViewById(R.id.edit_user_text);
        Button setButton = (Button)editUserLayout.findViewById(R.id.edituser_selectbutton);
        saveButton = (Button)editUserLayout.findViewById(R.id.edituser_savebutton);
        
        // set the fragment label based on whether we're adding or editing
        if( isNew )
        {
            String tempTitle = getActivity().getResources().getString(R.string.new_user_title);
            editLabel.setText(tempTitle);
            setButton.setVisibility(View.INVISIBLE);
        }
        else
        {
            // grab the user name we are editing
            myUser = UserPeer.getUserByPK(incomingEditId);
 
            oldName = myUser.getUserNickname();
            editLabel.setText(oldName); 
            myEdit.setText(oldName);
        }

        setSaveButton();

        // launch with the keyboard displayed
        myEdit.postDelayed( new Runnable()
        {
            @Override
            public void run()
            {
                myEdit.requestFocus();
                InputMethodManager keyboard = (InputMethodManager)getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                keyboard.showSoftInput(myEdit,0);
            }
        },300);
        
        return editUserLayout;

    }  // end onCreateView()

    
    // sets the save button as visible/invisible depending on whether changes
    // have been made to the name
    public void setSaveButton()
    {
        String tempString = myEdit.getText().toString();

        // TODO - this is always coming back false and staying visible
        if( tempString != oldName )
        {
            saveButton.setVisibility(View.VISIBLE);
        }
        else
        {
            saveButton.setVisibility(View.INVISIBLE);
        }

    }  // end setSaveButton()


    // when the user clicks the 'select' button
    public static void select(Xflash inContext)
    {
        // set the user and return to the UserFragment
        XflashSettings.setCurrentUser(incomingEditId);

        // local EditUserFragment.save()
        save(inContext);
    }

    // when the user clicks the 'save' button
    public static void save(Xflash inContext)
    {
        // pull the content of the EditText
        String tempString = myEdit.getText().toString();
            
        // save the user, depending on whether they're new
        if( isNew )
        {
            myUser = UserPeer.createUserWithNickname(tempString,null);
        }
        else
        {
            myUser.setUserNickname(tempString);
            myUser.save();
        } 

        // close the soft keyboard
        InputMethodManager keyboard = (InputMethodManager)inContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        keyboard.hideSoftInputFromWindow(myEdit.getWindowToken(),0);

        // return to UserFragment
        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_USER);
        inContext.onScreenTransition("user",Xflash.DIRECTION_CLOSE);

    }  // end save()

    
    // methods called by UserFragment to set the incoming state
    // immediately before transitioning to EditUserFragment
    public static void setNew(boolean inNew)
    {
        isNew = inNew;
    }

    public static void setIncomingEditId(int inEdit)
    {
        incomingEditId = inEdit;
    }


}  // end EditUserFragment class declaration





