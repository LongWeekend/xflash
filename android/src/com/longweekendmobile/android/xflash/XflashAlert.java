package com.longweekendmobile.android.xflash;

//  XflashAlert.java
//  Xflash
//
//  Created by Todd Presson on 3/18/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  a class to handle dialogs called by more than one class/fragment
//
//      *** ALL METHODS STATIC ***
//
//  public  void fireUpdate(int  )
//  public  void fireTagLearned(Tag  )
//  public  void fireLastCardDialog(Tag  )
//  public  void startStudying(View  )
//  public  void deleteUserError(User  )
//  public  void fireNoTagNameDialog(Context  )
//  private void fireStartStudyingDialog(Tag  )
//  private void fireEmptyTagDialog()

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.res.Resources;
import android.view.View;

import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;
import com.longweekendmobile.android.xflash.model.User;

public class XflashAlert 
{
    // displays a dialog with various update messages, depending on current
    // versionCode in AndroidManifest.xml
    
    // NOTE - newVersionCode could be a string (i.e. "1.0") if we prefer
    public static void fireUpdate(int newVersionCode)
    {
        Resources res = Xflash.getActivity().getResources();
        
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );

        String title = null;
        String message = null;
        
        if( newVersionCode == 1 )
        {
            // first run
            title = res.getString(R.string.firstrun_alert_title);
            message = res.getString(R.string.firstrun_alert_message);
        }
        else if( newVersionCode == 2 )
        {
            title = res.getString(R.string.update_debug_title);
            message = res.getString(R.string.update_debug_message);
        }
        else
        {
            throw new RuntimeException("XflashAlert.fireUpdate(" + newVersionCode + 
                                       ") BAD VERSION CODE!");
        }
        
        builder.setTitle(title);
        builder.setMessage(message);

        // on negative response, do nothing
        builder.setNegativeButton( res.getString(R.string.just_ok) ,null);

        builder.create().show();

    }  // end fireUpdate()
    
    
    // dialog to display (once) when all cards in a Tag are learned
    public static void fireTagLearned(Tag inTag)
    {
        Resources res = Xflash.getActivity().getResources();
        
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );

        // set the title
        String tempString = res.getString(R.string.learned_alert_title);
        builder.setTitle(tempString);

        // set the message
        tempString = res.getString(R.string.learned_alert_message);
        tempString = tempString.replace("##TAGNAME##", inTag.getName() );
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton( res.getString(R.string.just_ok) ,null);

        builder.create().show();

    }  // end fireTagLearned()
    
    
    // dialog to display error if user tries to remove the last card in a set
    public static void fireLastCardDialog(Tag inTag)
    {
        Resources res = Xflash.getActivity().getResources();
        
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );

        // set the title
        String tempString = res.getString(R.string.lastcard_alert_title);
        builder.setTitle(tempString);

        // set the message
        tempString = res.getString(R.string.lastcard_alert_message);
        tempString = tempString.replace("##TAGNAME##", inTag.getName() );
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton( res.getString(R.string.just_ok) ,null);

        builder.create().show();

    }  // end fireLastCardDialog()


    // launch the clicked on Tag in the practice tab
    public static void startStudying(View v)
    {
        int incomingTagId = (Integer)v.getTag();
        Tag tempTag = TagPeer.retrieveTagById(incomingTagId);

        // if user is trying to open an empty tag
        if( tempTag.getCardCount() < 1 )
        {
            fireEmptyTagDialog();
        }
        else
        {
            fireStartStudyingDialog(tempTag);
        }

    }  // end startStudying()

    public static void deleteUserError(User inUser)
    {
        Resources res = Xflash.getActivity().getResources();
        
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );

        // set the title
        String tempString = res.getString(R.string.user_deleteerror_title);
        builder.setTitle(tempString);

        // set the message
        if( inUser.getUserId() == XflashSettings.LWE_DEFAULT_USER )
        {
            // if they are trying to delete the default user
            tempString = res.getString(R.string.user_deleteerror_default_message);
        }
        else
        {
            // if they are trying to delete the active user
            tempString = res.getString(R.string.user_deleteerror_active_message);
            tempString = tempString.replace("##USERNAME##", inUser.getUserNickname() ); 
        }
        
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton( res.getString(R.string.just_ok) ,null);

        builder.create().show();

    }  // end deleteUserError()


    // dialog to display error when attemping to save a Tag with no name
    public static void fireNoTagNameDialog(Context inContext)
    {
        Resources res = inContext.getResources();
        
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder(inContext);

        // set the title
        String tempString = res.getString(R.string.edittag_noname_title);
        builder.setTitle(tempString);

        // set the message
        tempString = res.getString(R.string.edittag_noname_message);
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton( res.getString(R.string.just_ok) ,null);

        builder.create().show();

    }  // end fireNoTagNameDialog()


    // launch the dialog to confirm user would like to start studying a tag
    private static void fireStartStudyingDialog(Tag inTag)
    {
        final Tag tagToSet = inTag;
        final Xflash inContext = Xflash.getActivity();

        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder(inContext);

        // set the title
        builder.setTitle( tagToSet.getName() );

        // set the message
        String tempString = inContext.getResources().getString(R.string.startstudying_dialog_message);
        builder.setMessage(tempString);

        // on postive response, set the new active user
        builder.setPositiveButton( inContext.getResources().getString(R.string.just_ok) , 
                                   new DialogInterface.OnClickListener()
        {
            public void onClick(DialogInterface dialog,int which)
            {
                // set the new user and return to settings
                XflashSettings.setActiveTag(tagToSet);
                Xflash.getTabHost().setCurrentTabByTag("practice");
            }
        });

        // on negative response, do nothing
        builder.setNegativeButton("Cancel",null);

        builder.create().show();

    }  // end fireEmptyTagDialong()


    // dialog to display on attempt to start studying a tag with no cards
    private static void fireEmptyTagDialog()
    {
        Resources res = Xflash.getActivity().getResources();
        
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );

        // set the title
        String tempString = res.getString(R.string.emptyset_dialog_title);
        builder.setTitle(tempString);

        // set the message
        tempString = res.getString(R.string.emptyset_dialog_message);
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton( res.getString(R.string.just_ok) ,null);

        builder.create().show();

    }  // end fireEmptyTagDialong()


}  // end XflashAlert class declaration
