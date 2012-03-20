package com.longweekendmobile.android.xflash.model;

//  UserHistoryPeer.java
//  Xflash
//
//  Created by Todd Presson on 1/22/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public UserHistoryPeer()
//
//      *** ALL METHODS STATIC ***
//
//  private int nextAfterLevel(int  ,boolean  )
//  private void recordResult(Card  ,Tag  ,boolean  ,boolean  )
//
//  public void buryCard(Card  ,Tag  )
//  public void recordCorrectForCard(Card  ,Tag  )
//  public void recordWrongForCard(Card  ,Tag  )

import android.database.sqlite.SQLiteDatabase;
import android.database.Cursor;

import com.longweekendmobile.android.xflash.XFApplication;
import com.longweekendmobile.android.xflash.XflashSettings;

public class UserHistoryPeer
{
    private static final String MYTAG = "XFlash UserHistoryPeer";

    // returns what the next level should be based on the users's answer
    private static int nextAfterLevel(int level,boolean gotItRight)
    {
        if( gotItRight )
        {
            // user got it right
            if( level >= 1 && level < 5)
            {
                ++level;
                return level;
            }
            else if( level == 0 )
            {
                // if they get an unseen card right it should go into 
                // the "right 1x" bucket
                return 2;
            }
            else
            {
                return 5;
            }
        } // end if( gotItRight )
        else
        {
            // user got it wrong, put it at 1
            return 1;
        }

    }  // end nextAfterLevel()

    // updates the database based on the user's answer
    private static void recordResult(Card inCard,Tag inTag,boolean gotItRight,boolean knewIt)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        String[] selectionArgs;
        String query;
        int nextLevel = -1;
        
        if( knewIt )
        {
            nextLevel = 5;
        }
        else
        {
            nextLevel = nextAfterLevel(inCard.getLevelId(),gotItRight);
        }

        if( gotItRight )
        {
            // int oldNextLevel
            
            // args: inCard.cardId, user_id, (inCard.rightCount + 1), inCard.wrongCount, nextLevel
            selectionArgs = new String[] { Integer.toString( inCard.getCardId() ), Integer.toString( XflashSettings.getCurrentUserId() ), Integer.toString( (inCard.getRightCount() + 1) ), Integer.toString( inCard.getWrongCount() ), Integer.toString(nextLevel) };

            query = "INSERT OR REPLACE INTO user_history (card_id,timestamp,created_on,user_id,right_count,wrong_count,card_level) VALUES (?,current_timestamp,current_timestamp,?,?,?,?)";

        }
        else
        {
            // int

            // args: inCard.cardId, user_id, inCard.rightCount, (inCard.wrongCount + 1), nextLevel
            selectionArgs = new String[] { Integer.toString( inCard.getCardId() ), Integer.toString( XflashSettings.getCurrentUserId() ), Integer.toString( inCard.getRightCount() ), Integer.toString( ( inCard.getWrongCount() + 1 ) ), Integer.toString(nextLevel) };
            
            query = "INSERT OR REPLACE INTO user_history (card_id,timestamp,created_on,user_id,right_count,wrong_count,card_level) VALUES (?,current_timestamp,current_timestamp,?,?,?,?)";

        }

        tempDB.execSQL(query,selectionArgs);

        inTag.moveCard(inCard,nextLevel);

    }  // end recordResult()


    public static void buryCard(Card inCard,Tag inTag)
    {
        recordResult(inCard,inTag,true,true);
    }


    public static void recordCorrectForCard(Card inCard,Tag inTag)
    {
        recordResult(inCard,inTag,true,false);
    }


    public static void recordWrongForCard(Card inCard,Tag inTag)
    {
        recordResult(inCard,inTag,false,false);
    }


}  // end UserHistoryPeer class declaration




