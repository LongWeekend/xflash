package com.longweekendmobile.android.xflash;

//  Xflash.java
//  Xflash
//
//  Created by Todd Presson on 1/7/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  protected void onCreate(Bundle  )               @over
//  protected void onSaveInstanceState(Bundle  )    @over
//
//  *** METHODS CALLED BY FRAGMENTS ***
//
//  public void PracticeFragment_reveal(View  )
//
//  public void TagFragment_addTag(View  )
//
//  public void SettingsFragment_advanceColorScheme(View  )
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
//  public void onTabChanged(String  )

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
   
    // TODO - we don't really want to leave these instantiated for the lifecycle of
    //        the app, as they're only necessary for changing internal tab views
    private static Xflash myContext;
 
    // properties for our fragment tab management
    private TabHost mTabHost;
    private static HashMap<String, TabInfo> mapTabInfo = new HashMap<String, TabInfo>();
    private TabInfo mLastTab = null;


    /** Called when the activity is first created. */
    // see android.support.v4.app.FragmentActivity#onCreate(android.os.Bundle)
    @Override
    protected void onCreate(Bundle savedInstanceState) 
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        
        // set up all of our tab systems
        initializeTabHost(savedInstanceState);
        
        // if we're coming back from a stop, queue the last open tab
        if( savedInstanceState != null )
        {
            // set the tab as per the saved state
            mTabHost.setCurrentTabByTag(savedInstanceState.getString("tab")); 
        }

        myContext = this;
       
    }  // end onCreate


    // see android.support.v4.app.FragmentActivity#onSaveInstanceState(android.os.Bundle)
    @Override
    protected void onSaveInstanceState(Bundle outState)
    {
        // save the tab selected
        outState.putString("tab", mTabHost.getCurrentTabTag());
        super.onSaveInstanceState(outState);
    }


    public void PracticeFragment_browseClick(View v)
    {
        PracticeFragment.browseClick();
    }

    public void PracticeFragment_reveal(View v)
    {
        PracticeFragment.reveal();
    }

    public void PracticeFragment_practiceClick(View v)
    {
        PracticeFragment.practiceClick(v);
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

// END HelpPageFragment sub-activity methods


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
        
        // see android.widget.TabHost.TabContentFactory#createTabContent(java.lang.String)
        public View createTabContent(String tag)
        {
            View v = new View(mContext);
            v.setMinimumWidth(0);
            v.setMinimumHeight(0);
            
            return v;
        }
    }
    
    // initialize the Tab Host
    private void initializeTabHost(Bundle args)
    {
        // Xflash.mTabhost - top level class property
        mTabHost = (TabHost)findViewById(android.R.id.tabhost);
        mTabHost.setup();
        
        TabHost.TabSpec spec;
        TabInfo tabInfo = null;
        
        // Resources object to grab our tab drawables
        Resources res = getResources();     
        
        // add the Practice tab
        spec = this.mTabHost.newTabSpec("practice").setIndicator("Practice", res.getDrawable(R.drawable.practice_flip));
        Xflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("practice", PracticeFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);
 
        // add the Study Sets tab
        spec = this.mTabHost.newTabSpec("tag").setIndicator("Study Sets", res.getDrawable(R.drawable.tags_flip));
        Xflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("tag", TagFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        // add the Search tab
        spec = this.mTabHost.newTabSpec("search").setIndicator("Search", res.getDrawable(R.drawable.search_flip));
        Xflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("search", SearchFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        // add the Search tab
        spec = this.mTabHost.newTabSpec("settings").setIndicator("Settings", res.getDrawable(R.drawable.settings_flip));
        Xflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("settings", SettingsFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        // add the Search tab
        spec = this.mTabHost.newTabSpec("help").setIndicator("Help", res.getDrawable(R.drawable.help_flip));
        Xflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("help", HelpFragment.class, args)));
        Xflash.mapTabInfo.put(tabInfo.tag, tabInfo);


        // default to displaying the first tab
        this.onTabChanged("practice");
        mTabHost.setOnTabChangedListener(this);
    }

    
    // adds new tabs to the fragment tab manager
    private static void addTab(Xflash activity, TabHost tabHost, TabHost.TabSpec tabSpec, TabInfo tabInfo)
    {
        // Attach a Tab view factory to the spec
        tabSpec.setContent(activity.new TabFactory(activity));
        String tag = tabSpec.getTag();

        // Check to see if we already have a fragment for this tab, probably
        // from a previously saved state.  If so, deactivate it, because our
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
    }

    
    // TODO - this feels over-commented, but is hard to understand
    //        just by reading the code

    // fragment handling for changing tabs to the appropriate display
    // see android.widget.TabHost.OnTabChangeListener#onTabChanged(java.lang.String)
    public void onTabChanged(String inTabTagname)
    {
        // the tab we need to change to - as passed into method by 'inTabTagname'
        TabInfo newTab = Xflash.mapTabInfo.get(inTabTagname);
        TabInfo switchTab = null;

        // if we AREN'T clicking on the tab we're already on
        if( mLastTab != newTab )
        {
            FragmentTransaction ft = this.getSupportFragmentManager().beginTransaction();
            
            // if we are coming from an instantiated tab, remove the old
            // fragment to free memory taken by its view hierarchy.
            // this will ALWAYS happen, except when the first tab is 
            // loaded when the app launches
            if( mLastTab != null )
            {
                if( mLastTab.fragment != null )
                {
                    ft.detach(mLastTab.fragment);
                }
            }

            XflashScreen.detachExtras(ft);

            // if we were passed in a 'tag' for a valid (previously added) fragment
            if( newTab != null )
            {
                // if the fragment we are switching to does not already have
                // and instantiation
                // i.e. it has not yet been switched to in the current
                // run of the application - we need to fire it up
                if( newTab.fragment == null )
                {
                    newTab.fragment = Fragment.instantiate(this,
                           newTab.clss.getName(), newTab.args);
                    
                    ft.add(R.id.realtabcontent, newTab.fragment, newTab.tag);
                } 
                else
                {
                    // we only need to check for multiple screens here, where the tab
                    // is fully instantiated - as that means we've been here before and
                    // MAY have opened secondary screens 

                    // depending no which fragment we're loading...
                    if( inTabTagname == "settings" )
                    {
                        if( XflashScreen.getCurrentSettingsScreen() > 0 )
                        {
                            switchTab = XflashScreen.getTransitionFragment("difficulty");
                        }
                    }
                    else if( inTabTagname == "help" )
                    {
                        // if we ARE on the secondary screen
                        if( XflashScreen.getCurrentHelpScreen() > 0 )
                        {
                            // if we're switching into a tab on a sub-page, intercede
                            // and substitute the fragment info for where we WANT
                            // to navigate to
                            switchTab = XflashScreen.getTransitionFragment("help_page");
                        }
                    }
                    
                    if( switchTab == null )
                    {
                        ft.attach(newTab.fragment);
                    }
                    else
                    {
                        ft.attach(switchTab.fragment);
                        XflashScreen.setScreenValues(switchTab.tag);
                    }
                    
                }  // end else -- for if( newTab.fragment == null )

            }  // end if( newTab != null )
            else
            {
                Log.d(MYTAG,"onTabChanged() passed an invalid tab tag:  " + inTabTagname);
            }

            mLastTab = newTab;
            
            // commit changes and act immediately
            ft.commit();
            this.getSupportFragmentManager().executePendingTransactions();
        
        }  // end if( we clicked a tab we're NOT already on)

    }  // end onTabChanged()

    
    // fragment handling for loading new screens to a single tab
    public void onScreenTransition(String tag)
    {
        FragmentTransaction ft = this.getSupportFragmentManager().beginTransaction();
                
        // load check for extra fragments
        TabInfo newTab = XflashScreen.getTransitionFragment(tag);

        // if we are not transitioning to an extra fragment, load from tabs
        if( newTab == null )
        {
            newTab = Xflash.mapTabInfo.get(tag);
        }

        // set the appropriate animation transition
        int[] tempAnimSet = XflashScreen.getAnim(tag);
        ft.setCustomAnimations(tempAnimSet[0],tempAnimSet[1]);

        // if we still have an attached tab
        if( mLastTab != null )
        {
            if( mLastTab.fragment != null )
            {
                ft.detach(mLastTab.fragment);
            }
        }

        XflashScreen.detachSelectExtras(ft,tag);
        // set values for our extraFragments array and extraScreens tracker 
        // based in which "tag" we're switching to
        XflashScreen.setScreenValues(tag); 

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
        
    }  // end onScreenTransition()


}  // end Xflash class declaration
      


 
