package com.longweekendmobile.android.xflash;

//  EditTagFragment.java
//  Xflash
//
//  Created by Todd Presson on 4/17/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over

import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Group;
import com.longweekendmobile.android.xflash.model.GroupPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class EditTagFragment extends Fragment
{
    private static final String MYTAG = "XFlash EditTagFragment";
   
    public static final boolean CREATE_ACTIVE = false; 
    public static final boolean EDIT_ACTIVE = true;

    private static FragmentActivity activityContext = null;
    
    private static int groupIdPassed;
    private static int cardIdPassed;
    
    // properties to be set externally before intializing this fragment,
    // necessary because it is possible to be called as both an Activity
    // and a Fragment simultaneously
    private static Tag activityTag;
    private static Tag fragmentTag;

    // working tag property
    private static Tag operatingTag;
    
    private EditText nameEdit;
    private EditText descriptionEdit;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the Settings activity
        LinearLayout editTagLayout = (LinearLayout)inflater.inflate(R.layout.edit_tag, container, false);

        // get the title bar and reload button and set them to the color theme
        RelativeLayout titleBar = (RelativeLayout)editTagLayout.findViewById(R.id.edit_tag_heading);
        XflashSettings.setupColorScheme(titleBar);
        
        // set our click listener for the tag name text
        nameEdit = (EditText)editTagLayout.findViewById(R.id.edit_tag_nametext);
        nameEdit.setOnEditorActionListener(editTagActionListener);

        // get the description EditText and set the same keyboardDone() listener
        descriptionEdit = (EditText)editTagLayout.findViewById(R.id.edit_tag_descriptiontext);
        descriptionEdit.setOnEditorActionListener(editTagActionListener);

        if( activityContext != null )
        {
            operatingTag = activityTag;
        }
        else
        {
            operatingTag = fragmentTag;
        }
        
        // set title text based on whether we are editing a Tag
        TextView titleText = (TextView)editTagLayout.findViewById(R.id.edittag_heading_text);
        if( operatingTag == null )
        {
            titleText.setText( Xflash.getActivity().getResources().getString(R.string.create_tag_title) );
        }
        else
        {
            titleText.setText( Xflash.getActivity().getResources().getString(R.string.update_tag_title) );

            // set content for the fields, since we are editing
            // an existing Tag
            nameEdit.setText( operatingTag.getName() );
            descriptionEdit.setText( operatingTag.getDescription() );
        }

        // launch with the keyboard displayed only if we're making a NEW Tag
        if( activityContext != null )
        {
            nameEdit.postDelayed( new Runnable()
            {
                @Override
                public void run()
                {
                    nameEdit.requestFocus();
                    InputMethodManager keyboard = (InputMethodManager)Xflash.getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                    keyboard.showSoftInput(nameEdit,0);
                }
            },300);
        }

        return editTagLayout;

    }  // end onCreateView()

    public static void setActivityContext(FragmentActivity inContext)
    {
        activityContext = inContext;
    }

    // set a tag we are editing
    public static void setTagToEdit(Tag inTag)
    {
        // set the working tag based on where we are calling from
        if( activityContext != null )
        {
            activityTag = inTag;
        }
        else
        {
            fragmentTag = inTag;
        }

    }  // end setTagToEdit()

    
    // simple setters for incoming data, since we cannot use Intent extras
    public static void setGroupId(int inId)
    {
        groupIdPassed = inId;
    }

    public static void setCardId(int inId)
    {
        cardIdPassed = inId;
    }
    
    
    // must be called by CreateTagActivity on exit to prevent multiple 
    // instances of the Fragment from malfunctioning
    public static void resetToFragment()
    {
        operatingTag = fragmentTag;
    }


    // called by the action listener on our EditText keyboard, when 'done' is pressed
    private void keyboardDone()
    {
        Group currentGroup = null;

        if( groupIdPassed == -100 )
        {
            Log.d(MYTAG,">>> no group passed");
        }
        else
        {
            currentGroup = GroupPeer.retrieveGroupById(groupIdPassed);
        }

        // get the name input
        String nameContent = nameEdit.getText().toString();

        // when they click 'done' on the keyboard, add the new Tag and exit
        if( nameContent.length() > 0 )
        {
            // get the description input
            String descriptionContent = descriptionEdit.getText().toString();

            if( operatingTag == null )
            {
                // create the new Tag in the database if we're called via Activity
                operatingTag = TagPeer.createTagNamed(nameContent, currentGroup, descriptionContent);
            }
            else
            {
                // save the existing Tag we are editing (called via Fragment)
                operatingTag.setName(nameContent);
                operatingTag.setDescription(descriptionContent);

                operatingTag.save();
            }

            // broadcast the creation of a new Tag, tagged with the id of the passed
            // card if 'this' was called from AddCardToTag
            XflashNotification theNotifier = XFApplication.getNotifier();

            theNotifier.setCardIdPassed(cardIdPassed);
            theNotifier.newTagBroadcast(operatingTag);
        }
        else
        {
            // they didn't have a tag name entered, so call the alert, but we have
            // to differentiate the Activity context of the modal from the 
            // FragmentActivity context of the Fragment-only status so the alert
            // dialog is shown in the correct view
            if( activityContext == null )
            {
                // they're inline, give them Xflash.this
                XflashAlert.fireNoTagNameDialog( (Context)Xflash.getActivity() );
            }
            else
            {
                // they're modal, give them the overlay Activity context
                XflashAlert.fireNoTagNameDialog( (Context)activityContext );
            }
        }

    }  // end keyboardDone()


    // the listener for when 'done' is clicked on the keyboard
    private TextView.OnEditorActionListener editTagActionListener = new TextView.OnEditorActionListener()
    {
        @Override
        public boolean onEditorAction(TextView v,int actionId,KeyEvent event)
        {
            if( actionId == EditorInfo.IME_ACTION_DONE )
            {
                keyboardDone();

                if( nameEdit.getText().toString().length() > 0 )
                {
                    // only close if they typed in a title 
                    if( activityContext != null )
                    {
                        // if we're running as a (modal) Activity, close it out
                        activityContext.finish();
                        activityContext = null;
                    }
                    else
                    {
                        // if we're running as a Fragment, use our tab-screen system
                        Xflash myContext = Xflash.getActivity();
                        
                        // hide the soft keyboard
                        InputMethodManager imm = (InputMethodManager)myContext.getSystemService(Context.INPUT_METHOD_SERVICE);
                        imm.hideSoftInputFromWindow(nameEdit.getWindowToken(),0);
                        imm.hideSoftInputFromWindow(descriptionEdit.getWindowToken(),0);
                        
                        // transition back to TagCardsFragment
                        myContext.onScreenTransition("tag_cards",XflashScreen.DIRECTION_CLOSE);
                    }
                }

                return true;

            }  // end if( DONE was clicked )

            // do not consume event if it wasn't 'done'
            return false;
        }

    };  // end editTagActionListener


}  // end EditTagFragment class declaration




