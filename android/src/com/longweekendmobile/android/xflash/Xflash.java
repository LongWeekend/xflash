package com.longweekendmobile.android.xflash;

//  Xflash.java
//  Xflash
//
//  Created by Todd Presson on 1/7/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  protected void onCreate(Bundle  )               @over
//  protected void onSaveInstanceState(Bundle  )    @over
//  public void onBackPressed()                     @over
//
//  *** METHODS CALLED BY FRAGMENTS ***
//
//  public void PracticeFragment_reveal(View  )
//  public void PracticeFragment_practiceClick(View  )
//  public void PracticeFragment_browseClick(View  )
//  public void PracticeFragment_goRight(View  )
//
//  public void TagFragment_addTag(View  )
//
//  public void SettingsFragment_switchStudyMode(View  )
//  public void SettingsFragment_switchStudyLanguage(View  )
//  public void SettingsFragment_switchReadingMode(View  )
//  public void SettingsFragment_goDifficulty(View  )
//  public void SettingsFragment_advanceColorScheme(View  )
//
//  public void DifficultyFragment_goBackToSettings(View  )
//
//  public void HelpFragment_goAskUs(View  )
//  public static void HelpFragment_pullHelpTopic(int  )
//
//  public void HelpPageFragment_goBackToHelp(View  )
//  public void HelpPageFragment_helpNext(View  )
//
//  *** TAB FRAGMENT FUNCTIONALITY ***
//
//  class TabFactory implements TabContentFactory
//
//  private void initializeTabHost(Bundle  )
//  private static void addTab(Xflash  ,TabHost  ,TabHost.TabSpec  ,TabInfo  )
//
//  public void onTabChanged(String  )
//  public void onScreenTransition(String  )

import java.util.HashMap;

import android.content.Context;
import android.content.res.Resources;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentTransaction;
import android.util.Log;
import android.view.View;
import android.widget.TabHost;
import android.widget.TabHost.TabContentFactory;

public class Xflash extends FragmentActivity implements TabHost.OnTabChangeListener
{
    private static final String MYTAG = "XFlash main";
   
    private static Xflash myContext;
 
    // properties for our fragment tab management
    private TabHost myTabHost;
    private static HashMap<String, TabInfo> mapTabInfo = new HashMap<String, TabInfo>();
    private TabInfo currentTab = null;


    /** Called when the activity is first created. */
    // see android.support.v4.app.FragmentActivity#onCreate(android.os.Bundle)
    @Override
    protected void onCreate(Bundle savedInstanceState) 
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        
        // set up all of our persistence settings, screen manager, and tab host
        XflashSettings.load();
        XflashScreen.fireUpScreenManager();
        initializeTabHost(savedInstanceState);
        
        // if we're coming back from a stop, queue the previously open tab
        if( savedInstanceState != null )
        {
            myTabHost.setCurrentTabByTag(savedInstanceState.getString("tab")); 
        }

        myContext = this;
       
    }  // end onCreate


    // see android.support.v4.app.FragmentActivity#onSaveInstanceState(android.os.Bundle)
    @Override
    protected void onSaveInstanceState(Bundle outState)
    {
        // save the currently open tab 
        outState.putString("tab", myTabHost.getCurrentTabTag());
        super.onSaveInstanceState(outState);
    }

    
    @Override
    public void onBackPressed()
    {
        String newTabTag = XflashScreen.goBack(currentTab.tag);

        // if the screen manager returned a fragment to go-back to (or exit)
        if( newTabTag != null )
        {
            onScreenTransition(newTabTag); 
        }
        else if( currentTab.tag != "practice" )
        {
            // take them back to the opening screen before exiting
            onTabChanged("practice"); 
            myTabHost.setCurrentTabByTag("practice");
        } 
        else
        {
            // exit the app
            super.onBackPressed();
        }
    }


