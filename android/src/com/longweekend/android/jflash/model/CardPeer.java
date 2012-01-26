package com.longweekend.android.jflash.model;

//  CardPeer.java
//  jFlash
//
//  Created by Todd Presson on 1/17/12.
//  Copyright 2012 LONG WEEKEND INC.. All rights reserved.
//
//  public CardPeer() 
//
//      *** ALL METHODS STATIC ***
//
//  public Card blankCardWithId(int  )
//  public Card blankCard()
//  public boolean keywordIsReading(String  )
//  public boolean keywordIsHeadword(String  )
//  public ArrayList<Card> searchCardsForKeyword(String  )
//
//  private String FTSSQLForKeyword(String  ,String  ,int  )
//  private Card retrieveCardWithCursor(Cursor  )
//  private ArrayList<Card> addCardsToList(ArrayList<Card>  ,Cursor  ,boolean  )
//  private Card retrieveCardByPK(int  )
//
//  public ArrayList<ArrayList<Integer>> retrieveCardIdsSortedByLevelForTag(Tag  )
//  public ArrayList<Card> retrieveFaultedCardsForTag(Tag  )
//  public ArrayList<Card> retrieveCardSetForExampleSentenceId(int  )
//
//  public void setJ(boolean  )

import java.util.ArrayList;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.longweekend.android.jflash.JFApplication;

public class CardPeer
{
    private static final String MYTAG = "JFlash CardPeer";

    // TODO - temporary fix until we understand what to do
    // with the preprocessor calls for language
    private static boolean isJ;

    private static SQLiteDatabase tempDB;

    public CardPeer()
    {
        // for our purposes, the same is #define JFLASH or whatever they did
        isJ = true;

        // get the dao
        tempDB = JFApplication.getWritableDao();
    }

    // factory that cares about what language we are using
    public static Card blankCardWithId(int inId)
    {
        Card tempCard;

        if( isJ )
        {
            tempCard = new JapaneseCard();
        }
        else
        {
            tempCard = new ChineseCard();
        }

        tempCard.setCardId(inId);
    
        return tempCard;    
    }


    // when we REALLY want a blank card
    public static Card blankCard()
    {
        Card tempCard = blankCardWithId(0);

        return tempCard;
    }


    // returns 'true' if the keyword appears to be reading-like.  note that
    // this implementation is specific to Chinese Flash, and would not work
    // for JFlash
    //
    // TODO - not tested in instances when it would return 'true'
    //        also, do we need a special unicode char variable?
    public static boolean keywordIsReading(String inKey)
    {
        if( isJ )
        {
            return false;
        }

        String[] keySplit = inKey.split(" ");

        // if any components are longer than 5 chars, it's not pinyin
        for( String key : keySplit )
        {
            if( key.length() > 5 )
            {
                return false;
            }
        }

        // okay, it has short bits, so make sure there's no kanji/hanzi
        boolean hasIdeograph = false;

        int tempInt = inKey.length();
        for(int charIndex = 0; charIndex < tempInt; charIndex++)
        {
            char testChar = inKey.charAt(charIndex);

            if(testChar >= 0x4E00)
            {
                hasIdeograph = true;
            }
        }

        return ( hasIdeograph == false );

    }  // end keywordIsReading()

    // TODO - see note on keywordIsReading() above
    public static boolean keywordIsHeadword(String inKey)
    {
        if( isJ )
        {
            return false;
        }

        // strip out numbers, symbols, and whitespace
        String keySplit[] = inKey.split("? ");

        for( String key : keySplit )
        {
            int tempInt = key.length();
            for(int charIndex = 0; charIndex < tempInt; charIndex++)
            {
                char testChar = key.charAt(charIndex);

                if( testChar < 0x2E80 || testChar > 0x9FFF )
                {
                    return false;
                }
            }   
        }

        return true;

    }  // end keywordIsHeadword()

