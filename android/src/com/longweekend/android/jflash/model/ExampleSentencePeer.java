package com.longweekend.android.jflash.model;

//  ExampleSentencePeer.java
//  jFlash
//
//  Created by Todd Presson 1/14/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public ExampleSentencePeer()
//
//      *** ALL METHODS STATIC ***
//
//  public boolean isNewVersion()
//  public ArrayList<ExampleSentence> retrieveSentencesWithSQL(String  ,boolean  )
//  public ExampleSentence getExampleSentenceByPK(int  )
//  public ArrayList<ExampleSentence> getExampleSentencesByCardId(int  )
//  public boolean sentencesExistForCardId(int  )
//  public ArrayList<ExampleSentence> searchSentencesForKeyword(String  )

// TODO - this has not been tested!  I do not have a database copy
//        with the ExampleSentence object info in it

import java.util.ArrayList;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.longweekend.android.jflash.JFApplication;

// TODO - this class has not been properly tested due to lack of
//        sentence table in database to test on

public class ExampleSentencePeer
{
    private static final String MYTAG = "JFlash ExampleSentencePeer";

    private static SQLiteDatabase tempDB;

    public ExampleSentencePeer()
    {
        // we pass a context to the contructor in this case
        // because we don't know which method we'll be calling,
        // and don't want to pass contexts along a chain
        
        // get the dao
        tempDB = JFApplication.getWritableDao();
    }

    // TODO - really I have no idea what to do with this at this point
    public static boolean isNewVersion()
    {

/*
+ (BOOL) isNewVersion
{
#if defined (LWE_JFLASH)
  // Get plugin version
  BOOL isNewVersion = NO;
  // MMA TODO: 12/11/2011 -- this is a total hack, but it's no better than the [CurrentState..] static code
  // that was here before.  Point is, we need a way to just stop all this plugin versioning ridiculousness altogether.
  jFlashAppDelegate *appDelegate = (jFlashAppDelegate*)[[UIApplication sharedApplication] delegate];
  if ([[appDelegate.pluginManager versionForLoadedPlugin:EXAMPLE_DB_KEY] isEqualToString:@"1.2"])
  {
    isNewVersion = YES;
  }
  return isNewVersion;
#else
  return YES;
#endif
}
*/
        return false;

    }  // end isNewVersion()

    // returns an ArrayList of ExampleSentence objects based on input 'sql'
    // if willHydrate == true, the hydrate(Cursor  ) method will be called
    // on each ExampleSentence as it is added to the ArrayList
    public static ArrayList<ExampleSentence> retrieveSentencesWithSQL(String sql,boolean willHydrate)
    {
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

        if( isNewVersion() )
        {
            query = "SELECT s.* FROM sentences s, card_sentence_link l WHERE l.card_id = " + inId + " AND s.sentence_id = l.sentence_id AND l.should_show = 1 LIMIT 10";
        }
        else
        {
            query = "SELECT s.* FROM sentences s, card_sentence_link l WHERE l.card_id = " + inId + " AND s.sentence_id = l.sentence_id LIMIT 10";
        }

        return retrieveSentencesWithSQL(query,true);

    } // end getExampleSentencesByCardId()

    // returns true if example sentences exist for a given card Id, else false
    // if a card_sentence_link table record's should_show value is 0,
    // return false even if there is a link
    public static boolean sentencesExistForCardId(int inId)
    {
        String[] selectionArgs = new String[] { Integer.toString(inId) };
        String query;
        

        if( isNewVersion() )
        {
            // Version 1.2 example sentences DB
            query = "SELECT sentence_id FROM card_sentence_link WHERE card_id = ? AND should_show = '1' LIMIT 1";
        }
        else
        {
                // Version 1.1 example sentences DB
                query = "SELECT sentence_id FROM card_sentence_link WHERE card_id = ? LIMIT 1";
        }

        // TODO - waiting for debug
        Log.d(MYTAG,query);
        
        try
        {
            Cursor myCursor = tempDB.rawQuery(query,selectionArgs);

            // just making sure the query was successful
            int rowCount = myCursor.getCount();

            if( rowCount > 0 )
            {
                return true;
            }
            else
            {
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
        
        Log.d(MYTAG,"In Statement:  " + inStatement);

        String query;
        query = "SELECT DISTINCT(s.sentence_id), s.sentence_ja, s.sentence_en, s.checked FROM sentences s, card_sentence_link c WHERE s.sentence_id = c.sentence_id AND c.card_id IN (" + inStatement + ")";
            
        ArrayList<ExampleSentence> exampleSentences = new ArrayList<ExampleSentence>();

        exampleSentences = retrieveSentencesWithSQL(query,true);

        return exampleSentences;

    }  // end searchSentencesForKeyword() 



}  // end ExampleSentencePeer class declaration


