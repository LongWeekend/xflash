package com.longweekendmobile.android.xflash.model;

//  ExampleSentencePeer.java
//  Xflash
//
//  Created by Todd Presson 1/14/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//      *** ALL METHODS STATIC ***
//
//  public ArrayList<ExampleSentence> retrieveSentencesWithSQL(String  ,boolean  )
//  public ExampleSentence getExampleSentenceByPK(int  )
//  public ArrayList<ExampleSentence> getExampleSentencesByCardId(int  )
//  public boolean sentencesExistForCardId(int  )
//  public ArrayList<ExampleSentence> searchSentencesForKeyword(String  )

import java.util.ArrayList;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.longweekendmobile.android.xflash.XFApplication;

public class ExampleSentencePeer
{
    private static final String MYTAG = "XFlash ExampleSentencePeer";

    // returns an ArrayList of ExampleSentence objects based on input 'sql'
    // if willHydrate == true, the hydrate(Cursor  ) method will be called
    // on each ExampleSentence as it is added to the ArrayList
    public static ArrayList<ExampleSentence> retrieveSentencesWithSQL(String sql,boolean willHydrate)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        ExampleSentence tempSentence = null;
        ArrayList<ExampleSentence> sentenceList = new ArrayList<ExampleSentence>();

        try
        {
            Cursor myCursor = tempDB.rawQuery(sql,null);

            int rowCount = myCursor.getCount();
            myCursor.moveToFirst();

            for(int i = 0; i < rowCount; i++)
            {
                tempSentence = new ExampleSentence();
                
                if( willHydrate )
                {
                    tempSentence.hydrate(myCursor);
                }   
                else
                {
                    int tempColumn = myCursor.getColumnIndex("sentence_id");
                    int tempId = myCursor.getInt(tempColumn);

                    tempSentence.setSentenceId(tempId);
                }
      
                sentenceList.add(tempSentence);
                myCursor.moveToNext();

            } // end for loop

            myCursor.close();

            // on success, return the ExampleSentence array
            return sentenceList;

        } 
        catch (Throwable t)
        {
            LWEDatabase.logQueryFail(MYTAG, t.toString() , "retrieveSentencesWithSQL()" );

            // on fail, return null
            return null;
        }

    }  // end retrieveSentencesWithSQL()


    // returns a single hydrated ExampleSentence object by sentenceId
    public static ExampleSentence getExampleSentenceByPK(int inId)
    {
        String query = "SELECT * FROM sentences WHERE sentence_id = " + inId;

        ArrayList<ExampleSentence> tempSentences;

        tempSentences = retrieveSentencesWithSQL(query,true);

        return tempSentences.get(0);
    }


    // returns all linked ExampleSentence objects for a given Card by cardId
    public static ArrayList<ExampleSentence> getExampleSentencesByCardId(int inId)
    {
        String query;

        query = "SELECT s.* FROM sentences s, card_sentence_link l WHERE l.card_id = " + inId + " AND s.sentence_id = l.sentence_id AND l.should_show = 1 LIMIT 10";

        return retrieveSentencesWithSQL(query,true);

    } // end getExampleSentencesByCardId()

    // returns true if example sentences exist for a given card Id, else false
    // if a card_sentence_link table record's should_show value is 0,
    // return false even if there is a link
    public static boolean sentencesExistForCardId(int inId)
    {
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
        
        // String[] selectionArgs = new String[] { Integer.toString(inId) };
        String query;
        

        // TODO - for reasons not fully understood, this ALWYAS returns 0 rows when
        //        used with selectionArgs rather than manually inserting inId
        query = "SELECT sentence_id FROM card_sentence_link WHERE card_id = " + inId + " AND should_show = '1' LIMIT 1";

        try
        {
            // Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
            Cursor myCursor = tempDB.rawQuery(query,null);

            // just making sure the query was successful
            int rowCount = myCursor.getCount();
            myCursor.close();

            if( rowCount > 0 )
            {
                // we have sentences!
                return true;
            }
            else
            {
                // no sentences for this card
                return false;
            }
        } 
        catch (Throwable t)
        {
            LWEDatabase.logQueryFail(MYTAG, t.toString() , "sentencesExistForCardId()" );
            
            return false;
        }

    }  // end sentencesExistForCardId()
  
    // returns an ArrayList of ExampleSentence objects after searching for 'keyword'
    public static ArrayList<ExampleSentence> searchSentencesForKeyword(String keyword,Context inContext)
    {
        ArrayList<Card> cardList = CardPeer.searchCardsForKeyword(keyword);

        // do a clever IN SQL statement!  Aha!
        int cardCount = cardList.size();
        StringBuilder inStatement = new StringBuilder();
        Card card;

        for(int i = 0; i < cardCount; i++)
        {
            card = cardList.get(i);

            if(i == 0)
            {
                inStatement.append( card.getCardId() );
            }
            else if( i > 0 )
            {
                inStatement.append(",").append( card.getCardId() ); 
            }   
        }
        
        String query;
        query = "SELECT DISTINCT(s.sentence_id), s.sentence_ja, s.sentence_en, s.checked FROM sentences s, card_sentence_link c WHERE s.sentence_id = c.sentence_id AND c.card_id IN (" + inStatement + ")";
            
        ArrayList<ExampleSentence> exampleSentences = new ArrayList<ExampleSentence>();

        exampleSentences = retrieveSentencesWithSQL(query,true);

        return exampleSentences;

    }  // end searchSentencesForKeyword() 



}  // end ExampleSentencePeer class declaration


