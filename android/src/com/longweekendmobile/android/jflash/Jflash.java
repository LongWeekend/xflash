package com.longweekendmobile.android.jflash;

//  Jflash.java
//  jFlash
//
//  Created by Todd Presson on 1/7/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  protected void onCreate(Bundle  )               @over
//  protected void onSaveInstanceState(Bundle  )    @over
//
//  *** METHODS CALLED BY FRAGMENTS ***
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
//  private class TabInfo
//  class TabFactory implements TabContentFactory
//
//  private void initializeTabHost(Bundle  )
//  private static void addTab(Jflash  ,TabHost  ,TabHost.TabSpec  ,TabInfo  )
//  public void onTabChanged(String  )

import java.util.HashMap;

import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentTransaction;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TabHost;
import android.widget.TabHost.TabContentFactory;
import android.widget.TextView;
import android.util.Log;

public class Jflash extends FragmentActivity implements TabHost.OnTabChangeListener
{
    private static final String MYTAG = "JFlash main";
   
    // TODO - we don't really want to leave these instantiated for the lifecycle of
    //        the app, as they're only necessary for changing internal tab views
    private static Jflash myContext;
 
    // properties for our fragment tab management
    private TabHost mTabHost;
    private static HashMap<String, TabInfo> mapTabInfo = new HashMap<String, Jflash.TabInfo>();
    private TabInfo mLastTab = null;

    /** Called when the activity is first created. */
    // (non-Javadoc) see android.support.v4.app.FragmentActivity#onCreate(android.os.Bundle)
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


    // (non-Javadoc) see android.support.v4.app.FragmentActivity#onSaveInstanceState(android.os.Bundle)
    @Override
    protected void onSaveInstanceState(Bundle outState)
    {
        // save the tab selected
        outState.putString("tab", mTabHost.getCurrentTabTag());
        super.onSaveInstanceState(outState);
    }


// START TagFragment sub-activity methods
    
    // onClick for our PLUS button
    public void TagFragment_addTag(View v)
    {
        // start the 'add tag' activity as a modal
        startActivity(new Intent(this,CreateTagActivity.class));
    }

// END TagFragment sub-activity methods


// START SettingsFragment sub-activity methods

    // called when user makes a change to the color scheme in Settings
    public void SettingsFragment_advanceColorScheme(View v)
    {
        SettingsFragment.advanceColorScheme();
    }

// END SettingsFragment sub-activity methods

// START HelpFragment sub-activity methods

    // onClick method for the "ask us" button - pops a dialog
    public void HelpFragment_goAskUs(View v)
    {
        HelpFragment.goAskUs(this);
    }

    
    // TODO - move to HelpFragment (onScreenTransition?)
    // calls a new view activity for fragment tab layout 
    public static void HelpFragment_pullHelpTopic(int inId)
    {
        // set the help topic we are pulling
        HelpPageFragment.setHelpTopic(inId);
        
        ScreenManager.setCurrentHelpScreen(1);

        // load the HelpPageFragment to the fragment tab manager
        myContext.onScreenTransition("help_page");
    }

// END HelpFragment sub-activity methods


// START HelpPageFragment sub-activity methods

    // reset the content view to the main help screen
    public void HelpPageFragment_goBackToHelp(View v)
    {
        // reload the HelpPage fragment to the fragment tab manager
        
        ScreenManager.setCurrentHelpScreen(0);
        
        this.onScreenTransition("help");
    }
    

    // when the 'next' button is pressed
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

    private class TabInfo
    {
         private String tag;
         private Class<?> clss;
         private Bundle args;
         private Fragment fragment;
         
        TabInfo(String tag, Class<?> clazz, Bundle args)
         {
             this.tag = tag;
             this.clss = clazz;
             this.args = args;
         }
    }
    
    class TabFactory implements TabContentFactory
    {
        private final Context mContext;

        public TabFactory(Context context)
        {
            mContext = context;
        }
        
        // (non-Javadoc)  see android.widget.TabHost.TabContentFactory#createTabContent(java.lang.String)
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
        // Jflash.mTabhost - top level class property
        mTabHost = (TabHost)findViewById(android.R.id.tabhost);
        mTabHost.setup();
        
        TabHost.TabSpec spec;
        TabInfo tabInfo = null;
        
        // Resources object to grab our tab drawables
        Resources res = getResources();     
        
