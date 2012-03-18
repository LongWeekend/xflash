package com.longweekendmobile.android.xflash;

//  PracticeCardSelector.java
//  Xflash
//
//  Created by Todd Presson on 3/8/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//      *** ALL METHODS STATIC ***
//
//  public static void setNextPracticeCard(Tag  ,Card  )
//  public static void setBrowseCardByDirection(int  )
//  public static void setNextBrowseCard(Tag  ,int  )
//
//  private static Card randomCardInTag(Tag  ,Card  )
//  private static int calculateNextCardLevelForTag(Tag  )
//  private static float calculateProbabilityOfUnseenWithCardsSeen(int ,int ,int ,int )

import java.util.ArrayList;
import java.util.Random;
import java.lang.Math;
import android.util.Log;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.Tag;

public class PracticeCardSelector
{
    private static final String MYTAG = "XFlash PracticeCardSelector";
    private static final int NUM_CARDS_IN_NOT_NEXT_QUEUE = 5;
    private static final int NONRECENT_CARD_RETRIES = 3;

    private static ArrayList<Card> lastFiveCards = null;

    
    // sets the active card to the next card in line for practice mode
    public static void setNextPracticeCard(Tag inTag,Card inCard)
    {
        Card nextCard = randomCardInTag(inTag,inCard);


        // TODO - insert code below


        XflashSettings.setActiveCard(nextCard);

    }  // end setNextPracticeCard()

/*

  Card *nextCard = [self _randomCardInTag:cardSet currentCard:currentCard error:&error];
  
  // If necessary, tell the user they've learned this set
  if ((nextCard.levelId == kLWELearnedCardLevel) && (error.code == kAllBuriedAndHiddenError))
  {
    if (self.alreadyShowedLearnedAlert == NO)
    {
      [LWEUIAlertView notificationAlertWithTitle:NSLocalizedString(@"Study Set Learned", @"Study Set Learned")
                                         message:NSLocalizedString(@"Congratulations! You've already learned this set. We will show cards that would usually be hidden.",@"Congratulations! You've already learned this set. We will show cards that would usually be hidden.")
                                        delegate:self];
      self.alreadyShowedLearnedAlert = YES;
    }
  }
  else if (self.alreadyShowedLearnedAlert)
  {
    // This is used to "reset" the alert in the case that they had them all learned, and then got one wrong.
    self.alreadyShowedLearnedAlert = NO;
  }


*/


    // passthrough for setNextBrowseCard(Tag  ,Card  ,int  )
    public static void setBrowseCardByDirection(int inDirection)
    {
        Tag tempTag = XflashSettings.getActiveTag();

        setNextBrowseCard(tempTag,inDirection);
    }

    // TODO - this actually works, the rest of the class is untested

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

    
    // returns a random card (ideally not the last card - passed as argument)
    private static Card randomCardInTag(Tag inTag,Card inCard)
    {
        Random randGenerator = new Random();
        Card randomCard = null;
        
        if( inTag.cardsByLevel.size() != 6 )
        {
            Log.d(MYTAG,"ERROR - inRandomCardInTag() for: " + inTag.getName() );
            Log.d(MYTAG,"      - cardsByLevel.size() MUST be 6, instead is:  " + inTag.cardsByLevel.size() );
        }

        // make sure our previous card array is initialized
        if( lastFiveCards == null )
        {
            lastFiveCards = new ArrayList<Card>();
        }

        // get the next card level
        int nextLevelId = calculateNextCardLevelForTag(inTag);

        // get a random card offset
        ArrayList<Card> cardArray = inTag.cardsByLevel.get(nextLevelId);
        
        // see if calculateNextCardLevelForTag returned an empty level
        int numCardsAtLevel = cardArray.size();

        if( numCardsAtLevel < 1 )
        {
            Log.d(MYTAG,"ERROR - in randomCardInTag() for: " + inTag.getName() );
            Log.d(MYTAG,"      - cards at level " + nextLevelId + " don't exist!");
        }

        // yoink a card
        int randomOffset = Math.abs( randGenerator.nextInt() ) % numCardsAtLevel;
        
        randomCard = cardArray.get(randomOffset);

        // add the card we're leaving to lastFiveCards
        if( inCard != null )
        {
            lastFiveCards.add(inCard);
        }

        // TODO - wait a minute, wouldn't this technically mean that
        //      - that the array lastFiveCards is actually only holding
        //      - on to the last FOUR cards?  
        if( lastFiveCards.size() == NUM_CARDS_IN_NOT_NEXT_QUEUE )
        {
            lastFiveCards.remove(0);
        }

        // prevent getting the same card twice
        int whileIterator = 0;      // counts how many times we whiled against the array
        int duplicateIterator = 0;  // counts tries that return the same card as before

        // immediately bypassed if our randomCard is not in lastFiveCards
        while( lastFiveCards.contains(randomCard) )
        {
            Log.d(MYTAG,"pulled a card still in lastFiveCards");

            // if there is only one card left in the level, get a new level
            if( numCardsAtLevel == 1 )
            {
                // try up to five times to get a different level
                int lastNextLevel = nextLevelId;
                for(int i = 0; i < 5; i++)
                {
                    nextLevelId = calculateNextCardLevelForTag(inTag);
                    
                    if( nextLevelId != lastNextLevel )
                    {
                        // break out of for loop
                        break;
                    }
                }

            }  // end if( last card in level)

            // now get a different card randomly
            cardArray = inTag.cardsByLevel.get(nextLevelId);
            int numCardsAtLevel2 = cardArray.size();

            // see if calculateNextCardLevelForTag returned an empty level
            if( numCardsAtLevel2 < 1 )
            {
                Log.d(MYTAG,"ERROR - in randomCardInTag() for: " + inTag.getName() );
                Log.d(MYTAG,"      - cards at level2 " + nextLevelId + " don't exist!");
            }

            // yoink a new card
            randomOffset = Math.abs( randGenerator.nextInt() ) % numCardsAtLevel2;
            randomCard = cardArray.get(randomOffset);

            ++whileIterator;
            if( whileIterator > NONRECENT_CARD_RETRIES )
            {
                // the same card is worse than a card that was twice ago, 
                // so we check again that it's not that
                if( ( duplicateIterator == NONRECENT_CARD_RETRIES ) || 
                    ( inCard.equals(randomCard) == false ) )
                {
                    // we tried 3 times, fuck it
                    // (breaking out of while loop) 
                    break;
                }

                ++duplicateIterator;

            }  // end if( whileIterator > nonrecent card limit )

        }  // end while( lastFiveCards contains randomCard )

        if( randomCard.isFault )
        {
            randomCard.hydrate();
        }

        return randomCard;

    }  // end randomCardInTag()
    
    
    // calculates next card level based on current performance and Tag progress
    private static int calculateNextCardLevelForTag(Tag inTag)
    {
        if( inTag.cardLevelCounts.size() != 6 )
        {
            Log.d(MYTAG,"ERROR - in CardSelector.calculateNextCardLevelForTag()");
            Log.d(MYTAG,"      - inTag.cardLevelCounts.size() != 6");
        }

        // control variables
        int weightingFactor = XflashSettings.getFrequency();

        boolean hideLearnedCards = XflashSettings.getHideLearned();

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
    private static float calculateProbabilityOfUnseenWithCardsSeen(int cardsSeenTotal,
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


}  // end PracticeCardSelector class declaration


