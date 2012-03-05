package com.longweekendmobile.android.xflash.model;

//  Tag.java
//  Xflash
//
//  Created by Todd Presson on 1/8/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public Tag()
//  
//  public static Tag starredWordsTag()
//  public static boolean isEqual(Tag  )
//
//  public Tag blankTagWithId(int  )
//  public int groupId()
//  public boolean isEditable()
//  public int seenCardCount()
//
//  public void recacheCardCountForEachLevel()
//  public ArrayList<ArrayList<Integer>> thawCardIds(Context  )
//  public void freezeCardIds(Context  )
//  public void populateCardIds(Context  )
//  public ArrayList<ArrayList<Integer>> combineCardIds()
//  public void moveCard(Card  ,int  )
//  public void removeCardFromActiveSet(Card  )
//  public void addCardToActiveSet(Card  )
//
//  public void save()
//  public void tagDidSave()
//  public void hydrate()
//  public void hydrateWithCursor(Cursor  )
//  public String description()
//
//  public void setId(int  )
//  public int getId()
//  public void setEditable(int  )
//  public int getEditable()
//  public void setName(String  )
//  public String getName()
//  public void setDescription(String  )
//  public String getDescription()
//  public void setFault(boolean  )
//  public boolean getFault()
//  public void setCardCount(int  )
//  public int getCardCount()
//  public void setCurrentIndex(int  )
//  public int getCurrentIndex()

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Collections;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.longweekendmobile.android.xflash.XFApplication;

public class Tag
{
    private static final String MYTAG = "XFlash Tag";

    // private static final String kTagErrorDomain = "kTagErrorDomain";
    // private static final String LWETagDidSave = "kTagDidSave";
    // private static final int kAllBuriedAndHiddenError = 999;
    // private static final int kLWETagUnknownError = 998;
    private static final int kLWEUninitializedTagId = -1;
    private static final int kLWEUninitializedCardCount = -1;
    private static final int kLWEUnseenCardLevel = 0;
    // private static final int kLWELearnedCardLevel = 5;
    public static final int STARRED_TAG_ID = 0;

    private int tagId;
    private int cardCount;
    private int currentIndex;
    private int tagEditable;
    ArrayList<ArrayList<Integer>> cardIds;          
    ArrayList<Integer> cardLevelCounts;
    ArrayList<Integer> flattenedCardIdArray;
    
    private String tagName;
    private String tagDescription;

    private boolean isFault;

    public Tag()
    {
        cardIds = null;
        cardLevelCounts = null;
        flattenedCardIdArray = null;
        
        isFault = true;
        tagId = kLWEUninitializedTagId;
        cardCount = kLWEUninitializedCardCount; 
    }

    // isEqual() simply returns a boolean confirming whether the
    // incoming Tag object has the same tagId as the THIS tag object
    public boolean isEqual(Tag inTag)
    {
        return ( tagId == inTag.tagId );        
    }

    public static Tag starredWordsTag()
    {
        Tag tempTag = TagPeer.retrieveTagById(STARRED_TAG_ID);
        
        return tempTag;
    }

    // this method simply returns a new Tag object with the same tag ID
    // as the Tag from which this method was called
    public static Tag blankTagWithId(int inId)
    {
        Tag newTag = new Tag();

        newTag.tagId = inId;

        return newTag;
    }

    // calls a GroupPeer object to query the database, returns the id
    // of the Group that this Tag belongs to
    public int groupId()
    {
        // TODO: all of this makes the assumption that tags are 
        // 1-1 with groups.  that was not the original design, 
        // but are we moving that direction?  MMA - Oct 19 2011

        return GroupPeer.parentGroupIdOfTag(this);
    }

    // returns a boolean if this object's tagEditable is 1
    public boolean isEditable()
    {
        return ( tagEditable == 1 );
    }

    // not ENTIRELY sure what's going on here yet
    public int seenCardCount()
    {
        return ( cardCount - cardLevelCounts.get(kLWEUnseenCardLevel) );
    }

