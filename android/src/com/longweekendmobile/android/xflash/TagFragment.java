package com.longweekendmobile.android.xflash;

//  TagFragment.java
//  Xflash
//
//  Created by Todd Presson on 1/26/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//  public void onResume()                                              @over
//
//  public static void addToplevelTag(Context  )
//  public static void openGroup(View  ,Xflash  )
//  public static void goTagCards(View  ,Xflash  )
//  public static void startStudying(View  ,Xflash  )
//  public static void fireStartStudyingDialog(Tag  ,Xflash  )
//  public static void fireEmptyTagDialog(Xflash  )
//
//  private static OnLongClickListener userTagLongClick = new OnLongClickListener() 
//
//  private static void refreshTagList()
//  private void setupObservers()
//  private void updateFromNewTagObserver(Object  )
//  private void udpateFromSubscriptionObserver()
//  public static boolean getSearchOn()
//  public static void searchPressed()
//
//  public static class TagSearch
//
//      public static void loadSearch()
//      public static void showSearch()
//      public static void hideSearch()
//      public static void closeKeyboard()
//      private static void showSearchScroll()
//      private static void hideSearchScroll()
//      private static TextWatcher searchListener 
//      private static void textChanged(Editable text)
//      private static void refreshTagSearchList()

import java.util.ArrayList;
import java.util.Observable;
import java.util.Observer;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnLongClickListener;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.longweekendmobile.android.xflash.model.Group;
import com.longweekendmobile.android.xflash.model.GroupPeer;
import com.longweekendmobile.android.xflash.model.Tag;
import com.longweekendmobile.android.xflash.model.TagPeer;

public class TagFragment extends Fragment
{
    // private static final String MYTAG = "XFlash TagFragment";
   
    private static FragmentActivity myContext = null;
    private static LayoutInflater myInflater;

    private static Observer newTagObserver = null; 
    private static Observer subscriptionObserver = null; 

    public static Group currentGroup = null;
    public static boolean needLoad = false;
    private static RelativeLayout tagLayout = null;
    private static LinearLayout tagList = null;

    // for display of any groups
    private static ArrayList<Group> groupArray = null;
    
    // for shuffling the tag list
    private static ArrayList<Tag> rawTagArray = null;
    private static ArrayList<Tag> userTagArray = null;
    
    // for final display of tag list
    private static ArrayList<Tag> shuffleArray = null;
 