// passthroughs for methods called by onClick declarations in Fragments

    public void PracticeFragment_reveal(View v)
    {
        PracticeFragment.reveal();
    }
    public void PracticeFragment_practiceClick(View v)
    {
        PracticeFragment.practiceClick(v);
    }
    public void PracticeFragment_browseClick(View v)
    {
        PracticeFragment.browseClick();
    }
    public void PracticeFragment_goRight(View v)
    {
        PracticeFragment.goRight();
    }

    public void TagFragment_addTag(View v)
    {
        TagFragment.addTag(this);
    }

    public void SettingsFragment_switchStudyMode(View v)
    {
        SettingsFragment.switchStudyMode();
    }
    public void SettingsFragment_switchStudyLanguage(View v)
    {
        SettingsFragment.switchStudyLanguage();
    }
    public void SettingsFragment_switchReadingMode(View v)
    {
        SettingsFragment.switchReadingMode();
    }
    public void SettingsFragment_goDifficulty(View v)
    {
        SettingsFragment.goDifficulty(this);
    }
    public void SettingsFragment_advanceColorScheme(View v)
    {
        SettingsFragment.advanceColorScheme();
    }

    public void DifficultyFragment_goBackToSettings(View v)
    {
        DifficultyFragment.goBackToSettings(this);
    }

    public void HelpFragment_goAskUs(View v)
    {
        HelpFragment.goAskUs(this);
    }
    public static void HelpFragment_pullHelpTopic(int inId)
    {
        HelpFragment.pullHelpTopic(inId,myContext);
    }
    
    public void HelpPageFragment_goBackToHelp(View v)
    {
        HelpPageFragment.goBackToHelp(myContext);
    }
    public void HelpPageFragment_helpNext(View v)
    {
        HelpPageFragment.helpNext();
    } 

