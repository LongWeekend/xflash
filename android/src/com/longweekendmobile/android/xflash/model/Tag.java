package com.longweekendmobile.android.xflash.model;

//  Tag.java
//  Xflash
//
//  Created by Todd Presson on 1/8/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public Tag()
//  
//  public static boolean isEqual(Tag  )
//
//  public int groupId()
//  public boolean isEditable()
//  public int getSeenCardCount()
//  public boolean needShowAllLearned()
//  public void resetAllLearned()
//
//  public void recacheCardCountForEachLevel()
//  public ArrayList<ArrayList<Integer>> thawCards(Context  )
//  public void freezeCards()
//  public void populateCards()
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
//  public void setCardCount(int  )
//  public int getCardCount()
//  public void setCurrentIndex(int  )
//  public int getCurrentIndex()
//  public int incrementIndex()
//  public int decrementIndex()

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

import android.content.ContentValues;
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
    public static final int kLWEUnseenCardLevel = 0;
    public static final int kLWELearnedCardLevel = 5;
    public static final int DEFAULT_TAG_ID = 124;

    private boolean learnedShowedAlready;

    private int tagId;
    private int cardCount;
    private int currentIndex;
    private int tagEditable;

    public ArrayList<ArrayList<Card>> cardsByLevel;          
    public ArrayList<Card> flattenedCardArray;
    public ArrayList<Integer> cardLevelCounts;
    
    private String tagName;
    private String tagDescription;

    public Tag()
    {
        learnedShowedAlready = false;

        tagId = kLWEUninitializedTagId;
        cardCount = kLWEUninitializedCardCount; 
        
        cardsByLevel = null;
        cardLevelCounts = null;
        flattenedCardArray = null;
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

    
    // returns how many cards have been seen so far
    public int getSeenCardCount()
    {
        return ( cardCount - cardLevelCounts.get(kLWEUnseenCardLevel) );
    }


    // returns true if we need to show the all-learned alert (i.e. if they
    // have learned all cards, and it has NOT been shown yet
    public boolean needShowAllLearned()
    {
        boolean levelsAreZero = true;

        // check whether there are any cards in any non-learned level
        for(int i = 0; i < 5; i++)
        {
            if( cardsByLevel.get(i).size() > 0 )
            {
                levelsAreZero = false;
            }
        }

        if( levelsAreZero && !learnedShowedAlready )
        {
            // if all cards are learned and we haven't told the user yet
            learnedShowedAlready = true;

            return true;
        }
        else
        {
            // otherwise, don't show dialog
            return false;
        }

    }  // end needShowAllLearned()

    
    // called by PracticeFragment when user gets a card wrong, to ensure
    // the learned dialog is re-shown if necessary
    //
    // NOTE: Tags keep track of whether or not they have been shown due
    // to issues presented with PracticeFragment fully reloading on change
    public void resetAllLearned()
    {
        learnedShowedAlready = false;
    }


    // isEqual() simply returns a boolean confirming whether the
    // incoming Tag object has the same tagId as the THIS tag object
    public boolean isEqual(Tag inTag)
    {
        return ( tagId == inTag.tagId );        
    }


    // create a cache of the number of Card objects in each level
    public void recacheCardCountForEachLevel()
    {
        // if we have no cards to recache
        if( cardsByLevel == null )
        {
            Log.d(MYTAG,"ERROR - in recacheCardCountForEachLevel()");
            Log.d(MYTAG,"      - cardsByLevel is null");
        
            return;
        }
        
        // if our array is broken
        if( cardsByLevel.size() != 6 )
        {
            Log.d(MYTAG,"ERROR in recacheCardCountForEachlevel()");
            Log.d(MYTAG,"cardsByLevel.size() does not equal 6");

            return;
        }

        int count = 0;
        int totalCount = 0;

        ArrayList<Integer> cardLevelCountsTmp = new ArrayList<Integer>();

        // sort through all six card levels
        for(int i = 0; i < 6; i++)
        {
            count = cardsByLevel.get(i).size();
            cardLevelCountsTmp.add(count);
            totalCount = totalCount + count;
        }

        cardLevelCounts = cardLevelCountsTmp;
        cardCount = totalCount;
        
        return;

    }  // end recacheCardCountForEachLevel() 
   

    // executed when loading a new set on app load
    public void populateCards()
    {
        cardsByLevel = CardPeer.retrieveCardsSortedByLevelForTag(this);
        flattenedCardArray = flattenCardArrays();
        
        // populate card level counts
        recacheCardCountForEachLevel();

    }  // end populateCards

    
    // concatenate cardId arrays for browse mode
    public ArrayList<Card> flattenCardArrays()
    {
        ArrayList<Card> allCards = new ArrayList<Card>(cardCount);

        // cycle through all six levels for cardsByLevel
        for(int i = 0; i < 6; i++)
        {
            int temp2 = cardsByLevel.get(i).size();

            // run though each cardsByLevel level and add all cards
            for(int j = 0; j < temp2; j++)
            {
                allCards.add( cardsByLevel.get(i).get(j) );
            }
        }   

        // put in numeric order
        Collections.sort(allCards, new CardComparator() );

        return allCards;

    }  // end flattenCardArrays()


    private class CardComparator implements Comparator<Card>
    {
        public int compare(Card card1,Card card2)
        {
            return ( card1.getCardId() - card2.getCardId() );
        }
    }


    // update level counts cache - kept in memory how many cards are in each level
    public void moveCard(Card inCard,int nextLevel)
    {
        if( cardsByLevel.size() != 6 )
        {
            Log.d(MYTAG,"ERROR in moveCard()");
            Log.d(MYTAG,"cardsByLevel.size() does not equal 6");
        }

        int countBeforeRemove = 0;
        int countBeforeAdd = 0;
        ArrayList<Card> thisLevelCards = null;
        ArrayList<Card> nextLevelCards = null;

        // update the cardsByLevel if necessary
        if( nextLevel != inCard.levelId )
        {
            thisLevelCards = cardsByLevel.get( inCard.getLevelId() );
            nextLevelCards = cardsByLevel.get(nextLevel);
       
            countBeforeRemove = thisLevelCards.size();
            countBeforeAdd = nextLevelCards.size();

            // now do the remove
            if( !thisLevelCards.contains(inCard) )
            {
                Log.d(MYTAG,"ERROR in moveCard - card no longer there");
            }
    
            int tempInt = thisLevelCards.indexOf(inCard);
            thisLevelCards.remove(tempInt);
            int countAfterRemove = thisLevelCards.size();

            // only do the add if the remove was successful
            if( countBeforeRemove == (countAfterRemove + 1) )
            { 
                nextLevelCards.add(inCard);

                // and update the card's level id
                inCard.setLevelId(nextLevel);

                // now confirm the add
                int countAfterAdd = cardsByLevel.get(nextLevel).size();
                if( !((countAfterAdd - 1) == countBeforeAdd) )
                {
                    Log.d(MYTAG,"the number after add (" + countAfterAdd + ") should be 1 more than the count before add (" + countBeforeAdd + ")");
                }

                recacheCardCountForEachLevel();
            }

        }  // end if( nextLevel != inCard.levelId )

    }  // end moveCard()


    // removed card from tag's memory arrays so they are out of the set
    public void removeCardFromActiveSet(Card inCard)
    {
        // remove from cardsByLevel
        ArrayList<Card> cardLevel = cardsByLevel.get( inCard.getLevelId() );
        cardLevel.remove(inCard);        

        // remove from array of all cards
        flattenedCardArray.remove(inCard);

        recacheCardCountForEachLevel();

    }  // end removeCardFromActiveSet()


    // add card to tag's memory arrays
    public void addCardToActiveSet(Card inCard)
    {
        // add to card level
        ArrayList<Card> cardLevel = cardsByLevel.get( inCard.getLevelId() );
        cardLevel.add(inCard);
        
        // add to array of all cards
        flattenedCardArray.add(inCard);
        
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

        return;
    
    }  // end save()


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
        tempBuilder.append("CardIds: ").append(cardsByLevel);    

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
        if( currentIndex > flattenedCardArray.size() )
        {
            Log.d(MYTAG,"ERROR - in getCurrentIndex()");
            Log.d(MYTAG,"      - index:  " + currentIndex + " > array size:  " + flattenedCardArray.size() );
        }
        
        return currentIndex;

    }  // end getCurrentIndex()


    public int incrementIndex()
    {
        // if we're at the end of the array, wrap around
        if( currentIndex >= flattenedCardArray.size() - 1 )
        {
            currentIndex = 0;
        }
        else
        {
            ++currentIndex;
        }

        return currentIndex;
            
    }  // end incrementIndex()


    public int decrementIndex()
    {
        // if we're at the beginning of the array, wrap around
        if( currentIndex == 0 )
        {
            currentIndex = flattenedCardArray.size() - 1;
        }
        else
        {
            --currentIndex;
        }

        return currentIndex;

    }  // end decrementIndex()


}  // end Tag class declaration




