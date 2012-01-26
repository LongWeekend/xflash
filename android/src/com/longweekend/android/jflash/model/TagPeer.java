package com.longweekend.android.jflash.model;

//  TagPeer.java
//  jFlash
//
//  Created by Todd Presson on 1/15/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public TagPeer()
//
//      *** ALL METHODS STATIC ***
//
//  public void recacheCountsForUserTags()
//  public void setCardCount(int  ,Tag  )
//  public boolean cancelMembership(Card  ,Tag  )
//  public boolean card(Card  ,Tag  )
//  public ArrayList<Tag> faultedTagsForCard(Card  )
//  public boolean subscribeCard(Card  ,Tag  )
//
//  public ArrayList<Tag> retrieveSysTagList()
//  public ArrayList<Tag> retrieveUserTagList()
//  public ArrayList<Tag> retrieveSysTagListContainingCard(Card  )
//  public ArrayList<Tag> retrieveTagListByGroupId(int  )
//  public ArrayList<Tag> retrieveTagListLike(String  )
//  public Tag retrieveTagById(int  )
//  public Tag retrieveTagByName(String  )
//  
//  public Tag createTagNamed(String  ,Group  )
//  public Tag createTagNamed(String  ,Group  ,String  )
//  public boolean deleteTag(Tag  )
//
//  private ArrayList<Tag> tagListWithCursor(Cursor  )
//  private Tag tagWithCursor(Cursor  )

import java.util.ArrayList;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.longweekend.android.jflash.JFApplication;

public class TagPeer
{
    private static final String MYTAG = "JFlash TagPeer";

    private static final String kTagPeerErrorDomain = "kTagPeerErrorDomain";
    private static final String LWETagContentDidChange = "LWETagContentDidChange";
    private static final String LWETagContentDidChangeTypeKey = "LWETagContentDidChangeTypeKey";
    private static final String LWETagContentDidChangeCardKey = "LWETagContentDidChangeCardKey";
    private static final String LWETagContentCardAdded = "LWETagContentCardAdded";
    private static final String LWETagContentCardRemoved = "LWETagContentCardRemoved";

    private static final int kRemoveLastCardOnATagError = 999;

    private static SQLiteDatabase tempDB;

    // pull the context in the constructor, because we will
    // need it for any given method
    public TagPeer()
    {
        // get the dao
        tempDB = JFApplication.getWritableDao();
    }

    // recaches card counts for user tags
    public static void recacheCountsForUserTags()
    {
        // get all editable (i.e. user-created) tags
        String query = "SELECT tag_id FROM tags WHERE editable = 1";
    
        Cursor myCursor = tempDB.rawQuery(query,null);
        int rowCount = myCursor.getCount();
        myCursor.moveToFirst();
    
        // for each Tag returned, pull a card count and reset
        // it in the database
        for(int i = 0; i < rowCount; i++)
        {
            // get the Tag Id
            int tempInt = myCursor.getColumnIndex("tag_id");
            int tempId = myCursor.getInt(tempInt);              

            // get the cards linked to the Tag
            String[] selectionArgs = new String[] { Integer.toString(tempId) };
            String tempQuery = "SELECT card_id FROM card_tag_link WHERE tag_id = ?";
   
            Cursor tempCursor = tempDB.rawQuery(tempQuery,selectionArgs);
            // how many total cards were returned?
            tempInt = tempCursor.getCount();
            tempCursor.close();

            Tag tempTag = new Tag();
            tempTag.setId(tempId);

            setCardCount(tempInt,tempTag);              

            Log.d(MYTAG,"tag_id: " + tempId + " has " + tempInt + " cards");

        }  // end for loop

        myCursor.close();

    }  // end recacheCountsForUserTags()

    // self explanatory
    public static void setCardCount(int newCount,Tag inTag)
    {
        String[] whereArgs = new String[] { Integer.toString( inTag.getId() ) };
         
        ContentValues updateValues = new ContentValues();
        updateValues.put("count", Integer.toString( newCount ) );
       
        tempDB.update("tags",updateValues,"tag_id = ?",whereArgs);        
    }

