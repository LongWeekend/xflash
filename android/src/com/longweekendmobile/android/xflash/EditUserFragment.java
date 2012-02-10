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
import android.util.Log;

public class EditUserFragment extends Fragment
{
    private static final String MYTAG = "XFlash EditUserFragment";
   
    // properties for handling color theme transitions
    private static LinearLayout editUserLayout;
    private EditText myEdit;
 
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

        myEdit = (EditText)editUserLayout.findViewById(R.id.edit_user_text);
        
        // set the fragment label based on whether we're adding or editing
        if( UserFragment.isNew )
        {
            editLabel.setText("New User");
            Log.d(MYTAG,"Looking at a new one here");
        }
        else
        {
            editLabel.setText("Dummy User"); 
            myEdit.setText("Dummy User");
            Log.d(MYTAG,"this one is not new");
        }

        XflashSettings.setupColorScheme(titleBar); 

        myEdit.postDelayed( new Runnable()
        {
            @Override
            public void run()
            {
                // launch with the keyboard displayed
                myEdit.requestFocus();
                InputMethodManager keyboard = (InputMethodManager)getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                keyboard.showSoftInput(myEdit,0);
                Log.d(MYTAG,"JUST REQUESTED OPEN");
            }
        },300);
        
        return editUserLayout;
    }

}  // end EditUserFragment class declaration





