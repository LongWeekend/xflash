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
//  public void PracticeFragment_toggleReading(View  )
//
//  public void TagFragment_addToplevelTag(View  )
//  public void TagFragment_openGroup(View  )
//  public void TagFragment_goTagCards(View  )
//  public void TagFragment_startStudying(View  )
//
//  public void TagCardsFragment_startStudying(View  )
//  public void TagCardsFragment_addCard(View  )
//
//  public void SearchFragment_addCard(View  )
//
//  public void AddCardToTagFragment_toggleWord(View  )
//  public void AddCardToTagFragment_addTag(View  )
//
//  public void SettingsFragment_switchStudyMode(View  )
//  public void SettingsFragment_switchStudyLanguage(View  )
//  public void SettingsFragment_switchReadingMode(View  )
//  public void SettingsFragment_goDifficulty(View  )
//  public void SettingsFragment_advanceColorScheme(View  )
//  public void SettingsFragment_goUser(View  )
//  public void SettingsFragment_goUpdate(View  )
//  public void SettingsFragment_launchSettingsWeb(View  )
//
//  public void UpdateFragment_check(View v)
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
//  public void onScreenTransition(String  ,int  )

import java.util.HashMap;

import android.content.Context;
import android.content.res.Resources;
import android.os.Bundle;
import android.os.SystemClock;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentTransaction;
import android.util.Log;
import android.view.View;
import android.widget.TabHost;
import android.widget.TabHost.TabContentFactory;
import android.widget.Toast;

public class Xflash extends FragmentActivity implements TabHost.OnTabChangeListener
{
    private static final String MYTAG = "XFlash XFlash";

    private static Xflash myContext;
 
    // properties for our fragment tab management
    private static TabHost myTabHost;
    private static HashMap<String, TabInfo> mapTabInfo = new HashMap<String, TabInfo>();
    private TabInfo currentTab = null;
    private static String currentTabName = null;

    private static boolean exitOnce;   
    private static long exitCount;

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
        exitOnce = false;
        exitCount = 0;
       
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
            if( ( newTabTag == "practice" ) && ( XflashScreen.getCurrentPracticeScreen() < 0 ) )
            {
                onScreenTransition(newTabTag,XflashScreen.DIRECTION_OPEN); 
            }
            else
            {
                onScreenTransition(newTabTag,XflashScreen.DIRECTION_CLOSE); 
            }

        }
        else 
        {
            // if we're at the root view
            
            // THIS MAY NOT BE NECESSARY?

            // fire a toast warning the user that another back press will exit
            // because each tab has its own backstack, I'm concerned users may
            // not realize when they are back to the root view, and thus
            // exit the app unintentionally in the middle of use
            if( !exitOnce  || ( ( SystemClock.uptimeMillis() - exitCount ) > 3000 ) )
            {
                // if this is their first back press at the root view, or more
                // than 3 seconds elapsed 
                exitOnce = true;
                exitCount = SystemClock.uptimeMillis();
                
                // warn they are about to exit
                Toast.makeText(this,"press back again to exit", Toast.LENGTH_SHORT).show();
            }
            else
            {
                // exit the app
                super.onBackPressed();
            }
        }
    }


