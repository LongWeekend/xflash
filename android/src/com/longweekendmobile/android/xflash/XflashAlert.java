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
//  public  void fireFirstRun(Tag  )
//  public  void fireTagLearned(Tag  )
//  public  void fireLastCardDialog(Tag  )
//  public  void startStudying(View  )
//  private void fireStartStudyingDialog(Tag  )
//  private void fireEmptyTagDialog()

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.view.View;

import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class XflashAlert 
{
    // dialog to be displayed the first time the app is ran after install
    public static void fireFirstRun()
    {
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );

        // set the title
        String tempString = Xflash.getActivity().getResources().getString(R.string.firstrun_alert_title);
        builder.setTitle(tempString);

        // set the message
        tempString = Xflash.getActivity().getResources().getString(R.string.firstrun_alert_message);
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton("OK",null);

        builder.create().show();

    }  // end fireTagLearned()
    
    
    // dialog to display (once) when all cards in a Tag are learned
    public static void fireTagLearned(Tag inTag)
    {
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );

        // set the title
        String tempString = Xflash.getActivity().getResources().getString(R.string.learned_alert_title);
        builder.setTitle(tempString);

        // set the message
        tempString = Xflash.getActivity().getResources().getString(R.string.learned_alert_message);
        tempString = tempString.replace("##TAGNAME##", inTag.getName() );
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton("OK",null);

        builder.create().show();

    }  // end fireTagLearned()
    
    
    // dialog to display error if user tries to remove the last card in a set
    public static void fireLastCardDialog(Tag inTag)
    {
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );

        // set the title
        String tempString = Xflash.getActivity().getResources().getString(R.string.lastcard_alert_title);
        builder.setTitle(tempString);

        // set the message
        tempString = Xflash.getActivity().getResources().getString(R.string.lastcard_alert_message);
        tempString = tempString.replace("##TAGNAME##", inTag.getName() );
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton("OK",null);

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
        builder.setPositiveButton("OK", new DialogInterface.OnClickListener()
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
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder( Xflash.getActivity() );

        // set the title
        String tempString = Xflash.getActivity().getResources().getString(R.string.emptyset_dialog_title);
        builder.setTitle(tempString);

        // set the message
        tempString = Xflash.getActivity().getResources().getString(R.string.emptyset_dialog_message);
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton("OK",null);

        builder.create().show();

    }  // end fireEmptyTagDialong()


}  // end XflashAlert class declaration
