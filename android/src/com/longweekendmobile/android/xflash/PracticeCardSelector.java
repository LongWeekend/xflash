package com.longweekendmobile.android.xflash;

//  PracticeCardSelector.java
//  Xflash
//
//  Created by Todd Presson on 3/8/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public static int calculateNextCardLevelForTag(Tag  )
//  public static float calculateProbabilityOfUnseenWithCardsSeen()
//
//  public static void setNextBrowseCard(Tag  ,Card,  ,int  )

import java.util.Random;

import android.util.Log;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.Tag;

public class PracticeCardSelector
{
    private static final String MYTAG = "XFlash PracticeCardSelector";
    
    // calculates next card level based on current performance and Tag progress
    public static int calculateNextCardLevelForTag(Tag inTag)
    {
        if( inTag.cardLevelCounts.size() != 6 )
        {
            Log.d(MYTAG,"ERROR - in CardSelector.calculateNextCardLevelForTag()");
            Log.d(MYTAG,"      - inTag.cardLevelCounts.size() != 6");
        }

        // control variables
        int weightingFactor = XflashSettings.getFrequency();

        // TODO - not sure where this settings is coming from
        // BOOL hideLearnedCards = [settings boolForKey:APP_HIDE_BURIED_CARDS];
        boolean hideLearnedCards = false;

        int numLevels = 5;
        int unseenCount = inTag.cardLevelCounts.get(Tag.kLWEUnseenCardLevel);
        int totalCardsInSet = inTag.getCardCount();

        // this is a quick return case; if all cards are unseen, just return that
        if( unseenCount == totalCardsInSet )
        {
            return Tag.kLWEUnseenCardLevel;
        }

        // if the hide learned cards is set to ON. Try to simulate with the decreased 
        // numLevels (hardcoded) and also tell that the totalCardsInSet is no longer 
        // the whole sets but the ones NOT in the buried section.
        if (hideLearnedCards)
        {
            // In this mode, we don't have 5 levels, we have four.
            numLevels = 4;

            // If all cards are learned, return "Learned" along with an error
            int learnedCount = inTag.cardLevelCounts.get(Tag.kLWELearnedCardLevel);

            totalCardsInSet = totalCardsInSet - learnedCount;
            if( (totalCardsInSet == 0) && (learnedCount > 0) )
            {
                return Tag.kLWELearnedCardLevel;
            }
        }  // end if(hideLearnedCards)

        // past here, we assume we have cards to work with
        if( totalCardsInSet <= 0 )
        {
            Log.d(MYTAG,"ERROR - in CardSelector.calculateNextCardLevelForTag()");
            Log.d(MYTAG,"      - totalCardsInSet is less than 1");
        }

        // Get m cards in n bins, figure out total percentages
        // Calculate different of weights and percentages and adjust accordingly
        int denominatorTotal = 0;
        int weightedTotal = 0;
        int cardsSeenTotal = 0;
        int numeratorTotal = 0;

        // the guts to get the total of card seen so far
        int[] totalArray = { 0,0,0,0,0,0 };

        for(int levelId = 1; levelId <= numLevels; levelId++)
        {
            // Get denominator values from cache/database
            int tmpTotal = inTag.cardLevelCounts.get(levelId);

            // all the level references (& the math) are 1-indexed, the array is 0 indexed 
            totalArray[levelId-1] = tmpTotal;
            cardsSeenTotal = cardsSeenTotal + tmpTotal;
            denominatorTotal = denominatorTotal + (tmpTotal * weightingFactor * (numLevels - levelId + 1));
            numeratorTotal = numeratorTotal + (tmpTotal * levelId);
        }
        float p_unseen = calculateProbabilityOfUnseenWithCardsSeen(cardsSeenTotal,
                                    totalCardsInSet,numeratorTotal,totalArray[0]);
        float randomNum = new Random().nextFloat();
        float p = 0;
        float pTotal = 0;

        // this for works like russian roulette where there is a 'randomNum' and 
        // each level has its own probability scaled 0-1 and if it sum-ed it would be 1.
        // this for enumerate through that level, accumulate the probability 
        // until it reach the 'randomNum'
        for (int levelId = 1; levelId <= numLevels; levelId++)
        {
            // For this array, the levels are 0-indexed, so we have to minus one (see above)
            weightedTotal = ( totalArray[levelId-1] * weightingFactor * ( numLevels - levelId + 1) );
            p = ( (float)weightedTotal / (float)denominatorTotal );
            p = (1 - p_unseen) * p;
            pTotal = pTotal + p;
            if( pTotal > randomNum )
            {
                return levelId;
            }
        }

        // If we get here, that would be an error (we should return in the above for 
        // loop) -- fail with level unseen
        return Tag.kLWEUnseenCardLevel;

    }  // end calculateNextCardLevelForTag()