    // (non-Javadoc) - see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, 
                             Bundle savedInstanceState) 
    {
        myContext = getActivity();
        myInflater = inflater;
        setupObservers();

        // inflate our layout for the Tag fragment and load our icon array
        tagLayout = (RelativeLayout)inflater.inflate(R.layout.tag, container, false);
        int icons[] = XflashSettings.getIcons();
        TagSearch.loadSearch();

        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)tagLayout.findViewById(R.id.tag_heading);
        ImageButton tempButton = (ImageButton)tagLayout.findViewById(R.id.tag_addbutton);
        
        XflashSettings.setupColorScheme(titleBar,tempButton);
    
        // populate the main list of groups
        LinearLayout groupList = (LinearLayout)tagLayout.findViewById(R.id.main_group_list);
        RelativeLayout tempRow = null;
        ImageView tempRowImage = null;
        TextView tempView = null;
        
        // if the TagFragment is not set to a specific group, load top level
        if( currentGroup == null )
        {
            currentGroup = GroupPeer.topLevelGroup();
            needLoad = true;
        }

        // set the title bar to the current group/tag
        tempView = (TextView)tagLayout.findViewById(R.id.tag_heading_text);
        tempView.setText( currentGroup.getGroupName() );

        // pull and display any groups owned by currentGroup
        if( needLoad )
        {
            groupArray = GroupPeer.retrieveGroupsByOwner( currentGroup.getGroupId() );
        }

        int rowCount = groupArray.size();
        for(int i = 0; i < rowCount; i++)
        {
            Group tempGroup = groupArray.get(i);
            
            tempRow = (RelativeLayout)inflater.inflate(R.layout.group_row,null);
            tempRow.setTag( tempGroup.getGroupId() );
      
            // set the group image
            tempRowImage = (ImageView)tempRow.findViewById(R.id.group_row_image);
            if( tempGroup.getRecommended() == 1 )
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_SPECIAL_FOLDER ] ); 
            }
            else
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_FOLDER ] ); 
            }


            // set the group title
            tempView = (TextView)tempRow.findViewById(R.id.group_row_top);
            tempView.setText( tempGroup.getGroupName() );

            // set the group set count
            StringBuilder tempBuilder = new StringBuilder();

            int tempInt = tempGroup.getChildGroupCount();
            if( tempInt > 0 )
            {
                tempBuilder.append(tempInt).append(" groups,  "); 
            }
            tempBuilder.append( tempGroup.getTagCount() ).append(" sets");
   
            tempView = (TextView)tempRow.findViewById(R.id.group_row_bottom);
            tempView.setText( tempBuilder.toString() );

            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)inflater.inflate(R.layout.divider,null);
                groupList.addView(divider);
            }
            groupList.addView(tempRow);

        }  // end for loop (groups)


        // pull and display any tags for currentGroup
        tagList = (LinearLayout)tagLayout.findViewById(R.id.main_tag_list);
        refreshTagList();

        // only display backup block on root view
        LinearLayout backupBlock = (LinearLayout)tagLayout.findViewById(R.id.tag_backup_block);
        if( ( currentGroup != null ) && currentGroup.isTopLevelGroup() )
        {
            backupBlock.setVisibility(View.VISIBLE);
        }
        else
        {
            backupBlock.setVisibility(View.GONE);
        }

        // check to see if we tabbed back in to 'Study Sets' with a search open
        if( TagSearch.searchOn )
        {
            TagSearch.showSearch();     
        }
        
        return tagLayout;

    }  // end onCreateView()


    @Override
    public void onPause()
    {
        super.onPause();
        
        // if the search option is open, make sure the keyboard is closed
        // on any transition
        if( TagSearch.searchOn )
        {
            TagSearch.closeKeyboard();
        }
    }


    // onClick for our PLUS button
    public static void addToplevelTag(Context inContext)
    {
        // start the 'add tag' activity as a modal
        Intent myIntent = new Intent(inContext,CreateTagActivity.class);
        myIntent.putExtra("group_id", currentGroup.getGroupId() );
        
        inContext.startActivity(myIntent);
    }


    // reload TagFragment with a new group
    public static void openGroup(View v,Xflash inContext)
    {
        XflashScreen.addTagStack();
        currentGroup = GroupPeer.retrieveGroupById( (int)(Integer)v.getTag() );
        
        inContext.onScreenTransition("tag",XflashScreen.DIRECTION_OPEN);
    }

    
    // transition to view all cards in a given Tag
    public static void goTagCards(View v,Xflash inContext)
    {
        int tempInt = (Integer)v.getTag();
        TagCardsFragment.loadTag(tempInt); 
        
        inContext.onScreenTransition("tag_cards",XflashScreen.DIRECTION_OPEN);
    }
    
    
    // launch the clicked on Tag in the practice tab
    public static void startStudying(View v,Xflash inContext)
    {
        int incomingTagId = (Integer)v.getTag();
        Tag tempTag = TagPeer.retrieveTagById(incomingTagId);

        // if user is trying to open an empty tag
        if( tempTag.getCardCount() < 1 )
        {
            fireEmptyTagDialog(inContext);
        }
        else
        {
            fireStartStudyingDialog(tempTag,inContext);
        }

    }  // end startStudying()

    
    // launch the dialog to confirm user would like to start studying a tag
    public static void fireStartStudyingDialog(Tag inTag,Xflash incoming)
    {
        final Tag tagToLaunch = inTag;
        final Xflash inContext = incoming;
        
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder(inContext);

        builder.setTitle( tagToLaunch.getName() );

        String tempString = inContext.getResources().getString(R.string.startstudying_dialog_message);
        builder.setMessage(tempString);

        // on postive response, set the new active user
        builder.setPositiveButton("OK", new DialogInterface.OnClickListener()
        {
            public void onClick(DialogInterface dialog,int which)
            {
                // set the new user and return to settings
                PracticeFragment.loadTag( tagToLaunch.getId() );
                Xflash.getTabHost().setCurrentTabByTag("practice");
            }
        });

        // on negative response, do nothing
        builder.setNegativeButton("Cancel",null);
        
        builder.create().show();

    }  // end fireEmptyTagDialong()


    // dialog to display on attempt to start studying a tag with no cards
    public static void fireEmptyTagDialog(Xflash inContext)
    {
        // set and fire our AlertDialog
        AlertDialog.Builder builder = new AlertDialog.Builder(inContext);

        String tempString = inContext.getResources().getString(R.string.emptyset_dialog_title);
        builder.setTitle(tempString);

        tempString = inContext.getResources().getString(R.string.emptyset_dialog_message);
        builder.setMessage(tempString);

        // on negative response, do nothing
        builder.setNegativeButton("OK",null);
        
        builder.create().show();

    }  // end fireEmptyTagDialong()


    // a long-click listener for deletion of user tags
    private static OnLongClickListener userTagLongClick = new OnLongClickListener() 
    {
        @Override
        public boolean onLongClick(View v) 
        {
            final View viewToRemove = v;
            final int tempInt = (Integer)viewToRemove.getTag();
            final Tag tempTag = TagPeer.retrieveTagById(tempInt);
            
            // set and fire our AlertDialog
            AlertDialog.Builder builder = new AlertDialog.Builder(myContext);
            builder.setTitle("Delete Tag?");
            builder.setMessage("Are you sure you want to delete the study set \"" + tempTag.getName() + "\"?");

            // on postive response, set the new active user
            builder.setPositiveButton("OK", new DialogInterface.OnClickListener()
            {
                public void onClick(DialogInterface dialog,int which)
                {
                    TagPeer.deleteTag(tempTag);

                    if( TagSearch.searchOn )
                    {
                        // if the delete call came from a tag in the TagSearch
                        TagSearch.tagSearchList.removeView(viewToRemove);
                        tagList.removeView( tagList.findViewWithTag( viewToRemove.getTag() ) );
                    }
                    else
                    {
                        // if it was just a regular delete
                        tagList.removeView(viewToRemove);            
                    }

                }  // end onClick()
            });

            // on negative response, do nothing
            builder.setNegativeButton("Cancel",null);

            builder.create().show();

            return true;
        }

    };  // end OnLongClickListener declaration 


    public static void setNeedLoad()
    {
        needLoad = true;
    }

    
    // pull and display any tags for currentGroup
    private static void refreshTagList()
    {
        // LayoutInflater inflater = (LayoutInflater)myContext.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        int rowCount;
     
        // if we need to refresh our arrays due to a change
        if( needLoad )
        {
            // TODO - I feel like there MUST be a better way to do this
            rawTagArray = currentGroup.childTags();
            userTagArray = new ArrayList<Tag>();
        
            // the ArrayList we will actually use to populate the view
            shuffleArray = new ArrayList<Tag>();

        
            // shuffle 'my starred words' to the top, user tags to the bottom
            rowCount = rawTagArray.size();
            for(int i = 0; i < rowCount; i++)
            {
                Tag shuffleTag = rawTagArray.get(i);

                // add the starred words tag at the start
                if( shuffleTag.getId() == Tag.STARRED_TAG_ID )
                {
                    shuffleArray.add(0,shuffleTag);
                }
                else
                {
                    // if it is a system tag, add it straight to
                    // the shuffle array, otherwise hold on to it
                    if( shuffleTag.isEditable() )
                    {
                        userTagArray.add(shuffleTag);
                    }
                    else
                    {
                        shuffleArray.add(shuffleTag);
                    }
                }
            }

            // add user tags back in at the bottom
            rowCount = userTagArray.size();
            if( rowCount > 0 )
            {
                for(int i = 0; i < rowCount; i++)
                {
                    shuffleArray.add( userTagArray.get(i) );
                } 
            }

            // clear views on reload
            tagList.removeAllViews();

            // we're done with conditional loading
            needLoad = false;

        }  // end if( needLoad ) 
      
        // now load the tag views
        refreshByTagList(shuffleArray,tagList);

    }  // end refreshTagList()


    // called by TagFragment.refreshTagList() and TagSearch.refreshTagSearchList()
    private static void refreshByTagList(ArrayList<Tag> inList,LinearLayout inLayout)
    {
        int icons[] = XflashSettings.getIcons();
        
        // now add the final ordered ArrayList of tags to views, add to the layout
        int rowCount = inList.size();
        for(int i = 0; i < rowCount; i++)
        {
            Tag tempTag = inList.get(i);
            
            RelativeLayout tempRow = (RelativeLayout)myInflater.inflate(R.layout.tag_row,null);
            tempRow.setTag( tempTag.getId() );
     
            // if this is a user tag, set a long-click listener for deletion
            if( tempTag.isEditable() )
            {
                tempRow.setOnLongClickListener(userTagLongClick);
            }
 
            // set the group image
            ImageView tempRowImage = (ImageView)tempRow.findViewById(R.id.tag_row_image);

            if( tempTag.getId() == Tag.STARRED_TAG_ID )
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_STARRED_TAG] );
            }
            else
            {
                tempRowImage.setImageResource( icons[XflashSettings.LWE_ICON_TAG] );
            }

            // set the tag title
            TextView tempView = (TextView)tempRow.findViewById(R.id.tag_row_top);
            tempView.setText( tempTag.getName() );

            // set the group set count
            tempView = (TextView)tempRow.findViewById(R.id.tag_row_bottom);
            int tempInt = tempTag.getCardCount();
            String tempCountString = Integer.toString(tempInt);
            if( tempInt == 1 )
            {
                tempCountString = tempCountString + " word";
            }
            else
            {
                tempCountString = tempCountString + " words";
            }
            tempView.setText(tempCountString);

            // clear the 'view' option if there are no cards in the tag
            tempView = (TextView)tempRow.findViewById(R.id.tag_row_click);
            if( tempTag.getCardCount() < 1 )
            {
                tempView.setVisibility(View.INVISIBLE);
            }
            else
            {
                tempView.setTag( tempTag.getId() ); 
            }

            // add a divider before all except the first
            if( i > 0 )
            {
                FrameLayout divider = (FrameLayout)myInflater.inflate(R.layout.divider,null);
                inLayout.addView(divider);
            }
            inLayout.addView(tempRow);

        }  // end for loop 

    }  // end refreshByTagList()


    // method to set all relevant Observers
    private void setupObservers()
    {
        if( newTagObserver == null )
        {
            // create and define behavior for newTagObserver
            newTagObserver = new Observer()
            {
                public void update(Observable obj,Object arg)
                {
                    updateFromNewTagObserver(arg);
                }
            };

        }  // end if( newTagObserver == null )
        
        if( subscriptionObserver == null )
        {
            // create and define behavior for newTagObserver
            subscriptionObserver = new Observer()
            {
                public void update(Observable obj,Object arg)
                {
                    updateFromSubscriptionObserver();
                }
            };

        }  // end if( subscriptionObserver == null )

       XflashNotification theNotifier = XFApplication.getNotifier();
       theNotifier.addNewTagObserver(newTagObserver);
       theNotifier.addSubscriptionObserver(subscriptionObserver);

    }  // end setupObservers()


    private void updateFromNewTagObserver(Object passedObject)
    {
        // get the Tag that was just added
        Tag theNewTag = (Tag)passedObject;

        // only refresh if it was added to the visible group
        if( theNewTag.groupId() == currentGroup.getGroupId() )
        {
            TagFragment.needLoad = true;
            TagFragment.refreshTagList();
        }

    }  // end updateFromNewTagObserver()


    private void updateFromSubscriptionObserver()
    {
        // only refresh if we're on the top level group
        // i.e. we need to update the count on 'My Starred Words'
        if( currentGroup.getGroupId() == 0 )
        {
            TagFragment.needLoad = true;
            TagFragment.refreshTagList();
        }

    }  // end updateFromSubscriptionObserver()


    public static boolean getSearchOn()
    {
        return TagSearch.searchOn;
    }

    
    // called by Xflash when onSearchRequested() is called
    public static void searchPressed()
    {
        if( TagSearch.searchOn )
        {
            TagSearch.hideSearch();
        }
        else
        {
            TagSearch.showSearch();
        }
   
    }  // end searchPressed()


    // class for handling tag searches
    public static class TagSearch
    {
        public static boolean searchOn = false;

        private static TextView tempTitle = null;
        private static ImageButton tempAddButton = null;
        private static RelativeLayout shade = null;
        private static EditText searchText = null;
        private static LinearLayout tagSearchList = null;
        private static ScrollView tagScroll = null; 
        private static ScrollView searchScroll = null;

        private static ArrayList<Tag> searchResultsList = null;
        
        // gets the view resources we need
        public static void loadSearch()
        {
            searchText = (EditText)tagLayout.findViewById(R.id.tag_search_text);
            tagSearchList = (LinearLayout)tagLayout.findViewById(R.id.tag_search_list);
            tempTitle = (TextView)tagLayout.findViewById(R.id.tag_heading_text);
            tempAddButton = (ImageButton)tagLayout.findViewById(R.id.tag_addbutton);
            shade = (RelativeLayout)tagLayout.findViewById(R.id.tag_shade);
            tagScroll = (ScrollView)tagLayout.findViewById(R.id.tag_scroll);
            searchScroll = (ScrollView)tagLayout.findViewById(R.id.tag_search_scroll);
            
        }
       
       
        // sets all appropriate views when transitioning INTO a search state
        public static void showSearch()
        {
            // hide the title
            tempTitle.setVisibility(View.GONE);
            tempAddButton.setVisibility(View.GONE);

            // show the search bar and shade
            searchText.setVisibility(View.VISIBLE);
            shade.setVisibility(View.VISIBLE);

            // display any results hanging out in the search array IF
            // there is still text in our EditText
            if( ( searchResultsList != null) && ( searchResultsList.size() > 0 ) &&
                ( searchText.getText().length() > 0 ) )
            {
                TagSearch.showSearchScroll();
            }
            
            searchText.addTextChangedListener(TagSearch.searchListener);
            
            // launch the keyboard if the EditText is empty
            searchText.postDelayed( new Runnable()
            {
                @Override
                public void run()
                {
                    // TODO - move this conditional outside of the post when
                    //      - we can base it on something not tied to 
                    //      - view instantiation
                    if( searchText.length() == 0 )
                    {
                        searchText.requestFocus();
                        InputMethodManager keyboard = (InputMethodManager)myContext.getSystemService(Context.INPUT_METHOD_SERVICE);
                        keyboard.showSoftInput(searchText,0);
                    }
                }
            },300);
            
            searchOn = true;
    
        }  // end TagSearch.showSearch()

    
        // sets all appropriate views when transitioning back to normal tag tab
        public static void hideSearch()
        {
            // hide the search bar and shade
            searchText.setVisibility(View.GONE);
            shade.setVisibility(View.GONE);

            // show the title
            tempTitle.setVisibility(View.VISIBLE);
            tempAddButton.setVisibility(View.VISIBLE);

            if( ( searchResultsList != null ) && ( searchResultsList.size() > 0 ) )
            {
                TagSearch.hideSearchScroll();
            }
            
            searchText.removeTextChangedListener(TagSearch.searchListener);
            
            searchOn = false;

        }  // end TagSearch.hideSearch()

       
        public static void closeKeyboard()
        {
            if( searchText != null)
            {
                InputMethodManager keyboard = (InputMethodManager)myContext.getSystemService(Context.INPUT_METHOD_SERVICE);
                keyboard.hideSoftInputFromWindow(searchText.getWindowToken(),0);
            }
        }

        
        private static void showSearchScroll()
        {
            shade.setBackgroundColor(0x00000000);
            tagScroll.setVisibility(View.GONE);
            searchScroll.setVisibility(View.VISIBLE);
        }

        private static void hideSearchScroll()
        {
            shade.setBackgroundColor(0x77000000);
            searchScroll.setVisibility(View.GONE);
            tagScroll.setVisibility(View.VISIBLE);
        }


        // listener for the search bar EditText
        private static TextWatcher searchListener = new TextWatcher()
        {
            public void onTextChanged(CharSequence text, int start, int lengthBefore, int lengthAfter)
            {
                // necessary stub
            }

            public void beforeTextChanged(CharSequence text, int start, int count, int after)
            {
                // necessary stub
            }
            
            public void afterTextChanged(Editable text)
            {
                TagSearch.textChanged(text); 
            }

        };  // end TagSearch.searchListener declaration

        
        // called by the TextWatcher for our EditText
        // reloads search from database and refreshes search view
        private static void textChanged(Editable text)
        {
            searchResultsList = TagPeer.retrieveTagListLike( text.toString() );

            if( ( text.length() == 0 ) || ( searchResultsList.size() < 1 ) )
            {
                // if the search bar is empty
                TagSearch.hideSearchScroll();
            }
            else
            {
                TagSearch.refreshTagSearchList();
            }

        }  // end TagSearch.textChanged()

        
        private static void refreshTagSearchList()
        {
            // show results!
            tagSearchList.removeAllViews();
            TagSearch.showSearchScroll();
                
            // now load the tag search views
            TagFragment.refreshByTagList(searchResultsList,tagSearchList);
            
        }  // end TagSearch.refreshTagSearchList()

    
    }  // end TagSearch class declaration


}  // end TagFragment class declaration



