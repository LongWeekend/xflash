package com.longweekendmobile.android.xflash;

//  EditUserFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void setNew(boolean  )
//  public static void loadUser(int  )
//
//  private void setSaveButton()
//  private void select()
//  private void save()

import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.text.Editable;
import android.text.TextWatcher;
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
   
    // incoming properties set by UserFragment via static methods
    private static boolean isNew;
    private static int incomingEditId = 1;
    
    private EditText myEdit;
    private Button saveButton;
    
    // if we're editing, the user and previous nickname for the user selected
    private User myUser;
    private String oldName;
 

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        LinearLayout editUserLayout = (LinearLayout)inflater.inflate(R.layout.edit_user, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)editUserLayout.findViewById(R.id.edit_user_heading);
        XflashSettings.setupColorScheme(titleBar); 
        
        // load our save button and add a click listener
        saveButton = (Button)editUserLayout.findViewById(R.id.edituser_savebutton);
        saveButton.setOnClickListener( new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                save();
            }
        });
        
        // set the fragment label based on whether we're adding or editing
        TextView editLabel = (TextView)editUserLayout.findViewById(R.id.edit_user_label); 
        Button setButton = (Button)editUserLayout.findViewById(R.id.edituser_selectbutton);
        myEdit = (EditText)editUserLayout.findViewById(R.id.edit_user_text);
        
        if( isNew )
        {
            // if we're adding a NEW user
            String tempTitle = getActivity().getResources().getString(R.string.new_user_title);
            editLabel.setText(tempTitle);
            
            setButton.setVisibility(View.INVISIBLE);
        }
        else
        {
            // we're editing an EXISTING user, grab the user name
            myUser = UserPeer.getUserByPK(incomingEditId);
 
            // set a click listener for the select button
            setButton.setOnClickListener( new View.OnClickListener()
            {
                @Override
                public void onClick(View v)
                {
                    select();
                }
            });

            // get the name of the user we are modifying
            oldName = myUser.getUserNickname();

            editLabel.setText(oldName); 
            myEdit.setText(oldName);
            
            // add a text-changed listener to the EditText
            myEdit.addTextChangedListener(editListener);
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

    
    // methods called by UserFragment to set the incoming state
    // immediately before transitioning to EditUserFragment
    public static void setNew(boolean inNew)
    {
        isNew = inNew;
    }

    public static void loadUser(int inEdit)
    {
        incomingEditId = inEdit;
        isNew = false;
    }


    // sets the save button as visible/invisible depending on whether changes
    // have been made to the name
    private void setSaveButton()
    {
        if( isNew )
        {
            return;
        }
        
        String tempString = myEdit.getText().toString();
        
        // if the entered content does NOT match the starting
        // name, display the save button
        if( tempString.compareTo(oldName) != 0 )
        {
            saveButton.setVisibility(View.VISIBLE);
        }
        else
        {
            saveButton.setVisibility(View.INVISIBLE);
        }

    }  // end setSaveButton()


    // when the user clicks the 'select' button
    private void select()
    {
        // set the user and return to the UserFragment
        XflashSettings.setCurrentUserId(incomingEditId);

        save();
    }

    // when the user clicks the 'save' button
    private void save()
    {
        // pull the content of the EditText
        String tempString = myEdit.getText().toString();
            
        // save the user, depending on whether they're new
        if( isNew )
        {
            myUser = UserPeer.createUserWithNickname(tempString);
        }
        else
        {
            myUser.setUserNickname(tempString);
            myUser.save();
        } 

        Xflash myContext = Xflash.getActivity();
        
        // close the soft keyboard
        InputMethodManager keyboard = (InputMethodManager)myContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        keyboard.hideSoftInputFromWindow(myEdit.getWindowToken(),0);

        // return to UserFragment
        XflashScreen.setCurrentSettingsType(XflashScreen.LWE_SETTINGS_USER);
        myContext.onScreenTransition("user",XflashScreen.DIRECTION_CLOSE);

    }  // end save()

    
    // listener for the search bar EditText
    private TextWatcher editListener = new TextWatcher()
    {
        public void onTextChanged(CharSequence text, int start, int lengthBefore, int lengthAfter)
        {
            // necessary stub
        }

        public void beforeTextChanged(CharSequence text, int start, int count, int after)
        {
            // necessary stub
        }

        public void afterTextChanged(Editable text)
        {
            setSaveButton();
        }

    };  // end editListener declaration


}  // end EditUserFragment class declaration





