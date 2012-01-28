package com.longweekend.android.jflash.model;

//  ExampleSentences.java
//  jFlash
//
//  Created by Todd Presson on 1/14/12.
//  Copyright 2012 LONG WEEKEND INC. All rights reserved.
//
//  represents a single example sentence in both English and Japanese
//  also has the "checked" flag to indicate whether or not the sentence
//  has been checked by a human after submission to the corpus.
//
//  public ExampleSentence()
//
//  public void hydrate(Cursor  )
//
//  public void setSentenceId(int  )
//  public int getSentenceId()
//  public void setChecked(int  )
//  public int getChecked()
//  public void setJa(String  )
//  public String getJa()
//  pubic void setEn(String  )
//  public String getEn()

import android.database.Cursor;

public class ExampleSentence
{
    // private static final String MYTAG = "JFlash ExampleSentence";

    int sentenceId;
    int checked;
    String sentenceJa;
    String sentenceEn;  

    public ExampleSentence()
    {
        sentenceId = 0;
        checked = 0;
        sentenceJa = null;
        sentenceEn = null;
    }


    // takes a sqlite Cursor  and populates the properties of the example sentence
    //
    //              expect that the incoming Cursor has already been 
    //              handled appropriately and prepared with moveToFirst()

    // TODO - has not been properly tested yet due to lack of appropriate database
    public void hydrate(Cursor inCursor)
    {
        int tempColumn = inCursor.getColumnIndex("sentence_id");
        sentenceId = inCursor.getInt(tempColumn);

        tempColumn = inCursor.getColumnIndex("checked");
        checked = inCursor.getInt(tempColumn);

        tempColumn = inCursor.getColumnIndex("sentence_ja");
        sentenceJa = inCursor.getString(tempColumn);

        tempColumn = inCursor.getColumnIndex("sentence_en");
        sentenceEn = inCursor.getString(tempColumn);
        
        // assume the Cursor will be closed by the calling method
        // we don't know if they're done with it yet
    }

    // generic getters/setters
    public void setSentenceId(int inId)
    {
        sentenceId = inId;
    }

    public int getSentenceId()
    {
        return sentenceId;
    }

    public void setChecked(int inCheck)
    {
        checked = inCheck;
    }

    public int getChecked()
    {
        return checked;
    }

    public void setJa(String inJa)
    {
        sentenceJa = inJa;
    }

    public String getja()
    {
        return sentenceJa;
    }

    public void setEn(String inEn)
    {
        sentenceEn = inEn;
    }

    public String getEn()
    {
        return sentenceEn;
    }

}  // end ExampleSentence class declaration


