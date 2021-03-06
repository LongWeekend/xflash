package com.longweekendmobile.android.xflash.model;

//  Tag.java
//  Xflash
//
//  Created by Todd Presson on 1/16/12.
//  Copyright 2012 Long Weekend LLC.  All rights reserved.
//
//  public Card()
//  
//  public String meaningWithoutMarkup()
//  public String getMeaning()
//  public String getHeadword()
//  public String headwordIgnoringMode(boolean  ,Context  )
//  public AttributedString attributedReading()
//  public void hydrate()
//  public void hydrate(Cursor  )
//  public void hydrate(Cursor  ,boolean  )
//  public boolean isEqual(Card  )
//  public String tweetContent()
//
//  public void setCardId(int  )
//  public int getCardId()
//  public void setUserId(int  )
//  public int getUserId()
//  public void setLevelId(int  )
//  public int getLevelId()
//  public void setWrongCount(int  )
//  public int getWrongCount()
//  public void setRightCount(int  )
//  public int getRightCount()
//  public void setHeadword(String  )
//  public String getJustHeadword()
//  public void setHeadwordEN(String  )
//  public String getJustHeadwordEN()
//  public void setReading(String  )
//  public String getReading()
//  public void setMeaning(String  )
//  public String getJustMeaning()

import java.text.AttributedString;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.longweekendmobile.android.xflash.XFApplication;
import com.longweekendmobile.android.xflash.XflashSettings;

public class Card
{
    private static final String MYTAG = "XFlash Card";

    protected static final String kLWEFullReadingKey = "lwe_full_reading";
    protected static final String kLWESegmentedReadingKey = "lwe_segmented_reading";

    protected static final int kLWEUninitializedCardId = -1;
    protected static final int CARD_TYPE_WORD = 0;
    protected static final int CARD_TYPE_KANA = 1;
    protected static final int CARD_TYPE_KANJI = 2;
    protected static final int CARD_TYPE_DICTIONARY = 3;
    protected static final int CARD_TYPE_SENTENCE = 4;
    
    protected static final int LWE_TWITTER_MAX_CHARS = 132;
    protected static final String LWE_TWITTER_HASH_TAG = "#jflash";
   
    protected int cardId;
    protected int userId;
    protected int levelId;
    protected int wrongCount;
    protected int rightCount;

    protected String headword;
    protected String headword_en;
    protected String hw_reading;
    protected String meaning;

    // if true, this Card isn't really a Card -- just has an ID and 
    // hasn't been fetched
    public boolean isFault;

    public Card() 
    {
        isFault = true;
        cardId = kLWEUninitializedCardId;
    }

    // override of equals so this.equals() and ArrayList.contains() will
    // serve our purposes
    public boolean equals(Object obj)
    {
        // definitely equal if they are the same object
        if( this == obj )
        {
            return true;
        }

        if( ( obj == null ) || ( obj.getClass() != this.getClass() ) )
        {
            return false;
        }

        // in that case we know we were passed a Card
        Card tempCard = (Card)obj;

        // judge equality by card id numbers
        return ( this.cardId == tempCard.cardId ); 

    }  // end equals()


    // we must override hashCode() when overriding equals()
    public int hashCode()
    {
        int hash = 7;   // arbitrary

        hash = 31 * hash + cardId;

        return hash;
    
    }  // end hashCode()


    // returns the meaning field withotu any HTML markup... messy!
    public String meaningWithoutMarkup()
    {
        String tempMeaning = meaning;

        tempMeaning = tempMeaning.replace("</dfn><dfn>",",");
        tempMeaning = tempMeaning.replace("<dfn>","(");
        tempMeaning = tempMeaning.replace("</dfn>",")");
        tempMeaning = tempMeaning.replace("<li>","");
        tempMeaning = tempMeaning.replace("</li>","; ");
        tempMeaning = tempMeaning.replace("<ol>","");
        tempMeaning = tempMeaning.replace("</ol>","");
        tempMeaning = tempMeaning.replace(" ; ","; ");
 
        return tempMeaning;
    }

    // returns a String based on current language setting I THINK
    public String getMeaning()
    { 
        if( XflashSettings.getStudyLanguage() == XflashSettings.LWE_STUDYLANGUAGE_JAPANESE )
        {    
            return meaning;
        }
        else 
        { 
            return headword;
        }
        
    }  // end getMeaning()

    
    // return conditional headword
    public String getHeadword()
    {
        return headwordIgnoringMode(false);
    }

    //  CONTEXT IS ONLY NECESSARY FOR PREFERENCES
    //  this is a hack until Mark and Co. decide what to do about
    //  preprocessor directives
    public String headwordIgnoringMode(boolean isIgnore)
    {
        if( isIgnore )
        {
            return headword;
        }

        // if no APP_HEADWORD preferences has been set
        if( XflashSettings.getStudyLanguage() == XflashSettings.LWE_STUDYLANGUAGE_ENGLISH )
        { 
            return headword_en;
        }
        else
        {
            return headword;
        }   

    }  // end headwordIgnoringMode()


