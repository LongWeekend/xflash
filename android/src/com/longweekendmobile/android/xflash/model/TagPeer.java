package com.longweekendmobile.android.xflash.model;

//  TagPeer.java
//  Xflash
//
//  Created by Todd Presson on 1/15/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//      *** ALL METHODS STATIC ***
//
//  public static Tag blankTagWithId(int  )
//  public Tag starredWordsTag()
//  public void recacheCountsForUserTags()
//  public void setCardCount(int  ,Tag  )
//  public boolean cancelMembership(Card  ,Tag  )
//  public boolean cardIsMemberOfTag(Card  ,Tag  )
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

import com.longweekendmobile.android.xflash.XFApplication;
import com.longweekendmobile.android.xflash.XflashAlert;
import com.longweekendmobile.android.xflash.XflashNotification;
import com.longweekendmobile.android.xflash.XflashSettings;

public class TagPeer
{
    private static final String MYTAG = "XFlash TagPeer";

    // private static final String kTagPeerErrorDomain = "kTagPeerErrorDomain";
    // private static final String LWETagContentDidChange = "LWETagContentDidChange";
    // private static final String LWETagContentDidChangeTypeKey = "LWETagContentDidChangeTypeKey";
    // private static final String LWETagContentDidChangeCardKey = "LWETagContentDidChangeCardKey";
    // private static final String LWETagContentCardAdded = "LWETagContentCardAdded";
    // private static final String LWETagContentCardRemoved = "LWETagContentCardRemoved";

    // private static final int kRemoveLastCardOnATagError = 999;

    public static final int STARRED_TAG_ID = 0;
    
    
    // this method simply returns a new Tag object with the same tag ID
    // as the Tag from which this method was called
    public static Tag blankTagWithId(int inId)
    {
        Tag newTag = new Tag();

        newTag.setId(inId);

        return newTag;
    }


    // returns the starred words Tag
    public static Tag starredWordsTag()
    {
        Tag tempTag = TagPeer.retrieveTagById(STARRED_TAG_ID);
        
        return tempTag;
    }

    // recaches card counts for user tags
    public static void recacheCountsForUserTags()
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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

        }  // end for loop

        myCursor.close();

    }  // end recacheCountsForUserTags()

    // self explanatory
    public static void setCardCount(int newCount,Tag inTag)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        String[] whereArgs = new String[] { Integer.toString( inTag.getId() ) };
         
        ContentValues updateValues = new ContentValues();
        updateValues.put("count", Integer.toString( newCount ) );
       
        tempDB.update("tags",updateValues,"tag_id = ?",whereArgs);        
    }

    // removes inCard.cardId from the incoming Tag object
    // this will also check whether inTag is currently active, and if so,m
    // will refuse to remove the card (and throw up a dialog)
    //
    // note this method DOES update the tag count cache on the tags table
    public static boolean cancelMembership(Card inCard,Tag inTag)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        boolean tagIsActive = ( inTag.getId() == XflashSettings.getActiveTag().getId() );
        String[] tempArgs = null;

        // first check whether the removed card is in the active tag
        if( tagIsActive )
        {
            // if we're downt to the last card
            if( inTag.getCardCount() <= 1 )
            {
                // this is the last card, abort!
                XflashAlert.fireLastCardDialog(inTag);

                return false;
            }

        }  // end if( removing from active tag )
        
        // now we actually delete from card_tag_link
        tempArgs = new String[] { Integer.toString( inCard.getCardId() ), Integer.toString( inTag.getId() ) };
        tempDB.delete("card_tag_link","card_id = ? AND tag_id = ?",tempArgs);
        
        tempArgs = new String[] { Integer.toString( inTag.getId() ) };
        String query = "UPDATE tags SET count = (count - 1) WHERE tag_id = ?";

        tempDB.execSQL(query,tempArgs);

        // broadcast the card whose subscription status has changed
        XflashNotification theNotifier = XFApplication.getNotifier();
        theNotifier.setCardWasAdded(false);
        theNotifier.setTagIdPassed( inTag.getId() );
        theNotifier.subscriptionBroadcast(inCard); 
        
        return true;

    }  // end cancelMembership()


    // checked if a passed tagId/cardId are matched
    public static boolean cardIsMemberOfTag(Card inCard,Tag inTag)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        String[] selectionArgs = new String[] { Integer.toString( inCard.getCardId() ), Integer.toString( inTag.getId() ) };
        String query = "SELECT * FROM card_tag_link WHERE card_id = ? AND tag_id = ?";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);

        int tempCount = myCursor.getCount();
        myCursor.close();

        if( tempCount > 0)
        {
            return true;
        }
        else
        {
            return false;
        }   

    }  // end cardIsMemberOfTag()

    // returns an ArrayList<int> of Tag objects this card is a member of
    public static ArrayList<Tag> faultedTagsForCard(Card inCard)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        // quick return on bad input
        if( inCard.getCardId() <= 0 )
        {
            Log.d(MYTAG,">>> subscribeCard() returning false on id < 1");
            return false;
        }

        // insert the new Tag into 'tags'
        ContentValues insertValues = new ContentValues();
        insertValues.put("card_id", inCard.getCardId() );
        insertValues.put("tag_id", inTag.getId() ); 
        tempDB.insert("card_tag_link",null,insertValues);

        String[] updateArgs = { Integer.toString( inTag.getId() ) };
        String query = "UPDATE tags SET count = (count + 1) WHERE tag_id = ?";
        
        tempDB.execSQL(query,updateArgs);
        
        // broadcast the card whose subscription status has changed
        XflashNotification theNotifier = XFApplication.getNotifier();
        theNotifier.setCardWasAdded(true);
        theNotifier.setTagIdPassed( inTag.getId() );
        theNotifier.subscriptionBroadcast(inCard); 
 
        return true;

    }  // end subscribeCard()


    // gets system Tag objects as an ArrayList
    public static ArrayList<Tag> retrieveSysTagList()
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
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
        String[] updateArgs = { Integer.toString( inGroup.getGroupId() ) };
        query = "UPDATE groups SET tag_count=(tag_count+1) WHERE group_id = ?";
        tempDB.execSQL(query,updateArgs);

        Tag tempTag = retrieveTagById(newId);
        
        return tempTag;

    }  // end createTagNamed()

    // deletes a Tag and all Card links
    public static boolean deleteTag(Tag inTag)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        ArrayList<Integer> groupList = new ArrayList<Integer>();

        // First get owner id of a tag
        String[] selectionArgs = new String[] { Integer.toString( inTag.getId() ) };
        String query = "SELECT group_id FROM group_tag_link WHERE tag_id = ?";
        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        int rowCount = myCursor.getCount();
        myCursor.moveToFirst();
        
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
                selectionArgs = new String[] { Integer.toString( groupList.get(i) ) };
                query = "UPDATE groups SET tag_count = (tag_count-1) WHERE group_id = ?";
                tempDB.execSQL(query,selectionArgs);
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

            inCursor.moveToNext();
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