    // calculate the probability of the unseen cards showing for th next 'round'
    // return the float ranegd 0-1 for the probability of unseen card showing next
    public static float calculateProbabilityOfUnseenWithCardsSeen(int cardsSeenTotal,
                                int totalCardsInSet,int numeratorTotal,int levelOneTotal)
    {
        int maxCardsToStudy = XflashSettings.getStudyPool();
        int weightingFactor = XflashSettings.getFrequency();

        if( ( maxCardsToStudy < 1 ) || ( weightingFactor < 1 ) )
        {
            Log.d(MYTAG,"ERROR - in calculateProbabilityOfUnseenWithCardsSeen()");
            Log.d(MYTAG,"      - bad value for maxCardsToStudy or weightingFactor");
        }

        if( ( cardsSeenTotal == totalCardsInSet ) || ( levelOneTotal >= maxCardsToStudy ) )
        {
            return 0;
        }
        else
        {
            if( cardsSeenTotal > totalCardsInSet);
            {
                Log.d(MYTAG,"ERROR - in calculateProbabilityOfUnseenWithCardsSeen()");
                Log.d(MYTAG,"      - cardsSeenTotal is greater than totalCardsInSet");
            }

            // Sets probability if we have less cards in the study pool than MAX allowed
            float p_unseen = 0;
            float mean = 0;
            mean = ( (float)numeratorTotal / (float)cardsSeenTotal );
            p_unseen = (mean - 1.0f);
            p_unseen = (float)Math.pow( (p_unseen / 4.0f), weightingFactor);
            p_unseen = p_unseen + (1.0f - p_unseen) * ( (float)Math.pow( (maxCardsToStudy - cardsSeenTotal),0.25) / (float)Math.pow(maxCardsToStudy,0.25) );

            return p_unseen;
        }

    }  // end calculateProbabilityOfUnseenWithCardsSeen()

  
    // passthrough for setNextBrowseCard(Tag  ,Card  ,int  )
    public static void setBrowseCardByDirection(int inDirection)
    {
        Tag tempTag   = XflashSettings.getActiveTag();

        setNextBrowseCard(tempTag,inDirection);
    }

    
    // set the active card to the next in currentTag, by direction
    public static void setNextBrowseCard(Tag currentTag,int inDirection)
    {
        Card nextCard = null;
        int currentIndex = currentTag.getCurrentIndex();

        if( inDirection == XflashScreen.DIRECTION_NULL )
        {
            // that means we're on the first card, (or haven't moved )
            // use the tag's currentIndex
            nextCard = currentTag.flattenedCardArray.get(currentIndex);
        }
        else
        {
            // We already have a card, so get the next card based on the current index
            if( inDirection == XflashScreen.DIRECTION_CLOSE )
            {
                // if we are closing (going back), get the previous card 
                currentIndex = currentTag.decrementIndex();
            }
            else 
            {
                // if we are opening (going forward), get the next card
                currentIndex = currentTag.incrementIndex();
            }
    
            // OK, we've updated currentIndex, get the new card
            nextCard = currentTag.flattenedCardArray.get(currentIndex);
        }
  
        // Now, if we have a faulted card, hydrate it
        if( nextCard.isFault )
        {
            nextCard.hydrate();
        }
       
        XflashSettings.setActiveCard(nextCard);

    }  // end setNextBrowseCard()


}  // end PracticeCardSelector class declaration


