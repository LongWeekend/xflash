package com.longweekendmobile.android.xflash;

//  PracticeFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  public static void reveal()
//  public static void toggleReading()
//  public static void practiceClick(View  ,Xflash  )
//  public static void browseClick(View  ,Xflash  )
//  public static void goRight(Xflash  )
//  public static void setPracticeBlank()
//
//  private static class PracticeScreen
//
//      public static void initialize()
//      public static void setupPracticeView(int  )
//      public static void setAnswerBar(int  )
//      public static void toggleReading()
//
//  private static class CardSelector
//
//      public static int calculateNextCardLevelForTag(Tag  )
//      public static float calculateProbabilityOfUnseenWithcardsSeen()


import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.CardPeer;
import com.longweekendmobile.android.xflash.model.ExampleSentencePeer;
import com.longweekendmobile.android.xflash.model.JapaneseCard;
import com.longweekendmobile.android.xflash.model.LWEDatabase;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class PracticeFragment extends Fragment
{
    private static final String MYTAG = "XFlash PracticeFragment";
    
    // properties for handling color theme transitions
    private static RelativeLayout practiceLayout;

    public static final int PRACTICE_VIEW_BLANK = 0;
    public static final int PRACTICE_VIEW_BROWSE = 1;
    public static final int PRACTICE_VIEW_REVEAL = 2;

    private static int practiceViewStatus = -1;

    // the counts for the count bar at the top
    public static int[] cardCounts = { 1, 2, 3, 4, 5 };
    
    private static int totalCards = 0;
    private static int unseenCards = 0;

    private static int incomingTagId = -1000;
    private static int percentageRight = 100;

    private static Tag currentTag;
    private static JapaneseCard currentCard = null;

    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate the layout for our practice activity
        practiceLayout = (RelativeLayout)inflater.inflate(R.layout.practice, container, false);

        // TODO - debugging
        currentCard = (JapaneseCard)CardPeer.retrieveCardByPK(88020);
        
        // set up view based on current study mode
        if( XflashSettings.getStudyMode() == XflashSettings.LWE_STUDYMODE_PRACTICE )    
        {
            // if we're not revealed, reset to blank (in case of mode change)
            if( practiceViewStatus != PRACTICE_VIEW_REVEAL )
            {
                practiceViewStatus = PRACTICE_VIEW_BLANK;
            }
        }
        else  
        {
            practiceViewStatus = PRACTICE_VIEW_BROWSE;
        } 
    
        // load all view elements and set up based on view status
        PracticeScreen.initialize();
        PracticeScreen.setupPracticeView(practiceViewStatus);

        return practiceLayout;

    }  // end onCreateView()


    // called by other fragments when launching PracticeFragment
    // to start studying a new Tag
    public static void loadTag(int inId)
    {
        currentTag = TagPeer.retrieveTagById(inId);
        totalCards = currentTag.getCardCount();
        unseenCards = totalCards;
    }

    
    // called by Xflash when someone clicks 'tap for answer'
    public static void reveal()
    {
        PracticeScreen.setupPracticeView(PRACTICE_VIEW_REVEAL);
    }


    // called by Xflash when the reading is clicked on
    public static void toggleReading()
    {
        PracticeScreen.toggleReading();
    }
    
    
    // method called when any button in the options block is clicked
    public static void practiceClick(View v,Xflash inContext)
    {
        // load the next practice view without adding to the back stack
        XflashScreen.setPracticeOverride();
        practiceViewStatus = PRACTICE_VIEW_BLANK;
        inContext.onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);
    }


    // method called when any button in the options block is clicked
    public static void browseClick(View v,Xflash inContext)
    {
        switch( v.getId() )
        {
            case R.id.browseblock_last:     inContext.onScreenTransition("practice",XflashScreen.DIRECTION_CLOSE);
                                            break;
            case R.id.browseblock_actions:  break;
            case R.id.browseblock_next:     inContext.onScreenTransition("practice",XflashScreen.DIRECTION_OPEN);
                                            break;  
        } 
    }


    // method called when user click to queue the extra screen
    public static void goRight(Xflash inContext)
    {
        // load the ExampleSentenceFragment to the fragment tab manager
        ExampleSentenceFragment.loadCard(currentCard,cardCounts);
        inContext.onScreenTransition("example_sentence",XflashScreen.DIRECTION_OPEN);
    }


    // called by ExampleSentenceFragment to reset the view
    public static void setPracticeBlank()
    {
        practiceViewStatus = PRACTICE_VIEW_BLANK;
    }


    // class to manage screen setup
    private static class PracticeScreen
    {
        // used for toggle of reading view
        private static boolean readingTextVisible = false; 
       
        // all of the layout views
        private static ImageButton blankButton = null;
        private static ImageButton rightArrow = null;
        private static ImageButton showReadingButton = null;
        private static ImageView hhBubble = null;
        private static ImageView hhImage = null;
        private static ImageView miniAnswerImage = null;
        private static LinearLayout countBar = null;
        private static RelativeLayout browseFrame = null;
        private static RelativeLayout showFrame = null;
        private static TextView answerTextView = null;
        private static TextView headwordView = null;
        private static TextView hhView = null;
        private static TextView showReadingText = null;
        private static TextView[] cardCountViews = { null, null, null, null, null };

        public static void initialize()
        {
            // load the title bar and background elements and pass them to the color manager
            RelativeLayout practiceBack = (RelativeLayout)PracticeFragment.practiceLayout.findViewById(R.id.practice_mainlayout);
            XflashSettings.setupPracticeBack(practiceBack);
        
            // load the progress count bar
            countBar = (LinearLayout)practiceLayout.findViewById(R.id.count_bar);
            cardCountViews[0] = (TextView)practiceLayout.findViewById(R.id.study_num);
            cardCountViews[1] = (TextView)practiceLayout.findViewById(R.id.right1_num);
            cardCountViews[2] = (TextView)practiceLayout.findViewById(R.id.right2_num);
            cardCountViews[3] = (TextView)practiceLayout.findViewById(R.id.right3_num);
            cardCountViews[4] = (TextView)practiceLayout.findViewById(R.id.learned_num);
           
            refreshCountBar();
    
            // load the show-reading button
            showReadingButton = (ImageButton)PracticeFragment.practiceLayout.findViewById(R.id.practice_showreadingbutton);
            
            // load the show-reading text
            showReadingText = (TextView)PracticeFragment.practiceLayout.findViewById(R.id.practice_readingtext);
            showReadingText.setText( currentCard.reading() );

            // load the headword view
            headwordView = (TextView)PracticeFragment.practiceLayout.findViewById(R.id.practice_headword);
            headwordView.setText( currentCard.getHeadword() );
            
            // load the answer view
            answerTextView = (TextView)practiceLayout.findViewById(R.id.practice_answertext);
            
            if( XflashSettings.getStudyLanguage() == XflashSettings.LWE_STUDYLANGUAGE_JAPANESE )
            {
                // in Japanese, the answer is the meaning
                answerTextView.setText( currentCard.meaningWithoutMarkup() );
            }
            else
            {
                // in English, the answer is our Japanese headword
                answerTextView.setText( currentCard.headwordIgnoringMode(true) );
            }

            // load the mini answer button
            miniAnswerImage = (ImageView)practiceLayout.findViewById(R.id.practice_minianswer);
            
            // load the hot head
            hhImage = (ImageView)practiceLayout.findViewById(R.id.practice_hothead);
            
            // load the hot head's image bubble
            hhBubble = (ImageView)practiceLayout.findViewById(R.id.practice_hhbubble);
                
            // load the hot head percentage view
            hhView = (TextView)practiceLayout.findViewById(R.id.practice_talkbubble_text);
    
            // load the resources for the answer bar
            blankButton = (ImageButton)practiceLayout.findViewById(R.id.practice_answerbutton);
            browseFrame = (RelativeLayout)practiceLayout.findViewById(R.id.browse_options_block);
            rightArrow = (ImageButton)practiceLayout.findViewById(R.id.practice_rightbutton);
            showFrame = (RelativeLayout)practiceLayout.findViewById(R.id.practice_options_block);
       
            // if there is no tag loaded, go for Long Weekend Favorites
            if( currentTag == null )
            {
                currentTag = TagPeer.retrieveTagById(124);
            }
            
            // load the tag name
            TextView tempPracticeInfo = (TextView)practiceLayout.findViewById(R.id.practice_tag_name);
            tempPracticeInfo.setText( PracticeFragment.currentTag.getName() );

            // load the tag card count
            String tempString = Integer.toString( PracticeFragment.unseenCards );
            tempString = tempString + " / ";
            tempString = tempString + Integer.toString( PracticeFragment.totalCards );

            tempPracticeInfo = (TextView)practiceLayout.findViewById(R.id.practice_tag_count);
            tempPracticeInfo.setText(tempString);

        }  // end PracticeScreen.initialize()
        
        
        // set all TextView elements of the count bar to the current values
        public static void refreshCountBar()
        {
            for(int i = 0; i < 5; i++)
            {
                cardCountViews[i].setText( Integer.toString( PracticeFragment.cardCounts[i] ) );
            }
        }


        // set all widgets to the card-hidden state
        public static void setupPracticeView(int inViewMode)
        {
            if( inViewMode == PRACTICE_VIEW_BLANK )
            {
                // set up for blank view
                answerTextView.setVisibility(View.GONE);
                hhImage.setVisibility(View.VISIBLE);
                hhBubble.setVisibility(View.VISIBLE);
                hhView.setText( Integer.toString( PracticeFragment.percentageRight ) + "%" );
                hhView.setVisibility(View.VISIBLE);
                readingTextVisible = false;
                rightArrow.setVisibility(View.GONE);
                showReadingButton.setVisibility(View.VISIBLE);
                showReadingText.setVisibility(View.GONE);
            }
            else if( inViewMode == PRACTICE_VIEW_BROWSE )
            {
                // set up for browse view
                answerTextView.setVisibility(View.VISIBLE);
                countBar.setVisibility(View.GONE);
                hhImage.setVisibility(View.GONE);
                hhBubble.setVisibility(View.GONE);
                hhView.setVisibility(View.GONE);
                miniAnswerImage.setVisibility(View.GONE);
                readingTextVisible = false;
                rightArrow.setVisibility(View.GONE);
                showReadingButton.setVisibility(View.GONE);
                showReadingText.setVisibility(View.VISIBLE);
            }   
            else 
            {
                // set up for reveal
                answerTextView.setVisibility(View.VISIBLE);
                hhImage.setVisibility(View.VISIBLE);
                hhBubble.setVisibility(View.VISIBLE);
                hhView.setText( Integer.toString( PracticeFragment.percentageRight ) + "%" );
                hhView.setVisibility(View.VISIBLE);
                miniAnswerImage.setVisibility(View.GONE);
                readingTextVisible = true;
                showReadingButton.setVisibility(View.GONE);
                showReadingText.setVisibility(View.VISIBLE);
                showReadingText.setClickable(false);
                
                // only display the arrow if example sentences exist
                XFApplication.getDao().attachDatabase(LWEDatabase.DB_EX);
                if( ExampleSentencePeer.sentencesExistForCardId( currentCard.getCardId() ) )
                {
                    rightArrow.setVisibility(View.VISIBLE);
                }
                XFApplication.getDao().detachDatabase(LWEDatabase.DB_EX);

            }  // end if block for ( inViewMode )

            practiceViewStatus = inViewMode;
            setAnswerBar(practiceViewStatus);
    
        }  // end PracticeScreen.setupPracticeView()
    

        // method called when user taps to reveal the answer
        public static void setAnswerBar(int inMode)
        {
            // set what should be visible based on study mode
            switch(inMode)
            {
                case PRACTICE_VIEW_BLANK:   browseFrame.setVisibility(View.GONE);
                                            showFrame.setVisibility(View.GONE);
                                            blankButton.setVisibility(View.VISIBLE);
                                            break;
                case PRACTICE_VIEW_BROWSE:  blankButton.setVisibility(View.GONE);
                                            showFrame.setVisibility(View.GONE);
                                            browseFrame.setVisibility(View.VISIBLE);
                                            break;
                case PRACTICE_VIEW_REVEAL:  blankButton.setVisibility(View.GONE);
                                            browseFrame.setVisibility(View.GONE);
                                            showFrame.setVisibility(View.VISIBLE);
                                            break;
                default:    Log.d(MYTAG,"Error in PracticeScreen.setAnswerBar()  :  invalid study mode: " + inMode);
            } 

        }  // end PracticeScreen.setAnswerBar()


        // flip between 'show reading' button and the actual reading value
        public static void toggleReading()
        {
            if( readingTextVisible )
            {
                showReadingText.setVisibility(View.GONE);
                showReadingButton.setVisibility(View.VISIBLE); 
                readingTextVisible = false;
            }
            else
            {
                showReadingButton.setVisibility(View.GONE);
                showReadingText.setVisibility(View.VISIBLE);
                readingTextVisible = true;
            }
    
        }  // end PracticeScreen.toggleReading()


    }  // end PracticeScreen class declaration


    // class to determine the next cards to load
    private static class CardSelector
    {

        // calculates next card level based on current performance and Tag progress
        public static int calculateNextCardLevelForTag(Tag inTag)
        {

/*
- (NSInteger)calculateNextCardLevelForTag:(Tag *)tag error:(NSError **)error
{
  LWE_ASSERT_EXC(([tag.cardLevelCounts count] == 6),@"There must be 6 card levels (1-5 plus unseen cards)");
  
  // control variables
  // controls how many words to show from new before preferring seen words
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSInteger weightingFactor = [settings integerForKey:APP_FREQUENCY_MULTIPLIER];
  BOOL hideLearnedCards = [settings boolForKey:APP_HIDE_BURIED_CARDS];
  
  // Total number of cards in this set and its level
  NSInteger numLevels = 5;
  NSInteger unseenCount = [[tag.cardLevelCounts objectAtIndex:kLWEUnseenCardLevel] intValue];
  NSInteger totalCardsInSet = tag.cardCount;
  
  // This is a quick return case; if all cards are unseen, just return that
  if (unseenCount == totalCardsInSet)
  {
    return kLWEUnseenCardLevel;
  }

 //if the hide learned cards is set to ON. Try to simulate with the decreased numLevels (hardcoded)
  //and also tell that the totalCardsInSet is no longer the whole sets but the ones NOT in the buried section.
  if (hideLearnedCards)
  {
    // In this mode, we don't have 5 levels, we have four.
    numLevels = 4;
    
    // If all cards are learned, return "Learned" along with an error
    NSInteger learnedCount = [[tag.cardLevelCounts objectAtIndex:kLWELearnedCardLevel] intValue];
    totalCardsInSet = totalCardsInSet - learnedCount;
    if ((totalCardsInSet == 0) && (learnedCount > 0))
    {
      if (error != NULL)
      {
        *error = [NSError errorWithDomain:kTagErrorDomain code:kAllBuriedAndHiddenError userInfo:nil];
      }
      return kLWELearnedCardLevel;
    }
  }
  
  LWE_ASSERT_EXC(totalCardsInSet > 0, @"Beyond this point we assume we have some cards!");
   // Get m cards in n bins, figure out total percentages
  // Calculate different of weights and percentages and adjust accordingly
  NSInteger denominatorTotal = 0, weightedTotal = 0, cardsSeenTotal = 0, numeratorTotal = 0;
  
  // the guts to get the total of card seen so far
  NSInteger totalArray[6];
  for (NSInteger levelId = 1; levelId <= numLevels; levelId++)
  {
    // Get denominator values from cache/database
    NSInteger tmpTotal = [[tag.cardLevelCounts objectAtIndex:levelId] intValue];
    totalArray[levelId-1] = tmpTotal;   // all the level references (& the math) are 1-indexed, the array is 0 indexed
    cardsSeenTotal = cardsSeenTotal + tmpTotal;
    denominatorTotal = denominatorTotal + (tmpTotal * weightingFactor * (numLevels - levelId + 1)); 
    numeratorTotal = numeratorTotal + (tmpTotal * levelId);
  }
  
  CGFloat p_unseen = [self calculateProbabilityOfUnseenWithCardsSeen:cardsSeenTotal 
                                                          totalCards:totalCardsInSet
                                                           numerator:numeratorTotal 
                                                       levelOneCards:totalArray[0]];
    CGFloat randomNum = ((CGFloat)rand() / (CGFloat)RAND_MAX);
  CGFloat p = 0, pTotal = 0;
  //this for works like russian roulette where there is a 'randomNum' 
  //and each level has its own probability scaled 0-1 and if it sum-ed it would be 1.
  //this for enumerate through that level, accumulate the probability until it reach the 'randomNum'.
  for (NSInteger levelId = 1; levelId <= numLevels; levelId++)
  {
    // For this array, the levels are 0-indexed, so we have to minus one (see above)
    weightedTotal = (totalArray[levelId-1] * weightingFactor * (numLevels - levelId + 1));
    p = ((CGFloat)weightedTotal / (CGFloat)denominatorTotal);
    p = (1 - p_unseen) * p;
    pTotal = pTotal + p;
      if (pTotal > randomNum)
    {
          return levelId;
      }
  }
  
  // If we get here, that would be an error (we should return in the above for loop) -- fail with level unseen
  if (error != NULL)
  {
    *error = [NSError errorWithDomain:kTagErrorDomain code:kLWETagUnknownError userInfo:nil];
  }
  return kLWEUnseenCardLevel;
}

*/
            return 0;

        }  // end calculateNextCardLevelForTag()




        // calculate the probability of the unseen cards showing for th next 'round'
        // return the float ranegd 0-1 for the probability of unseen card showing next
        public static float calculateProbabilityOfUnseenWithcardsSeen()
        {

/*

- (CGFloat)calculateProbabilityOfUnseenWithCardsSeen:(NSUInteger)cardsSeenTotal totalCards:(NSUInteger)totalCardsInSet numerator:(NSUInteger)numeratorTotal levelOneCards:(NSUInteger)levelOneTotal
{
  NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
  NSInteger maxCardsToStudy = [settings integerForKey:APP_MAX_STUDYING];
  NSInteger weightingFactor = [settings integerForKey:APP_FREQUENCY_MULTIPLIER];
  LWE_ASSERT_EXC((maxCardsToStudy > 0), @"This value must be non-zero");
  LWE_ASSERT_EXC((weightingFactor > 0), @"This value must be non-zero");
  
  // Quick return of 0 probability if we've already seen all the cards in a set, or aren't taking any more
  if ((cardsSeenTotal == totalCardsInSet) || (levelOneTotal >= maxCardsToStudy))
  {
    return 0;
  }
  else
  {
    LWE_ASSERT_EXC((cardsSeenTotal < totalCardsInSet), @"To get to this point, there should be more cards in the set than cards seen");
    
    // Sets probability if we have less cards in the study pool than MAX allowed
    CGFloat p_unseen = 0, mean = 0;
    mean = (CGFloat)numeratorTotal / (CGFloat)cardsSeenTotal;
    p_unseen = (mean - 1.0f);
    p_unseen = pow((p_unseen / 4.0f), weightingFactor);
    p_unseen = p_unseen + (1.0f - p_unseen)*(pow((maxCardsToStudy - cardsSeenTotal),0.25)/pow(maxCardsToStudy,0.25));
    return p_unseen;
  }
}
*/

            return (float)0;
    
        }  // end calculateProbabilityOfUnseenWithcardsSeen()


    }  // end CardSelector class declaration




}  // end PracticeFragment class declaration