// passthroughs for methods called by onClick declarations in Fragments

    public void PracticeFragment_reveal(View v)
    {
        PracticeFragment.reveal();
    }
    public void PracticeFragment_practiceClick(View v)
    {
        PracticeFragment.practiceClick(v,this);
    }
    public void PracticeFragment_browseClick(View v)
    {
        PracticeFragment.browseClick(v,this);
    }
    public void PracticeFragment_goRight(View v)
    {
        PracticeFragment.goRight(this);
    }
    public void PracticeFragment_toggleReading(View v)
    {
        PracticeFragment.toggleReading();
    }

    public void ExampleSentenceFragment_read(View v)
    {
        ExampleSentenceFragment.read(v);
    }

    public void ExampleSentenceFragment_exampleClick(View v)
    {
        ExampleSentenceFragment.exampleClick(v,this);
    }

    public void TagFragment_addToplevelTag(View v)
    {
        TagFragment.addToplevelTag(this);
    }
    public void TagFragment_openGroup(View v)
    {
        TagFragment.openGroup(v,this);
    }
    public void TagFragment_goTagCards(View v)
    {
        TagFragment.goTagCards(v,this);
    }
    public void TagFragment_startStudying(View v)
    {
        TagFragment.startStudying(v,this);
    }

    public void TagCardsFragment_startStudying(View v)
    {
        TagCardsFragment.startStudying(v,this);
    }
    public void TagCardsFragment_addCard(View v)
    {
        TagCardsFragment.addCard(v,this);
    }

    public void SearchFragment_addCard(View v)
    {
        SearchFragment.addCard(v,this);
    }
    public void SearchFragment_toggleStar(View v)
    {
        SearchFragment.toggleStar(v);
    }

    public void AddCardToTagFragment_toggleWord(View v)
    {
        AddCardToTagFragment.toggleWord(v);
    }
    public void AddCardToTagFragment_addTag(View v)
    {
        AddCardToTagFragment.addTag(this);
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
    public void SettingsFragment_goUser(View v)
    {
        SettingsFragment.goUser(this);
    }
    public void SettingsFragment_goUpdate(View v)
    {
        SettingsFragment.goUpdate(this);
    }
    public void SettingsFragment_launchSettingsWeb(View v)
    {
        SettingsFragment.launchSettingsWeb(v,this);
    }

    public void UserFragment_activateUser(View v)
    {
        UserFragment.activateUser(v,this);
    }
    public void UserFragment_editUser(View v)
    {
        UserFragment.editUser(v,this);
    }

    public void EditUserFragment_select(View v)
    {
        EditUserFragment.select(this);
    }
    public void EditUserFragment_save(View v)
    {
        EditUserFragment.save(this);
    }

    
    public void UpdateFragment_check(View v)
    {
        UpdateFragment.check();
    }
    
    public void SettingsWebFragment_reload(View v)
    {
        SettingsWebFragment.reload();
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
    
   
    public static TabHost getTabHost()
    {
        return myTabHost;
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

                    // if there IS a secondary screen, it is loaded into switchTab and
                    // used.  If not, switchTab remains null and we default back 
                    // to newTab
                    if( inTabTagname == "tag" )
                    {
                        // if we are in the card view of the tag tab
                        if( XflashScreen.getTagCardsOn() )
                        {
                            switchTab = XflashScreen.getTransitionFragment("tag_cards");
                        }
                        else if( XflashScreen.getAddCardToTagOn() )
                        {
                            switchTab = XflashScreen.getTransitionFragment("add_card");
                        }
                    }
                    else if( inTabTagname == "search" )
                    {
                        if( XflashScreen.getCurrentSearchScreen() > 0 )
                        {
                            switchTab = XflashScreen.getTransitionFragment("search_add_card");
                        }
                    }
                    else if( inTabTagname == "settings" )
                    {
                        // if we are loading a tab currently on an extra screen
                        if( XflashScreen.getCurrentSettingsScreen() > 0 )
                        {
                            // intercede and substitute the fragment TabInfo for where
                            // we really need to navigate to
                            int tempSettingsType = XflashScreen.getCurrentSettingsType();

                            if( tempSettingsType == XflashScreen.LWE_SETTINGS_DIFFICULTY )
                            {
                                switchTab = XflashScreen.getTransitionFragment("difficulty");
                            }
                            else if( tempSettingsType == XflashScreen.LWE_SETTINGS_USER )
                            {
                                switchTab = XflashScreen.getTransitionFragment("user");
                            }
                            else if( tempSettingsType == XflashScreen.LWE_SETTINGS_EDIT_USER )
                            {
                                switchTab = XflashScreen.getTransitionFragment("edit_user");
                            }
                            else if( tempSettingsType == XflashScreen.LWE_SETTINGS_UPDATE )
                            {
                                switchTab = XflashScreen.getTransitionFragment("update");
                            }
                            else if( tempSettingsType == XflashScreen.LWE_SETTINGS_WEB )
                            {
                                switchTab = XflashScreen.getTransitionFragment("settings_web");
                            }
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
                        XflashScreen.setScreenValues(switchTab.tag,XflashScreen.DIRECTION_NULL);
                    }
                    
                }  // end else -- from:   if( newTab.fragment == null )

            }  // end if( newTab != null )
            else
            {
                Log.d(MYTAG,"onTabChanged() passed an invalid tab tag:  " + inTabTagname);
            }

            // set the current tab to the one we are switchng to right now
            currentTab = newTab;
            currentTabName = currentTab.tag;

            ft.commit();
            this.getSupportFragmentManager().executePendingTransactions();
        
        }  // end if( we clicked a tab we're NOT already on)

    }  // end onTabChanged()

    
    // return the name of the current tab
    public static String getCurrentTabName()
    {
        return currentTabName;
    }

    
    // fragment handling for loading extra screens inside a tab
    public void onScreenTransition(String inTag,int direction)
    {
        FragmentTransaction ft = this.getSupportFragmentManager().beginTransaction();
        
        if( direction == XflashScreen.DIRECTION_OPEN )
        {
            ft.setCustomAnimations(R.anim.slidein_right,R.anim.slideout_left);
        }
        else if( direction == XflashScreen.DIRECTION_CLOSE )
        {
            ft.setCustomAnimations(R.anim.slidein_left,R.anim.slideout_right);
        }

        // detach extra screens, if we're transitioning back to a tab root
        XflashScreen.detachExtras(ft);
        
        // pull the fragment TabInfo if we are switching to an extra screen
        TabInfo newTab = XflashScreen.getTransitionFragment(inTag);
                
        // if we are not transitioning to an extra fragment, load root from tab HashMap 
        if( newTab == null )
        {
            newTab = Xflash.mapTabInfo.get(inTag);
        }

    // FIRST WE NEED TO detach any currently attached fragment
    
        // detach the tab's root fragment
        if( currentTab != null )
        {
            if( currentTab.fragment != null ) 
            {
                ft.detach(currentTab.fragment);
            }
        }


    
    // THEN WE NEED TO attach the new fragment of the tab we're moving to


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
        XflashScreen.setScreenValues(inTag,direction); 
        
    }  // end onScreenTransition()


}  // end Xflash class declaration
      


 