    // create a cache of the number of Card objects in each level
    public void recacheCardCountForEachLevel()
    {
        // if we have no cards to recache
        if( cardIds == null )
        {
            Log.d(MYTAG,"ERROR - in recacheCardCountForEachLevel()");
            Log.d(MYTAG,"      - cardIds is null");
        
            return;
        }
        
        // if our array is broken
        if( cardIds.size() != 6 )
        {
            Log.d(MYTAG,"ERROR in recacheCardCountForEachlevel()");
            Log.d(MYTAG,"cardIds.size() does not equal 6");

            return;
        }

        int count = 0;
        int totalCount = 0;

        ArrayList<Integer> cardLevelCountsTmp = new ArrayList<Integer>();

        // sort through all six card levels
        for(int i = 0; i < 6; i++)
        {
            count = cardIds.get(i).size();
            cardLevelCountsTmp.add(count);
            totalCount = totalCount + count;
        }

        cardLevelCounts = cardLevelCountsTmp;
        cardCount = totalCount;
        
        return;

    }  // end recacheCardCountForEachLevel() 
    
    // loads a serialized copy of cardIds from a file 'ids.plist'
    // TODO - performance on ObjectInputStream is horrible, hand-code 
    //        a serialization or don't worry about it?
    @SuppressWarnings("unchecked")
    public ArrayList<ArrayList<Integer>> thawCardIds(Context inContext)
    {
        String cacheFile = "ids.plist";

        try
        {
            // open file, open serialized reader, read our list
            FileInputStream fis = inContext.openFileInput(cacheFile); 
            ObjectInputStream in = new ObjectInputStream(fis); 
            
            // the following line causes the compiler to complain about
            // unsafe operations (i.e. an unspecified List)
            //      - CANNOT BE HELPED, SUPPRESS WARNING
            cardIds = (ArrayList<ArrayList<Integer>>)in.readObject();
            
            in.close(); 
            fis.close();
        } 
        catch(Throwable t)
        {
            Log.d(MYTAG,"ERROR: caught -- " + t.toString() );
        }

        return cardIds;

    }  // end thawCardIds()

    // saves a serialized copy of cardIds to a file 'ids.plist'
    // TODO - performance on ObjectOutputStream is terrible, consider
    //        hand-writing serialization?
    public void freezeCardIds(Context inContext)
    {
        String cacheFile = "ids.plist";

        try
        {
            // open file, open serialized writer, write our list
            FileOutputStream fos = inContext.openFileOutput(cacheFile,Context.MODE_PRIVATE); 
            ObjectOutputStream out = new ObjectOutputStream(fos); 
            out.writeObject(cardIds);
            out.close(); 
            fos.close();
        } 
        catch(Throwable t)
        {
            Log.d(MYTAG,"ERROR: caught -- " + t.toString() );
        }

    }  // end freezeCardIds()

    // executed when loading a new set on app load
    public void populateCardIds(Context inContext)
    {
        ArrayList<ArrayList<Integer>> tempCardIdsArray = thawCardIds(inContext);

        if( tempCardIdsArray != null)
        {
            // delete the PLIST now that we have it in memory
            String tempFile = "ids.plist";
            inContext.deleteFile(tempFile);         

            Log.d(MYTAG,"load from file successful");
        }
        else
        {
            // no PLIST, generate new cardIds array

            Log.d(MYTAG,"no ids.plist available");

            tempCardIdsArray = CardPeer.retrieveCardIdsSortedByLevelForTag(this);

            Log.d(MYTAG,"initial load successful");
        }

        cardIds = tempCardIdsArray;
        flattenedCardIdArray = combineCardIds();

        // populate card level counts
        recacheCardCountForEachLevel();

    }  // end populateCardIds

    // concatenate cardId arrays for browse mode
    public ArrayList<Integer> combineCardIds()
    {
        ArrayList<Integer> allCardIds = new ArrayList<Integer>(cardCount);

        // cycle through all six levels for cardIds
        for(int i = 0; i < 6; i++)
        {
            int temp2 = cardIds.get(i).size();

            // run though each cardIds level and add all cards
            for(int j = 0; j < temp2; j++)
            {
                allCardIds.add( cardIds.get(i).get(j) );
            }
        }   

        // put in numeric order
        Collections.sort(allCardIds);

        return allCardIds;

    }  // end combineCardIds()