    // returns an ArrayList of Card objects after searching for keyword
    // TODO - untested, need database with table cards_search_content
    public static ArrayList<Card> searchCardsForKeyword(String inKey)
    {
        ArrayList<Card> cardList = new ArrayList<Card>();
        int queryLimit = 100;
        String column = null;

        // do not hydrate these cards, we will flywheel it on the table view
        if( keywordIsHeadword(inKey) )
        {
            Log.d(MYTAG,"debug 1");
            column = "headword";
        }
        else if( keywordIsReading(inKey) )
        {
            Log.d(MYTAG,"debug 2");
            column = "reading";
        }

        String query = FTSSQLForKeyword(inKey,column,queryLimit);
        Cursor myCursor = tempDB.rawQuery(query,null);
        myCursor.moveToFirst();

        cardList = addCardsToList(cardList,myCursor,false);
        myCursor.close();

        // now, did we get enough cards, query 'content' column as well
        // (if it was a no-column search, don't re-run
        if( column != null && cardList.size() < queryLimit )
        {
            int newLimit = cardList.size() - queryLimit;
            
            query = FTSSQLForKeyword(inKey,"content",newLimit);
            myCursor = tempDB.rawQuery(query,null);
                
            cardList = addCardsToList(cardList,myCursor,false);
        }

        return cardList;

    }  // end searchCardsForKeyword()

    // this will return a SQL query that will return Card IDs from the FTS table
    // based on settings passed in
    // TODO - untested, we need database with table column card_search_content
    private static String FTSSQLForKeyword(String inKey,String inColumn,int inLimit)
    {
        // users understand '?' better than '*' ...  perhaps?
        String keywordWildcard = inKey.replace("*","?");
        String column;
        String searchString;

        if( inColumn != null )
        {
            // if we are searching for a specific column and not the
            // whole table, wrap it in quotes for exact match
            searchString = "\"" + keywordWildcard + "\"";
            column = inColumn;
        }
        else
        {
            searchString = keywordWildcard;
            column = "cards_search_content";
        }

        // do the search using SQLite FTS
        String query = "SELECT card_id FROM cards_search_content WHERE " + column + " MATCH '" + searchString + "' ORDER BY LENGTH(" + column + ") ASC, ptag DESC LIMIT " + inLimit;

        return query;

    }  // end FTSSQLForKeyword()

    // returns a single Card from the cursor, in case of multiple rows
    // will operate on the LAST one
    private static Card retrieveCardWithCursor(Cursor inCursor)
    {
        Card tempCard = blankCard();
    
        inCursor.moveToLast();
        tempCard.hydrate(inCursor);
        
        return tempCard;
    }


    // looping helper, populates an ArrayList of Cards, either lightweight or full
    private static ArrayList<Card> addCardsToList(ArrayList<Card> inList,Cursor inCursor,boolean shouldHydrate)
    {
        Card tempCard;
        int rowCount = inCursor.getCount();
        
        for(int i = 0; i < rowCount; i++)
        {
            if( shouldHydrate )
            {
                tempCard = blankCard();
                tempCard.hydrate(inCursor);
            }
            else
            {
                int tempColumn = inCursor.getColumnIndex("card_id");
                int tempInt = inCursor.getInt(tempColumn);

                tempCard = blankCardWithId(tempInt);
            }

            inList.add(tempCard);
            
        } // end for loop

        return inList;

    }  // end addCardsToList()

    // takes a cardId and returns a hydrated card from the database
    private static Card retrieveCardByPK(int inId)
    {
        // TODO - temporary in place of the following code
        //        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
        //    [settings objectForKey:@"user_id"]
        int debughold = 0;

        String[] selectionArgs = new String[] { Integer.toString(debughold), Integer.toString(inId) };
        String query = 
     "SELECT c.card_id AS card_id,u.card_level as card_level,u.user_id as user_id," +
     "u.wrong_count as wrong_count,u.right_count as right_count,c.*,ch.meaning " + 
     "FROM cards c INNER JOIN cards_html ch ON c.card_id = ch.card_id " + 
     "LEFT OUTER JOIN user_history u ON c.card_id = u.card_id AND u.user_id = ?" +
     "WHERE c.card_id = ch.card_id AND c.card_id = ?";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        Card tempCard = retrieveCardWithCursor(myCursor);
        myCursor.close();

        return tempCard;        
    }


