package com.longweekendmobile.android.xflash;

//  EditUserFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()                                              @over
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class EditUserFragment extends Fragment
{
    // private static final String MYTAG = "XFlash EditUserFragment";
   
    // properties for handling color theme transitions
    private static LinearLayout editUserLayout;
    
    
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    }


    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        editUserLayout = (LinearLayout)inflater.inflate(R.layout.edit_user, container, false);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)editUserLayout.findViewById(R.id.edit_user_heading);
        TextView editLabel = (TextView)editUserLayout.findViewById(R.id.edit_user_label); 

        final EditText myEdit = (EditText)editUserLayout.findViewById(R.id.edit_user_text);
        
        // set the fragment label based on whether we're adding or editing
        if( UserFragment.isNew )
        {
            editLabel.setText("New User");
        }
        else
        {
            editLabel.setText("Dummy User"); 
            myEdit.setText("Dummy User");
        }

        XflashSettings.setupColorScheme(titleBar); 

        // launch with the keyboard displayed
        myEdit.requestFocus();
        myEdit.postDelayed( new Runnable()
        {
            @Override
            public void run()
            {
                InputMethodManager keyboard = (InputMethodManager)getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                keyboard.showSoftInput(myEdit,0);
            }
        },300);

        return editUserLayout;
    }

}  // end EditUserFragment class declaration