    // update level counts cache - kept in memory how many cards are in each level
    public void moveCard(Card inCard,int nextLevel)
    {
        if( cardIds.size() != 6 )
        {
            Log.d(MYTAG,"ERROR in recacheCardCountForEachlevel()");
            Log.d(MYTAG,"cardIds.size() does not equal 6");
        }

        int countBeforeRemove = 0;
        int countBeforeAdd = 0;
        ArrayList<Integer> thisLevelCards = null;
        ArrayList<Integer> nextLevelCards = null;

        // update the cardIds if necessary
        if( nextLevel != inCard.levelId )
        {
            thisLevelCards = cardIds.get( inCard.getLevelId() );
            nextLevelCards = cardIds.get(nextLevel);
        
            countBeforeRemove = thisLevelCards.size();
            countBeforeAdd = nextLevelCards.size();
        }

        // now do the remove
        if( !thisLevelCards.contains( inCard.getCardId() ) )
        {
            Log.d(MYTAG,"ERROR in moveCard - card no longer there");
        }
    
        int tempInt = thisLevelCards.indexOf( inCard.getCardId() );
        thisLevelCards.remove(tempInt);
        int countAfterRemove = thisLevelCards.size();

        // only do the add if the remove was successful
        if( countBeforeRemove == (countAfterRemove + 1) )
        { 
            nextLevelCards.add( inCard.getCardId() );

            // now confirm the add
            int countAfterAdd = cardIds.get(nextLevel).size();
            if( !((countAfterAdd - 1) == countBeforeAdd) )
            {
                Log.d(MYTAG,"the number after add (" + countAfterAdd + ") should be 1 more than the count before add (" + countBeforeAdd + ")");
            }

            recacheCardCountForEachLevel();
        }
        
    }  // end moveCard()
  
    // removed card from tag's memory arrays so they are out of the set
    public void removeCardFromActiveSet(Card inCard)
    {
        int tempId = inCard.getCardId();
        ArrayList<Integer> cardLevel = cardIds.get( inCard.getLevelId() );

        // remove from cardIds
        int tempIndex = cardLevel.indexOf(tempId);
        cardLevel.remove(tempIndex);        

        // remove from flattenedCardIdArray
        tempIndex = flattenedCardIdArray.indexOf(tempId);
        flattenedCardIdArray.remove(tempIndex);

        recacheCardCountForEachLevel();
        
    }  // end removeCardFromActiveSet()

    // add card to tag's memory arrays
    public void addCardToActiveSet(Card inCard)
    {
        int tempId = inCard.getCardId();
        ArrayList<Integer> cardLevel = cardIds.get( inCard.getLevelId() );

        cardLevel.add(tempId);
        flattenedCardIdArray.add(tempId);
        
        recacheCardCountForEachLevel();
    
    }  // end addCardToActiveSet()
    
    // saves the tag to the DB.
    //
    //  this only updates the Tag's basic info, creation is handled
    //  in TagPeer for historical reasons
    public void save()
    {
        
        if( tagId == kLWEUninitializedTagId )
        {
            Log.d(MYTAG,"Tag not initialized, use TagPeer.createTagNamed()");
        }

        // get the dao
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
    
        ContentValues updateValues = new ContentValues();
        updateValues.put("tag_name",tagName);
        updateValues.put("description",tagDescription);
        
        String[] whereArgs = new String[] { Integer.toString(tagId) };

        tempDB.update("tags",updateValues,"tag_id = ?",whereArgs);

        // TODO - if successful, send a broadcast 
        //  [[NSNotificationCenter defaultCenter] postNotificationName:LWETagDidSave object:self];
            
        return;
    
    }  // end save()