        // add the Practice tab
        spec = this.mTabHost.newTabSpec("practice").setIndicator("Practice", res.getDrawable(R.drawable.practice_flip));
        Jflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("practice", PracticeFragment.class, args)));
        Jflash.mapTabInfo.put(tabInfo.tag, tabInfo);
        
        // add the Study Sets tab
        spec = this.mTabHost.newTabSpec("tag").setIndicator("Study Sets", res.getDrawable(R.drawable.tags_flip));
        Jflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("tag", TagFragment.class, args)));
        Jflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        // add the Search tab
        spec = this.mTabHost.newTabSpec("search").setIndicator("Search", res.getDrawable(R.drawable.search_flip));
        Jflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("search", SearchFragment.class, args)));
        Jflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        // add the Search tab
        spec = this.mTabHost.newTabSpec("settings").setIndicator("Settings", res.getDrawable(R.drawable.settings_flip));
        Jflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("settings", SettingsFragment.class, args)));
        Jflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        // add the Search tab
        spec = this.mTabHost.newTabSpec("help").setIndicator("Help", res.getDrawable(R.drawable.help_flip));
        Jflash.addTab(this, this.mTabHost, spec, ( tabInfo = new TabInfo("help", HelpFragment.class, args)));
        Jflash.mapTabInfo.put(tabInfo.tag, tabInfo);

        
        // add fragments to the HashMap that aren't displayed as a tab root
        tabInfo = new TabInfo("help_page", HelpPageFragment.class, args);
        Jflash.mapTabInfo.put(tabInfo.tag, tabInfo);
 

        // default to displaying the first tab
        this.onTabChanged("practice");
        mTabHost.setOnTabChangedListener(this);
    }

    
    // adds new tabs to the fragment tab manager
    private static void addTab(Jflash activity, TabHost tabHost, TabHost.TabSpec tabSpec, TabInfo tabInfo)
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
    // (non-Javadoc) see android.widget.TabHost.OnTabChangeListener#onTabChanged(java.lang.String)
    public void onTabChanged(String inTabTagname)
    {
        // the tab we need to change to - as passed into method by 'inTabTagname'
        TabInfo newTab = Jflash.mapTabInfo.get(inTabTagname);

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
                    
                    // a temporary TabInfo, in case we have a secondary screen to add
                    TabInfo tempTab = null;
 
                    // if HelpFragment is what we're loading
                    if( inTabTagname == "help" )
                    {
                        // if we ARE on the secondary screen
                        if( ScreenManager.getCurrentHelpScreen() == 1 )
                        {
                            // TODO - there may be a better way of doing
                            //        this, but I can't find it

                            // if the help screen is already instantiated,
                            // remove and reattach it so it appears in the
                            // correct order, without animation transitions
                            tempTab = Jflash.mapTabInfo.get("help");
                            if( tempTab.fragment != null )
                            {
                                ft.detach(tempTab.fragment); 
                            }

                            // now instantiate the incoming class, which here will be help_page
                            tempTab.fragment = Fragment.instantiate(this,
                            tempTab.clss.getName() );
                        }
                    }
                    
                    ft.attach(newTab.fragment);
                    
                    // if we have are loading a secondary screen for this tab,
                    // attach it AFTER the base screen so it starts on top
                    if( tempTab != null )
                    {
                        ft.attach(tempTab.fragment);
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
        // (non-Javadoc) see android.widget.TabHost.OnTabChangeListener#onTabChanged(java.lang.String)
        TabInfo newTab = Jflash.mapTabInfo.get(tag);

        FragmentTransaction ft = this.getSupportFragmentManager().beginTransaction();
                    
        // for each possible incoming tag tab (i.e. all Activity fragments that have
        // mutiple screends), check for fragment instantiation and set an animation
        if( tag == "help" )
        {
            if( newTab.fragment == null )
            {
                newTab.fragment = Fragment.instantiate(this, HelpFragment.class.getName() );
            }
    
            // add our custom animation when we're sure we have a fragment
            ft.setCustomAnimations(R.anim.slidein_left,R.anim.slideout_right);
        }
        else if( tag == "help_page" )
        {
            if( newTab.fragment == null )
            {
                newTab.fragment = Fragment.instantiate(this, HelpPageFragment.class.getName() );
            }
            
            // add our custom animation when we're sure we have a fragment
            ft.setCustomAnimations(R.anim.slidein_right,R.anim.slideout_left);
        }
        
        ft.replace(R.id.realtabcontent, newTab.fragment, newTab.tag);

        ft.commit();
        
        this.getSupportFragmentManager().executePendingTransactions();

    }  // end onTabChanged()


}  // end Jflash class declaration
      


 