    // returns an ArrayList of (int) Card ids for a given tagId
    // TODO - once again, why pass the entire Tag object when we just want a single int?
    // TODO - cannot test because we have no level_id columns in database
    public static ArrayList<ArrayList<Integer>> retrieveCardIdsSortedByLevelForTag(Tag inTag)
    {
        // TODO - temporary in place of the following code
        //        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
        //        [settings objectForKey:@"user_id"]
        int debughold = 0;

        ArrayList<ArrayList<Integer>> cardIdList = new ArrayList<ArrayList<Integer>>(6);

        for(int i = 0; i < 6; i++)
        {
            ArrayList<Integer> tempList = new ArrayList<Integer>();
            cardIdList.add(tempList);
        }
        
        String[] selectionArgs = new String[] { Integer.toString(debughold), Integer.toString( inTag.getId() ) };
        String query = "SELECT l.card_id AS card_id,u.card_level as card_level " +
                     "FROM card_tag_link l LEFT OUTER JOIN user_history u ON u.card_id = l.card_id " +
                     "AND u.user_id = ? WHERE l.tag_id = ?";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);

        int rowCount = myCursor.getCount();
        myCursor.moveToFirst();

        for(int i = 0; i < rowCount; i++)
        {
            int tempColumn = myCursor.getColumnIndex("card_level");
            int tempLevelId = myCursor.getInt(tempColumn);

            tempColumn = myCursor.getColumnIndex("card_id");
            int tempCardId = myCursor.getInt(tempColumn);

            cardIdList.get(tempLevelId).add(tempCardId);

            myCursor.moveToNext();
        }

        myCursor.close();

        return cardIdList;  

    }  // end retrieveCardIdsSortedByLevelForTag()

    // returns an ArrayList of cardId integers contained in the Tag inTag
    public static ArrayList<Card> retrieveFaultedCardsForTag(Tag inTag)
    {
        ArrayList<Card> tempList = new ArrayList<Card>();
        String[] selectionArgs = new String[] { Integer.toString( inTag.getId() ) };
        String query = "SELECT card_id FROM card_tag_link WHERE tag_id = ?";
    
        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        myCursor.moveToFirst();
        addCardsToList(tempList,myCursor,false);
        myCursor.close();

        return tempList;

    }  // end retrieveFaultedCardsForTag()

    // returns an ArrayList<Integer> of cardIds that are linked to the sentence
    // 'inId' primary key of the sentence to look up cards for
    // TODO - cannot be tested without db containing sentence tables
    // TODO - uh... the code actually returns an array of Card objects, not IDs
    //      - as the original comment would imply
    public static ArrayList<Card> retrieveCardSetForExampleSentenceId(int inId)
    {
        String query;
        String[] selectionArgs = new String[] { Integer.toString(inId) };
        ArrayList<Card> tempList = new ArrayList<Card>();

        if( ExampleSentencePeer.isNewVersion() )
        {
            query = "SELECT c.* FROM card_sentence_link l, cards c WHERE l.card_id = c.card_id AND sentence_id = ? AND l.should_show = '1'";
        }
        else
        {
                query = "SELECT c.* FROM card_sentence_link l, cards c WHERE l.card_id = c.card_id AND sentence_id = ?";
        }

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        int rowCount = myCursor.getCount();
        myCursor.moveToFirst();

        for(int i = 0; i < rowCount; i++)
        {
            Card tempCard = blankCard();
            tempCard.hydrate(myCursor,true);
            tempList.add(tempCard);

            myCursor.moveToNext();      
        }           

        myCursor.close();
        
        return tempList;

    }  // end retrieveCardSetForExampleSentenceId()

    // generic getter/setter for temporary isJ
    public static void setJ(boolean inJ)
    {
        isJ = inJ;
    }

    public static boolean getJ()
    {
        return isJ;
    }


}  // end CardPeer declaration