    // TODO - rework as a receiver when we find out where we're broadcasting from
    public void tagDidSave()
    {

/* Refreshes self from the DB if a didSave notification is called
- (void)tagDidSave:(NSNotification *)notification
{
  if ([self isEqual:notification.object] && (self.isFault == NO)) // we only care if it's us & this isn't a faulted entry
  {
    [self hydrate];
  }
}
*/
        return;
    }

    // gets 'this' Tag's info from the db and hydrates
    public void hydrate()
    {
        if( tagId == kLWEUninitializedTagId )
        {
            Log.d(MYTAG,"ERROR - hydrate() called on uninitialized tag");
        }

        // get the dao
        SQLiteDatabase tempDB = XFApplication.getWritableDao();

        String[] selectionArgs = new String[] { Integer.toString(tagId) };
        String query = "SELECT * FROM tags WHERE tag_id = ? LIMIT 1";

        try
        {
            Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
            myCursor.moveToFirst();

            hydrateWithCursor(myCursor);
            myCursor.close();

        } 
        catch (Throwable t)
        {
            LWEDatabase.logQueryFail(MYTAG, t.toString() , "hydrate()" );
        }

    }  // end hydrate()

    // fills in values from incoming cursor
    // TODO - unfinished broadcast
    public void hydrateWithCursor(Cursor inCursor)
    {
        int tempColumn = inCursor.getColumnIndex("tag_id");
        tagId = inCursor.getInt(tempColumn);

        tempColumn = inCursor.getColumnIndex("description");
        tagDescription = inCursor.getString(tempColumn);

        tempColumn = inCursor.getColumnIndex("tag_name");
        tagName = inCursor.getString(tempColumn);
        
        tempColumn = inCursor.getColumnIndex("editable");
        tagEditable = inCursor.getInt(tempColumn);

        tempColumn = inCursor.getColumnIndex("count");
        cardCount = inCursor.getInt(tempColumn);

/*
  // TODO We only care about getting new updates on data if we had data to begin with.
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagDidSave:) name:LWETagDidSave object:nil];
  _isFault = NO;
}
*/
    }  // end hydrateWithCursor()

    public String description()
    {
        StringBuilder tempBuilder = new StringBuilder();

        tempBuilder.append("<Tag.class>\n");
        tempBuilder.append("Editable: ").append(tagEditable).append("\n");
        tempBuilder.append("Name: ").append(tagName).append("\n");  
        tempBuilder.append("Description: ").append(tagDescription).append("\n");    
        tempBuilder.append("Tag Id: ").append(tagId).append("\n");  
        tempBuilder.append("Current Index: ").append(currentIndex).append("\n");    
        tempBuilder.append("CardIds: ").append(cardIds);    

        return tempBuilder.toString();
    }

    // basic getters/setters to replace @synthesize commands
    public void setId(int inId) 
    {
        tagId = inId;
    }

    public int getId()
    {
        return tagId;
    }

    public void setEditable(int inEditable)
    {
        tagEditable = inEditable;
    }

    public int getEditable()
    {
        return tagEditable;
    }

    public void setName(String inName)
    {
        tagName = inName;
    }

    public String getName()
    {
        return tagName;
    }

    public void setDescription(String inDescription)
    {
        tagDescription = inDescription;
    }

    public String getDescription()
    {
        return tagDescription;
    }

    public void setFault(boolean inFault)
    {
        isFault = inFault;
    }

    public boolean getFault()
    {
        return isFault;
    }

    public void setCardCount(int inCount)
    {
        // do nothing if the input is the same as
        // the existing cardCount
        if( cardCount == inCount )
        {
            return;
        }

        // update the database if this is not the first load
        // e.g. cardCount = -1
        if( cardCount >= 0 )
        {
            TagPeer.setCardCount(inCount,this);
        }   

        cardCount = inCount;

        return;
    }

    public int getCardCount()
    {
        return cardCount;
    }

    public void setCurrentIndex(int inIndex)
    {
        currentIndex = inIndex;
    }

    public int getCurrentIndex()
    {
        return currentIndex;
    }


}  // end Tag class declaration




