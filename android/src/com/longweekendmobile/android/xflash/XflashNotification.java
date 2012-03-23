package com.longweekendmobile.android.xflash;

//  XflashNotification.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public XflashNotification()
//
//  public void setCardIdPassed(int  )
//  public int getCardIdPassed()
//  public void setTagIdPassed(int  )
//  public int getTagIdPassed()
//
//  public void addNewTagObserver(Observer  )
//  public void newTagBroadcast(Tag  )
//  public void addActiveTagObserver(Observer  )
//  public void activeTagBroadcast()
//  public void addSubscriptionObserver(Observer  )
//  public void subscriptionBroadcast(Card  )
//  public void addTagSearchObserver(Observer  )
//  public void tagSearchBroadcast(Integer  )
//
//  private class NewTagNotifier extends Observable
//  private class ActiveTagNotifier extends Observable
//  private class SubscriptionNotifier extends Observable
//  private class TagSearchNotifier extends Observable

import java.util.Observable;
import java.util.Observer;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.Tag;

public class XflashNotification
{
    // private static final String MYTAG = "XFlash XflashNotification";
    
    public static final int NO_CARD_PASSED = -1000;
    
    private boolean cardWasAdded = false;
    private int cardIdPassed = NO_CARD_PASSED;
    private int tagIdPassed = -1000;

    private NewTagNotifier newTagObserver = null;
    private ActiveTagNotifier activeTagObserver = null;
    private SubscriptionNotifier subscriptionObserver = null;
    private TagSearchNotifier tagSearchObserver = null;
    
    public XflashNotification()
    {
        newTagObserver = new NewTagNotifier();
        activeTagObserver = new ActiveTagNotifier();
        subscriptionObserver = new SubscriptionNotifier();
        tagSearchObserver = new TagSearchNotifier();
    }
    
    // basic getters/setters for broadcasts
    public void setCardWasAdded(boolean wasAdded)
    {
        cardWasAdded = wasAdded;
    }

    public boolean getCardWasAdded()
    {
        return cardWasAdded;
    }

    public void setCardIdPassed(int inCardId)
    {
        cardIdPassed = inCardId;
    }

    public int getCardIdPassed()
    {
        return cardIdPassed;
    }

    public void setTagIdPassed(int inTagId)
    {
        tagIdPassed = inTagId;
    }

    public int getTagIdPassed()
    {
        return tagIdPassed;
    }


    // add observers and send messages
    public void addNewTagObserver(Observer inObserver)
    {
        newTagObserver.addObserver(inObserver);
    }
    public void newTagBroadcast(Tag inTag)
    {
        newTagObserver.broadcastNotification(inTag);
    }

    
    public void addActiveTagObserver(Observer inObserver)
    {
        activeTagObserver.addObserver(inObserver);
    }
    public void activeTagBroadcast()
    {
        activeTagObserver.broadcastNotification();
    }
   

    public void addSubscriptionObserver(Observer inObserver)
    {
        subscriptionObserver.addObserver(inObserver);
    }
    public void subscriptionBroadcast(Card inCard)
    {
        subscriptionObserver.broadcastNotification(inCard);
    }

    
    public void addTagSearchObserver(Observer inObserver)
    {
        tagSearchObserver.addObserver(inObserver);
    }
    public void tagSearchBroadcast(Integer inInteger)
    {
        tagSearchObserver.broadcastNotification(inInteger);
    }
   

    // Observable class to handle new tag notifications
    private class NewTagNotifier extends Observable
    {
        public NewTagNotifier()  { } 

        public void broadcastNotification(Tag inTag)
        {
            setChanged();
            notifyObservers(inTag);
        }

    }  // end NewTagNotifier class declaration

    
    // Observable class to handle start-studying notifications
    private class ActiveTagNotifier extends Observable
    {
        public ActiveTagNotifier()  { }

        public void broadcastNotification()
        {
            setChanged();
            notifyObservers();
        }

    }  // end ActiveTagNotifier class declaration


    // Observable class to handle subscription status changed notifications
    private class SubscriptionNotifier extends Observable
    {
        public SubscriptionNotifier()  { }

        public void broadcastNotification(Card inCard)
        {
            setChanged();
            notifyObservers(inCard);
        }

    }  // end SubscriptionNotifier class declaration
    
    
    // Observable class to handle new tag notifications
    private class TagSearchNotifier extends Observable
    {
        public TagSearchNotifier()  { }

        public void broadcastNotification(Integer inInteger)
        {
            setChanged();
            notifyObservers(inInteger);
        }

    }  // end TagSearchNotifier class declaration


}  // end XflashNotification class declaration