    // removes inCard.cardId from the incoming Tag object
    // this will alsoc heck regarding the last card on the active set and automatically
    // remove that card from the active set card cache
    //
    // note this method DOES update the tag count cache on the tags table
    public static boolean cancelMembership(Card inCard,Tag inTag)
    {
        Log.d(MYTAG,"ALERT - MISSING FUNCTIONALITY");
        Log.d(MYTAG,"      - IN METHOD TagPeer.cancelMembership()");

        // first check whether the removed card is in the active tag
        // if the tagId supplied is the active card, check for last card cause
        // we don't want the last card being removed from a tag. 
        
        // TODO - don't know the proper way to implement this yet
        //      - it will probably require passing Context from the 
        //      - Activity calling this method?
        //
        // CurrentState *currentState = [CurrentState sharedCurrentState];
        // if ([tag isEqual:currentState.activeTag])
        if( false )
        {
            Log.d(MYTAG,"editing current set tags");

            // get the total card count of relevant tag
            String[] selectionArgs = new String[] { Integer.toString( inTag.getId() ) };
            String query = "SELECT count(card_id) AS total_card FROM card_tag_link WHERE tag_id = ?";
        
            Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
            myCursor.moveToFirst();

            int tempColumn = myCursor.getColumnIndex("total_card");
            int totalCard = myCursor.getInt(tempColumn);
            myCursor.close();

            // if we're downt to the last card
            if( totalCard <= 1 )
            {
                Log.d(MYTAG,"last card in set");

                // TODO - NO idea what this is about yet

/* 
                // this is the last card, abort!
                    // construct the error object to be returned back to its caller.
      
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                NSLocalizedString(@"This set only contains the card you are currently studying.  To delete a set entirely, please change to a different set first.", @"AddTagViewController.AlertViewLastCardMessage"), NSLocalizedDescriptionKey,nil];
                    
                if( theError != NULL )
                    {
                        *theError = [NSError errorWithDomain:kTagPeerErrorDomain code:kRemoveLastCardOnATagError userInfo:userInfo];
                    }

*/      
        
                return false;
            
            }  // end if( totalCard <= 1 )


        }  // end if(the passed Card is in the active Tag)
           // initial - to determine if we're' downt to the last card

        
        // now we actually delete from card_tag_link
        String[] selectionArgs = new String[] { Integer.toString( inCard.getCardId() ), Integer.toString( inTag.getId() ) };
        String query = "DELETE FROM card_tag_link WHERE card_id = ? AND tag_id = ?";

        tempDB.rawQuery(query,selectionArgs);
        
        // only update this stuff if NOT the active set - actual comment
        // TODO - don't know the proper way to implement this yet
        //
        // if ([tag isEqual:currentState.activeTag] == NO)
        if( true )
        {
            selectionArgs = new String[] { Integer.toString( inTag.getId() ) };
            query = "UPDATE tags SET count = (count - 1) WHERE tag_id = ?";

            // TODO - original TempPeer.m had error correcting code here
            //        but the query executes normally even if there are
            //        no tags with the specified ID
            tempDB.rawQuery(query,selectionArgs);
        } 

        

        // Finally, send a system-wide notification that this tag changed
/*
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                            LWETagContentCardRemoved,LWETagContentDidChangeTypeKey,
                            card,LWETagContentDidChangeCardKey,
                            nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:LWETagContentDidChange
                                                      object:tag
                                                    userInfo:userInfo];
*/
        return true;

    }  // end cancelMembership()

    // checked if a passed tagId/cardId are matched
    public static boolean card(Card inCard,Tag inTag)
    {
        String[] selectionArgs = new String[] { Integer.toString( inCard.getCardId() ), Integer.toString( inTag.getId() ) };
        String query = "SELECT * FROM card_tag_link WHERE card_id = ? AND tag_id = ?";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);

