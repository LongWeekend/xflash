package com.longweekendmobile.android.xflash.model;

//  JapaneseCard.java
//  Xflash
//
//  Created by Todd Presson on 1/17/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//
//  public JapaneseCard()
//
//  public void hydrate(Cursor  )       @over
//  public void hydrate(Cursor  ,boolean  ) @over 
//
//  public boolean hasExampleSentencesWithPluginManager(Context  )
//  public String reading(Context  )
//
//  public void setRomaji(String  )
//  public String getRomaji()
//
//  + all methods inherited from Card

import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;

public class JapaneseCard extends Card
{
    // private static final String MYTAG = "XFlash JapaneseCard";

    private String romaji;

    public JapaneseCard()
    {

    }

    // override of Card.hydrate(Cursor  ) that includes JapaneseCard
    // relevant columns from the database
    @Override
    public void hydrate(Cursor inCursor)
    {
        // make a call up the line to Card.hydrate(Cursor,  boolean)
        super.hydrate(inCursor,false);

        int tempColumn = inCursor.getColumnIndex("romaji");
        romaji = inCursor.getString(tempColumn);

        tempColumn = inCursor.getColumnIndex("headword");
        headword = inCursor.getString(tempColumn);
    }


    // override of Card.hydrate(Cursor  ) that includes JapaneseCard
    // relevant columns from the database
    @Override
    public void hydrate(Cursor inCursor,boolean isSimple)
    {
        // make a call up the line to Card.hydrate(Cursor,  boolean)
        super.hydrate(inCursor,isSimple);
        
        int tempColumn = inCursor.getColumnIndex("romaji");
        romaji = inCursor.getString(tempColumn);

        tempColumn = inCursor.getColumnIndex("headword");
        headword = inCursor.getString(tempColumn);
    }

    // returns 'true' if a card has example sentences attached to it
    // TODO - don't have adequate info to properly replace PluginManager
    public boolean hasExampleSentencesWithPluginManager()
    {
        boolean returnVal = false;

        // we always have a sentence if the plugin is not installed
        // if ([pluginManager pluginKeyIsLoaded:EXAMPLE_DB_KEY])
/*      
        if( false )
        {
            returnVal = ExampleSentencePeer.sentencesExistForCardId(cardId);
        }
*/

        return returnVal;

    }  // end hasExampleSentencesWithPluginManager(  )


    // depending on APP_READING value in SharedPreferences, will
    // return a combined reading
    public String reading(Context inContext)
    {
        String combinedReading;

        SharedPreferences settings = inContext.getSharedPreferences("XFlash",0);
        String tempString = settings.getString("APP_READING","fail");

        // mux the readings according to user preferences
        if( tempString.equals("SET_READING_KANA") )
        {
            combinedReading = hw_reading;
        }
        else if( tempString.equals("SET_READING_ROMAJI") )
        {
            combinedReading = romaji;
        }
        else
        {
            combinedReading = hw_reading + " - " + romaji;
        }

        return combinedReading;
    
    }  // end reading()
  
    // generic getters/setters
    public void setRomaji(String inRomaji)
    {
        romaji = inRomaji;
    }

    public String getRomaji()
    {
        return romaji;
    }

}  // end JapaneseCard class declaration