    // by default, just return the regular string
    public AttributedString attributedReading()
    {
        AttributedString tempAttrib = new AttributedString(hw_reading);

        return tempAttrib;
    }

    // gets a card from the DB and hydrates
    public void hydrate()
    {
        // get the dao
        SQLiteDatabase tempDB = XFApplication.getWritableDao();
  
        if( cardId == kLWEUninitializedCardId )
        {
            Log.d(MYTAG,"ERROR - hydrate() called on uninitialzied card");
        }

        // pull all data for current Card by Id
        // this query pulls the following columns:
        //  card_id, card_type, headword, headword_en, reading, romanji, meaning
        String[] selectionArgs = new String[] { Integer.toString(cardId) };
        String query = "SELECT c.*, h.meaning FROM cards c, cards_html h WHERE c.card_id = h.card_id AND c.card_id = ? LIMIT 1";

        Cursor myCursor = tempDB.rawQuery(query,selectionArgs);
        myCursor.moveToFirst();

        // passthrough
        hydrate(myCursor,true);

        myCursor.close();
    }

    // takes a sqlite Cursor and populates the properties of the Card including meaning
    public void hydrate(Cursor inCursor)
    {
        hydrate(inCursor,false);
    }


    // takes a sqlite Cursor and populates the properties of the card
    // gives the freedom of not including the meaning
    public void hydrate(Cursor inCursor,boolean isSimple)
    {
        int tempColumn = inCursor.getColumnIndex("card_id");
        cardId = inCursor.getInt(tempColumn);

        tempColumn = inCursor.getColumnIndex("reading");
        hw_reading = inCursor.getString(tempColumn);

        tempColumn = inCursor.getColumnIndex("meaning");
        meaning = inCursor.getString(tempColumn);

        tempColumn = inCursor.getColumnIndex("headword_en");
        headword_en = inCursor.getString(tempColumn);

        if( isSimple == false )
        {
            tempColumn = inCursor.getColumnIndex("card_level");
            levelId = inCursor.getInt(tempColumn);

            tempColumn = inCursor.getColumnIndex("user_id");
            userId = inCursor.getInt(tempColumn);

            tempColumn = inCursor.getColumnIndex("right_count");
            rightCount = inCursor.getInt(tempColumn);

            tempColumn = inCursor.getColumnIndex("wrong_count");
            wrongCount = inCursor.getInt(tempColumn);
        }

        isFault = false;
        
    }  // end hydrate(Cursor  ,boolean  )


    // compare incoming card to 'this' card
    public boolean isEqual(Card inCard)
    {
        return ( cardId == inCard.cardId );
    }

    
    // get the tweet word and try to cut the meaning so that it returns a String
    // that will fit within the allocation of twitter status update
    // returns String with format:  "headword [reading] meaning"
    public String tweetContent()
    {
        // String to return
        String tweetString = null;

        // get the lengths of everyone involved
        int headwordLength = headword.length();
        int readingLength = hw_reading.length();
        int meaningLength = meaningWithoutMarkup().length();
    
        // go from most conservative (headword exceeds LWE_TWITTER_MAX_CHARS) 
        // to most liberal (the whole thing fits in LWE_TWITTER_MAX_CHARS)  
        if( headwordLength > LWE_TWITTER_MAX_CHARS )
        {
            // headword alone is longer than twitter allowance
            tweetString = headword.substring(0,LWE_TWITTER_MAX_CHARS);
        }
        else
        {
            // add four, because we add brackets and spaces
            if( ( headwordLength + readingLength + 4 ) > LWE_TWITTER_MAX_CHARS )
            {
                // headword + reading is too long, so just use headword
                tweetString = headword;
            }
            else
            {
                tweetString = headword + " [" + hw_reading + "] ";
            }
        }
  
        // now determine if we have any space left for a meaning
        int charsLeftBeforeMeaning = ( LWE_TWITTER_MAX_CHARS - tweetString.length() );
  
        // If there are less than 5, just ignore - not worth it
        if( charsLeftBeforeMeaning > 5 )
        {
            String justMeaning = meaningWithoutMarkup();
            
            int charsLeftAfterMeaning = charsLeftBeforeMeaning - meaningLength; 
            
            // but in some cases, the "meaning" length, can exceed the maximum length
            // of the twitter update status lenght, so it looks for "/" and cut the meaning
            // to fit in. 
            if( charsLeftAfterMeaning < 0 )
            {
                int cutIndex = justMeaning.indexOf("/");

                if( ( cutIndex < 0 ) || ( cutIndex > charsLeftBeforeMeaning ) )
                {
                    // if the first meaning is too long, just truncate
                    cutIndex = charsLeftBeforeMeaning;
                }
                else
                {
                    // loop until we've got as many meanings as we can fit
                    // i.e. do stuff Mark and Co. were too lazy to implement ;)
                    while( true )
                    {
                        int newSlashIndex = justMeaning.indexOf("/", ( cutIndex + 1 ) );
                
                        if( ( newSlashIndex < 0 ) || ( newSlashIndex > charsLeftBeforeMeaning ) )
                        {
                            break;
                        }
                        else
                        {
                            cutIndex = newSlashIndex;
                        }
                    }
                }
                
                // when we have as many meanings as will fit in a tweet, concat
                // them onto the tweet string
                tweetString = tweetString + justMeaning.substring(0,cutIndex);
            }
            else
            {
                // we have enough room for the whole meaning
                tweetString = tweetString + justMeaning;
            }
        } 
       
        // add the hashtag
        tweetString = tweetString + " " + LWE_TWITTER_HASH_TAG;
         
        return tweetString;
    }

  
    // generic getters/setters
    public void setCardId(int inId)
    {
        cardId = inId;
    }