        if( myCursor.getCount() > 0)
        {
            return true;
        }
        else
        {
            return false;
        }   

    }

    // returns an ArrayList<int> of Tag objects this card is a member of
    public static ArrayList<Tag> faultedTagsForCard(Card inCard)
    {
        // ArrayList to return
        ArrayList<Tag> membershipList = new ArrayList<Tag>();

        String[] selectionArgs = new String[] { Integer.toString( inCard.getCardId() ) };
        String query = "SELECT t.tag_id AS tag_id FROM tags t, card_tag_link c WHERE t.tag_id = c.tag_id AND c.card_id = ?";
        
        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        
        int rowCount = myCursor.getCount();
        myCursor.moveToFirst();

        // for each row returned
        for(int i = 0; i < rowCount; i++)
        {
            int tempColumn = myCursor.getColumnIndex("tag_id");
            int tempId = myCursor.getInt(tempColumn);

            // make a new Tag with the ID from the database
            // and add it to the list to be returned
            Tag tempTag = new Tag();
            tempTag.setId(tempId);
            membershipList.add(tempTag);        

            myCursor.moveToNext();
        }

        return membershipList;

    }  // end faultedTagsForCard()

    // subscribes a Card to a given Tag based on incoming object Id's
    // note that this method DOES NOT update the tag count cache on the tags table
    public static boolean subscribeCard(Card inCard,Tag inTag)
    {
        // quick return on bad input
        if( inCard.getCardId() <= 0 )
        {
            return false;
        }

        // TODO - the original code had error checking on whether these     
        //    queries were successful, but they execute normallly
        //        no matter the input numbers
        String[] selectionArgs = new String[] { Integer.toString( inCard.getCardId() ), Integer.toString( inTag.getId() ) };
        String query = "INSERT INTO card_tag_link (card_id,tag_id) VALUES (?,?)";
        tempDB.rawQuery(query,selectionArgs);

        selectionArgs = new String[] { Integer.toString( inTag.getId() ) };
        query = "UPDATE tags SET count = (count + 1) WHERE tag_id = ?";
        tempDB.rawQuery(query,selectionArgs);

        // TODO - more notifications
/*      
  // Finally, send a system-wide notification that this tag changed. Interested objects can listen.
  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                            LWETagContentCardAdded,LWETagContentDidChangeTypeKey,
                            card,LWETagContentDidChangeCardKey,
                            nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:LWETagContentDidChange
                                                      object:tag
                                                    userInfo:userInfo];

*/
        return true;

    }  // end subscribeCard()

    // gets system Tag objects as an ArrayList
    public static ArrayList<Tag> retrieveSysTagList()
    {
        ArrayList<Tag> tempList;
        String query = "SELECT *, UPPER(tag_name) as utag_name FROM tags WHERE editable = 0 ORDER BY utag_name ASC";

        Cursor myCursor = tempDB.rawQuery(query,null);
        myCursor.moveToFirst();
        tempList = tagListWithCursor(myCursor);
        myCursor.close();

        return tempList;
    }

    // returns an ArrayList of Tag objects by Tag.editable = 1;
    public static ArrayList<Tag> retrieveUserTagList()
    {
        ArrayList<Tag> tempList;
        String query = "SELECT *, UPPER(tag_name) as utag_name FROM tags WHERE editable = 1 OR tag_id = 0 ORDER BY utag_name ASC";

        Cursor myCursor = tempDB.rawQuery(query,null);
        myCursor.moveToFirst();
        tempList = tagListWithCursor(myCursor);
        myCursor.close();

        return tempList;
    }

    // gets system Tag objects that have inCard in them as ArrayList<Tag>
    public static ArrayList<Tag> retrieveSysTagListContainingCard(Card inCard)
    {
        ArrayList<Tag> tempList;
        String[] selectionArgs = new String[] { Integer.toString( inCard.getCardId() ) }; 
        String query = "SELECT *, UPPER(t.tag_name) as utag_name FROM card_tag_link l,tags t WHERE l.card_id = ? AND l.tag_id = t.tag_id AND t.editable = 0 ORDER BY utag_name ASC";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        myCursor.moveToFirst();
        tempList = tagListWithCursor(myCursor);
        myCursor.close();

        return tempList;
    }

    // returns an ArrayList<Tag> based on Group membership
    public static ArrayList<Tag> retrieveTagListByGroupId(int inId)
    {
        ArrayList<Tag> tempList;
        String[] selectionArgs = new String[] { Integer.toString(inId) }; 
        String query = "SELECT * FROM tags t, group_tag_link l WHERE t.tag_id = l.tag_id AND l.group_id = ? ORDER BY t.tag_name ASC";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        myCursor.moveToFirst();
        tempList = tagListWithCursor(myCursor);
        myCursor.close();

        return tempList;    
    }

    // returns an ArrayList<Tag> containgin any Tag with a title LIKE inString
    public static ArrayList<Tag> retrieveTagListLike(String inString)
    {
        ArrayList<Tag> tempList;
        String[] selectionArgs = new String[] { "%" + inString + "%" };
        String query = "SELECT * FROM tags WHERE tag_name LIKE ? ORDER BY tag_name ASC";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        myCursor.moveToFirst();
        tempList = tagListWithCursor(myCursor);
        myCursor.close();       
            
        return tempList;
    }

    // gets a Tag by its Id
    public static Tag retrieveTagById(int inId)
    {
        Tag myTag;
        String[] selectionArgs = new String[] { Integer.toString(inId) };
        String query = "SELECT * FROM tags WHERE tag_id = ? LIMIT 1";
            
        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        myCursor.moveToFirst();
        myTag = tagWithCursor(myCursor);
        myCursor.close();

        return myTag;
    }

    // gets a Tag by its name
    public static Tag retrieveTagByName(String inName)
    {
        Tag tempTag;
        String[] selectionArgs = new String[] { inName }; 
        String query = "SELECT * FROM tags WHERE tag_name LIKE ? LIMIT 1";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        myCursor.moveToFirst();
        tempTag = tagWithCursor(myCursor);
        myCursor.close();
    
        return tempTag;     
    }

    // adds a new tag to the database, returns new tag object
    public static Tag createTagNamed(String inName,Group inGroup)
    {
        Tag tempTag = createTagNamed(inName,inGroup," ");

        return tempTag;
    }

    // adds a new Tag to the database, returns the new Tag
    public static Tag createTagNamed(String inName,Group inGroup,String inDescription)
    {
        // insert the new Tag into 'tags'
        ContentValues insertValues = new ContentValues();
        insertValues.put("tag_name",inName);
        insertValues.put("description",inDescription); 

        String query = "INSERT INTO tags (tag_name, description) VALUES (?,?)";
        tempDB.insert("tags",null,insertValues);

        // get our freshly added Tag's ID for linkage
        Cursor myCursor = tempDB.rawQuery("SELECT MAX(tag_id) FROM tags",null);
        if( myCursor.getCount() != 1 )
        {
            Log.d(MYTAG,"ERROR retrieveing newest tag_id");
        }
        
        myCursor.moveToFirst();
        int newId = myCursor.getInt(0);
        myCursor.close();

        // insert the new Tag into 'group_tag_link'
        insertValues = new ContentValues();
        insertValues.put("tag_id",newId);
        insertValues.put("group_id", inGroup.getGroupId() );

        tempDB.insert("group_tag_link",null,insertValues);

        // increment the tag_count for the appropriate Group
        query = "UPDATE groups SET tag_count=(tag_count+1) WHERE group_id = " + inGroup.getGroupId();
        tempDB.execSQL(query);

        Tag tempTag = retrieveTagById(newId);
        
        return tempTag;

    }  // end createTagNamed()

    // deletes a Tag and all Card links
    public static boolean deleteTag(Tag inTag)
    {
        ArrayList<Integer> groupList = new ArrayList<Integer>();

        // First get owner id of a tag
        String[] selectionArgs = new String[] { Integer.toString( inTag.getId() ) };
        String query = "SELECT group_id FROM group_tag_link WHERE tag_id = ?";
        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        int rowCount = myCursor.getCount();
        myCursor.moveToFirst();
        
        Log.d(MYTAG,"group_id rows:  " + rowCount);

        // make our ArrayList of group_id's to remove inTag from
        for(int i = 0; i < rowCount; i++)
        {
            int tempColumn = myCursor.getColumnIndex("group_id");
            int tempInt = myCursor.getInt(tempColumn);
            groupList.add( tempInt );
            myCursor.moveToNext();
        }
        myCursor.close();
    
        tempDB.beginTransaction();
            
        // do all of the database removal
        try
        {
            // remove from card_tag_link
            selectionArgs = new String[] { Integer.toString( inTag.getId() ) };   
            tempDB.delete("card_tag_link","tag_id = ?",selectionArgs);  

            // remove from tags
            tempDB.delete("tags","tag_id = ?",selectionArgs);
                
            // drop tag_count for all relevant groups
            for(int i = 0; i < rowCount; i++)
            {
                query = "UPDATE groups SET tag_count = (tag_count-1) WHERE group_id = " + groupList.get(i);
                tempDB.execSQL(query);
            }

            tempDB.setTransactionSuccessful();
        } 
        catch (Throwable t) 
        {
            tempDB.endTransaction();
            LWEDatabase.logQueryFail(MYTAG, t.toString(), "deleteTag()");

            return false;
        }

        tempDB.endTransaction();

        return true;

    }  // end deleteTag()

    //  does not close Cursor
    private static ArrayList<Tag> tagListWithCursor(Cursor inCursor)
    {
        ArrayList<Tag> tags = new ArrayList<Tag>();

        int rowCount = inCursor.getCount();

        for(int i = 0; i < rowCount; i++)
        {
            Tag tempTag = new Tag();

            tempTag.hydrateWithCursor(inCursor);
            tags.add(tempTag);          
        }

        return tags;
    }

    //  does not close Cursor
    private static Tag tagWithCursor(Cursor inCursor)
    {
        Tag tempTag = new Tag();

        tempTag.hydrateWithCursor(inCursor);

        return tempTag;
    }



}  // end TagPeer class declaration