// nearly all of the following code is resued or modified from the example 
// (and associated github project) following:
//
// http://thepseudocoder.wordpress.com/2011/10/04/android-tabs-the-fragment-way/
// https://github.com/mitchwongho/Andy

    class TabFactory implements TabContentFactory
    {
        private final Context mContext;

        public TabFactory(Context context)
        {
            mContext = context;
        }
        
        public View createTabContent(String tag)
        {
            View v = new View(mContext);
            v.setMinimumWidth(0);
            v.setMinimumHeight(0);
            
            return v;
        }
    }
    
    
    // initalize our tab host, which is  Xflash.myTabhost  , a top level class property
    private void initializeTabHost(Bundle args)
    {
        myTabHost = (TabHost)findViewById(android.R.id.tabhost);
        myTabHost.setup();
        
        TabHost.TabSpec spec;
        TabInfo tabInfo = null;
        
        // Resources object to grab our tab drawables
        Resources res = getResources();     
        
        // create a tab spec, give it a in internal label, a label for the view, and a drawable
        // add the tab to our tab host, thus adding it to the app's primary view
        // add the new fragment's TabInfo object to our HashMap used for tab navigation 

        // add the Practice tab
        spec = this.myTabHost.newTabSpec("practice").setIndicator("Practice", res.getDrawable(R.drawable.practice_flip));
        Xflash.addTab(this, this.myTabHost, spec, ( tabInfo = new TabInfo("practice", PracticeFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);
 
        // add the Study Sets tab
        spec = this.myTabHost.newTabSpec("tag").setIndicator("Study Sets", res.getDrawable(R.drawable.tags_flip));
        Xflash.addTab(this, this.myTabHost, spec, ( tabInfo = new TabInfo("tag", TagFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        // add the Search tab
        spec = this.myTabHost.newTabSpec("search").setIndicator("Search", res.getDrawable(R.drawable.search_flip));
        Xflash.addTab(this, this.myTabHost, spec, ( tabInfo = new TabInfo("search", SearchFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        // add the Search tab
        spec = this.myTabHost.newTabSpec("settings").setIndicator("Settings", res.getDrawable(R.drawable.settings_flip));
        Xflash.addTab(this, this.myTabHost, spec, ( tabInfo = new TabInfo("settings", SettingsFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        // add the Search tab
        spec = this.myTabHost.newTabSpec("help").setIndicator("Help", res.getDrawable(R.drawable.help_flip));
        Xflash.addTab(this, this.myTabHost, spec, ( tabInfo = new TabInfo("help", HelpFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);


        // default to displaying the first tab on start
        this.onTabChanged("practice");
        myTabHost.setOnTabChangedListener(this);

    }  // end initializeTabHost()

    
    // adds new tab to the tab host, to be displayed on the primary view
    private static void addTab(Xflash activity, TabHost tabHost, TabHost.TabSpec tabSpec, TabInfo tabInfo)
    {
        // Attach a Tab view factory to the spec
        tabSpec.setContent(activity.new TabFactory(activity));
        String tag = tabSpec.getTag();

        // Check to see if we already have a fragment for this tab, probably
        // from a previously saved state.  If so, detach it, because our
        // initial state is that a tab isn't shown.
        tabInfo.fragment = activity.getSupportFragmentManager().findFragmentByTag(tag);
        
        if( tabInfo.fragment != null && !tabInfo.fragment.isDetached() )
        {
            FragmentTransaction ft = activity.getSupportFragmentManager().beginTransaction();
            ft.detach(tabInfo.fragment);
            ft.commit();
            activity.getSupportFragmentManager().executePendingTransactions();
        }

        tabHost.addTab(tabSpec);

    }  // end addTab()

    
    // fragment handling for changing tabs to the appropriate display
    // called by the tab host whenever a click is registered on the tab widget
    public void onTabChanged(String inTabTagname)
    {
        // pull the TabInfo of the fragment/tab we need from our HashMap
        TabInfo newTab = Xflash.mapTabInfo.get(inTabTagname);
        TabInfo switchTab = null;

        // if we are clicking on a new tab, rather than the one that's already open
        if( currentTab != newTab )
        {
            FragmentTransaction ft = this.getSupportFragmentManager().beginTransaction();
            
    // FIRST WE NEED TO detach any currently attached fragment

            // TODO - we're running detaches we don't necessarily need to here
            // detach the fragment of the tab we are leaving
            if( currentTab != null )
            {
                if( currentTab.fragment != null )
                {
                    ft.detach(currentTab.fragment);
                }
            }

            // detach any attached extra screen
            XflashScreen.detachExtras(ft);


    // THEN WE NEED TO attach the new fragment of the tab we're moving to

            if( newTab != null )
            {
                // if the tab we are switching to does not already have
                // an instantiated fragment, it hasn't been viewed yet
                if( newTab.fragment == null )
                {
                    newTab.fragment = Fragment.instantiate(this,newTab.clss.getName(), newTab.args);
                    ft.add(R.id.realtabcontent, newTab.fragment, newTab.tag);
                } 
                else  
                {
                    //        *** see personal note in XflashScreen.java *** 

                    // we only need to check for multiple screens here, where the tab
                    // is fully instantiated - as that means we've been here before and
                    // MAY have opened secondary screens 
                    if( inTabTagname == "settings" )
                    {
                        // if we are loading a tab currently on an extra screen
                        if( XflashScreen.getCurrentSettingsScreen() > 0 )
                        {
                            // intercede and substitute the fragment TabInfo for where
                            // we really need to navigate to
                            switchTab = XflashScreen.getTransitionFragment("difficulty");
                        }
                    }
                    else if( inTabTagname == "help" )
                    {
                        if( XflashScreen.getCurrentHelpScreen() > 0 )
                        {
                            switchTab = XflashScreen.getTransitionFragment("help_page");
                        }
                    }
                    
                    // if there is no extra screen to attach
                    if( switchTab == null )
                    {
                        ft.attach(newTab.fragment);
                    }
                    else
                    {
                        ft.attach(switchTab.fragment);
                        XflashScreen.setScreenValues(switchTab.tag);
                    }
                    
                }  // end else -- from:   if( newTab.fragment == null )

            }  // end if( newTab != null )
            else
            {
                Log.d(MYTAG,"onTabChanged() passed an invalid tab tag:  " + inTabTagname);
            }

            // set the current tab to the one we are switchng to right now
            currentTab = newTab;
            
            ft.commit();
            this.getSupportFragmentManager().executePendingTransactions();
        
        }  // end if( we clicked a tab we're NOT already on)

    }  // end onTabChanged()

    
    // fragment handling for loading extra screens inside a tab
    public void onScreenTransition(String inTag)
    {
        FragmentTransaction ft = this.getSupportFragmentManager().beginTransaction();
                
        // set the appropriate animation transition
        int[] tempAnimSet = XflashScreen.getAnim(inTag);
        ft.setCustomAnimations(tempAnimSet[0],tempAnimSet[1]);

    // FIRST WE NEED TO detach any currently attached fragment
    
        // detach the tab's root fragment
        if( currentTab != null )
        {
            if( currentTab.fragment != null )
            {
                ft.detach(currentTab.fragment);
            }
        }

        // detach extra screens, if we're transitioning back to a tab root
        XflashScreen.detachSelectExtras(ft,inTag);

    
    // THEN WE NEED TO attach the new fragment of the tab we're moving to

        // pull the fragment TabInfo if we are switching to an extra screen
        TabInfo newTab = XflashScreen.getTransitionFragment(inTag);

        // if we are not transitioning to an extra fragment, load root from tab HashMap 
        if( newTab == null )
        {
            newTab = Xflash.mapTabInfo.get(inTag);
        }

        // if the extra screen we are switching to does not already have
        // an instantiated fragment, it hasn't been viewed yet
        if( newTab.fragment == null )
        {
            newTab.fragment = Fragment.instantiate(this,newTab.clss.getName(),newTab.args);  
            ft.add(R.id.realtabcontent, newTab.fragment, newTab.tag);
        }
        else
        {
            ft.attach(newTab.fragment);
        }

        ft.commit();
        this.getSupportFragmentManager().executePendingTransactions();
        
        // set all necessary screen manager flags following transition
        XflashScreen.setScreenValues(inTag); 
        
    }  // end onScreenTransition()


}  // end Xflash class declaration
      


 