    public int getCardId()
    {
        return cardId;
    }

    public void setUserId(int inId)
    {
        userId = inId;
    }

    public int getUserId()
    {
        return userId;
    }

    public void setLevelId(int inId)
    {
        levelId = inId;
    }

    public int getLevelId()
    {
        return levelId;
    }

    public void setWrongCount(int inCount)
    {
        wrongCount = inCount;
    }

    public int getWrongCount()
    {
        return wrongCount;
    }

    public void setRightCount(int inCount)
    {
        rightCount = inCount;
    }

    public int getRightCount()
    {
        return rightCount;
    }

    public void setHeadword(String inWord)
    {
        headword = inWord;
    }

    public String getJustHeadword()
    {
        return headword;
    }

    public void setHeadwordEN(String inWord)
    {
        headword_en = inWord;
    }

    public String getJustHeadwordEN()
    {
        return headword_en;
    }

    public void setReading(String inWord)
    {
        hw_reading = inWord;
    }

    public String getReading()
    {
        return hw_reading;
    }

    public void setMeaning(String inWord)
    {
        meaning = inWord;
    }

    public String getJustMeaning()
    {
        return meaning;
    }

}  // end Card class declaration


// TODO - can't implement these until I know what's up with audio resources

/*

- (LWEAudioQueue *)playerWithPluginManager:(PluginManager *)pluginManager
{
  if (_player == nil)
  {
    NSDictionary *dict = [self audioFilenamesWithPluginManager:pluginManager];
    NSString *fullReadingFilename = [dict objectForKey:kLWEFullReadingKey];
    if (fullReadingFilename)
    {
      //If the full_reading key exists in the audioFilenames, it means there is an audio file
      // dedicated to this card.  So, just instantiate the AVQueuePlayer with the array
      NSURL *url = [NSURL fileURLWithPath:fullReadingFilename];
      _player = [[LWEAudioQueue alloc] initWithItems:[NSArray arrayWithObject:url]];
    }
    else
    {
      NSArray *segmentedReading = [dict objectForKey:kLWESegmentedReadingKey];
      NSMutableArray *items = [NSMutableArray arrayWithCapacity:[dict count]];
      for (NSString *filename in segmentedReading)
      {
        //Construct the filename for its audioFilename filename and instantiate the AVPlayerItem for it. 
        [items addObject:[NSURL fileURLWithPath:filename]];
      }
      // And create the player with the NSArray filled with the AVPlayerItem(s)
      _player = [[LWEAudioQueue alloc] initWithItems:items];
    }
  }
  return [_player autorelease];
}


- (BOOL) hasAudioWithPluginManager:(PluginManager *)mgr
{
  // It is up to the subclasses to handle this and say yes
  return NO;
}

- (NSDictionary *) audioFilenamesWithPluginManager:(PluginManager *)mgr
{
  // By default this does nothing, it is up to the subclasses to implement.
  return nil;
}

- (void) pronounceWithDelegate:(id)theDelegate pluginManager:(PluginManager *)pluginManager
{
  _player = [[self playerWithPluginManager:pluginManager] retain];
  _player.delegate = theDelegate;
  [_player play];
}

- (BOOL) hasExampleSentencesWithPluginManager:(PluginManager *)mgr;
{
  return NO;
}




+ (UIFont *) configureFontForLabel:(UILabel*)theLabel
{
#if defined (LWE_CFLASH)
  UIFont *theFont = theLabel.font;
  CGFloat currSize = theFont.pointSize;
  if (currSize == 0)
  {
    // Use default if not set
    currSize = FONT_SIZE_CELL_HEADWORD;
  }
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  
  // Don't change anything about the font if we're in English headword mode
  if ([[settings objectForKey:APP_HEADWORD] isEqualToString:SET_J_TO_E])
  {
    if ([[settings objectForKey:APP_HEADWORD_TYPE] isEqualToString:SET_HEADWORD_TYPE_TRAD])
    {
      theFont = [UIFont fontWithName:@"STHeitiTC-Medium" size:currSize];
    }
    else
    {
      theFont = [UIFont fontWithName:@"STHeitiSC-Medium" size:currSize];
    }
  }
  return theFont;
#else
  return theLabel.font;
#endif
}


*/
