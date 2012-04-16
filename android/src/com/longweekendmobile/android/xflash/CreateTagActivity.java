package com.longweekendmobile.android.xflash;

//  CreateTagActivity.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate()      @over
//  public void onResume()      @over
//  public void onPause()       @over
//
//  public static void setCurrentGroup(Group  )
//
//  private void keyboardDone()

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.longweekendmobile.android.xflash.model.Group;
import com.longweekendmobile.android.xflash.model.GroupPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class CreateTagActivity extends Activity
{
    private static final String MYTAG = "XFlash CreateTagActivity";
   
    private static Tag tagToEdit;
    private EditText nameEdit;
    private EditText descriptionEdit;
 
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.create_tag);
    
        // set our click listener for the tag name text and request focus
        nameEdit = (EditText)findViewById(R.id.create_tag_nametext);
        nameEdit.setOnEditorActionListener(createTagActionListener);

        // get the description EditText and set the same keyboardDone() listener
        descriptionEdit = (EditText)findViewById(R.id.create_tag_descriptiontext);
        descriptionEdit.setOnEditorActionListener(createTagActionListener);

        // launch with the keyboard displayed
        nameEdit.postDelayed( new Runnable() 
        {
            @Override
            public void run() 
            {
                nameEdit.requestFocus();
                InputMethodManager keyboard = (InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE);
                keyboard.showSoftInput(nameEdit,0);
            }
        },300);

    }  // end onCreate()

    
    @Override
    public void onResume()
    {
        super.onResume();
        overridePendingTransition(R.anim.slidein_bottom,R.anim.hold);

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)findViewById(R.id.create_tag_heading);
        XflashSettings.setupColorScheme(titleBar);

        TextView titleText = (TextView)findViewById(R.id.createtag_heading_text);

        // set title text based on whether we are editing a Tag
        if( tagToEdit == null )
        {
            titleText.setText( getResources().getString(R.string.create_tag_title) );
        }
        else
        {
            titleText.setText( getResources().getString(R.string.update_tag_title) );

            // set content for the fields, since we are editing
            // and existing Tag
            nameEdit.setText( tagToEdit.getName() );
            descriptionEdit.setText( tagToEdit.getDescription() );
        }
    
    }  // end onResume()

    @Override
    public void onPause()
    {
        super.onPause();
        
        overridePendingTransition(R.anim.hold,R.anim.slideout_bottom);
    }


    // TODO - set a tag we are editing, this can be changed to Intent 
    //      - extras if we don't need to also launch as a fragment
    public static void setTagToEdit(Tag inTag)
    {
        tagToEdit = inTag;
    }

    
    // called by the action listener on our EditText keyboard, when 'done' is pressed
    private void keyboardDone()
    {
        Intent myIntent = getIntent();
        Group currentGroup = null;

        int tempGroupId = myIntent.getIntExtra("group_id",-100);

        if( tempGroupId == -100 )
        {
            Log.d(MYTAG,">>> no group passed");
        }
        else
        {
            currentGroup = GroupPeer.retrieveGroupById(tempGroupId);
        }

        // get the name input
        String nameContent = nameEdit.getText().toString();

        // when they click 'done' on the keyboard, add the new group and exit
        if( nameContent.length() > 0 )
        {
            // get the description input
            String descriptionContent = descriptionEdit.getText().toString();
            
            if( tagToEdit == null )
            {
                // create the new Tag in the database
                tagToEdit = TagPeer.createTagNamed(nameContent, currentGroup, descriptionContent);
            }
            else
            {
                // save the existing Tag we are editing
                tagToEdit.setName(nameContent);
                tagToEdit.setDescription(descriptionContent);

                tagToEdit.save();
            }
             
            // broadcast the creation of a new Tag, tagged with the id of the passed
            // card if 'this' was called from AddCardToTag
            XflashNotification theNotifier = XFApplication.getNotifier();
            
            int tempCardId = myIntent.getIntExtra("card_id",XflashNotification.NO_CARD_PASSED);
            theNotifier.setCardIdPassed(tempCardId); 
            theNotifier.newTagBroadcast(tagToEdit);
        }
        else
        {
            // they didn't have a tag name entered
            String needName = getResources().getString(R.string.addtag_needname);
            Toast.makeText(this,needName, Toast.LENGTH_SHORT).show();
        }

    }  // end keyboardDone()

    
    // the listener for when 'done' is clicked on the keyboard
    private TextView.OnEditorActionListener createTagActionListener = new TextView.OnEditorActionListener() 
    {
        @Override
        public boolean onEditorAction(TextView v,int actionId,KeyEvent event) 
        {
            if( actionId == EditorInfo.IME_ACTION_DONE )
            {
                keyboardDone();
                
                if( nameEdit.getText().toString().length() > 0 )
                {
                    // only close the Activity if they typed in a title
                    finish();
                }
                    
                return true;

            }  // end if( DONE was clicked )
                
            // do not consume event if it wasn't 'done'
            return false;
        }  

    };  // end createTagActionListener

    

}  // end CreateTagActivity class declaration




