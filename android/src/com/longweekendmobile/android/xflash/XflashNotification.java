package com.longweekendmobile.android.xflash;

//  XflashNotification.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//

import java.util.Observable;
import java.util.Observer;

import com.longweekendmobile.android.xflash.model.Card;
import com.longweekendmobile.android.xflash.model.Tag;

public class XflashNotification
{
    // private static final String MYTAG = "XFlash XflashNotification";
    
    public static NewTagNotifier newTagObserver = null;
    public static SubscriptionNotifier subscriptionObserver = null;

    public static final int NO_CARD_PASSED = -1000;
    private static int cardIdPassed = NO_CARD_PASSED;
    private static int tagIdPassed = -1000;

    public XflashNotification()
    {
        newTagObserver = new NewTagNotifier();
        subscriptionObserver = new SubscriptionNotifier();
    }

    public void addNewTagObserver(Observer inObserver)
    {
        newTagObserver.addObserver(inObserver);
    }

    public void newTagBroadcast(Tag inTag)
    {
        newTagObserver.broadcastNotification(inTag);
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


    public void addSubscriptionObserver(Observer inObserver)
    {
        subscriptionObserver.addObserver(inObserver);
    }

    public void subscriptionBroadcast(Card inCard)
    {
        subscriptionObserver.broadcastNotification(inCard);
    }

    
    // Observable class to handle new tag notifications
    public class NewTagNotifier extends Observable
    {
        public NewTagNotifier()
        {

        }

        public void broadcastNotification(Tag inTag)
        {
            setChanged();
            notifyObservers(inTag);
        }

    }  // end NewTagNotifier class declaration

    
    // Observable class to handle subscription status changed notifications
    public class SubscriptionNotifier extends Observable
    {
        public SubscriptionNotifier()
        {

        }

        public void broadcastNotification(Card inCard)
        {
            setChanged();
            notifyObservers(inCard);
        }

    }  // end SubscriptionNotifier class declaration


}  // end XflashNotification class declaration




