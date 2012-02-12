package com.longweekendmobile.android.xflash;

//  DifficultyFragment.java
//  Xflash
//
//  Created by Todd Presson on 2/5/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public View onCreateView(LayoutInflater  ,ViewGroup  ,Bundle  )     @over
//
//  private void setSeekBars()

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.RadioGroup;
import android.widget.RelativeLayout;
import android.widget.SeekBar;

public class DifficultyFragment extends Fragment
{
    private static final String MYTAG = "XFlash DifficultyFragment";
   
    // properties for handling color theme transitions
    private static LinearLayout difficultyLayout;

    private RadioGroup myGroup;
    private SeekBar studyPoolBar;
    private SeekBar frequencyBar;


    // see android.support.v4.app.Fragment#onCreateView()
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState)
    {
        // inflate our layout for the HelpPage fragment
        difficultyLayout = (LinearLayout)inflater.inflate(R.layout.difficulty, container, false);

        // set the seek bars so we can change their values
        studyPoolBar = (SeekBar)difficultyLayout.findViewById(R.id.difficulty_studypool);
        studyPoolBar.setOnSeekBarChangeListener(barChange);
        
        frequencyBar = (SeekBar)difficultyLayout.findViewById(R.id.difficulty_frequency);
        frequencyBar.setOnSeekBarChangeListener(barChange);

        // set our check listener for the radio group
        myGroup = (RadioGroup)difficultyLayout.findViewById(R.id.difficulty_group);
        myGroup.setOnCheckedChangeListener(radioChange);

        // TODO - this is not loading when the tab is switched to
        // load the title bar elements and pass them to the color manager
        RelativeLayout titleBar = (RelativeLayout)difficultyLayout.findViewById(R.id.difficulty_heading);
        XflashSettings.setupColorScheme(titleBar); 

        // set the text values of the four radio buttons
        XflashRadio radioArray[] = { null, null, null, null };

        radioArray[0] = (XflashRadio)difficultyLayout.findViewById(R.id.difficulty_easy);
        radioArray[0].setButtonText("Easy");

        radioArray[1] = (XflashRadio)difficultyLayout.findViewById(R.id.difficulty_medium);
        radioArray[1].setButtonText("Medium");

        radioArray[2] = (XflashRadio)difficultyLayout.findViewById(R.id.difficulty_hard);
        radioArray[2].setButtonText("Hard");

        radioArray[3] = (XflashRadio)difficultyLayout.findViewById(R.id.difficulty_custom);
        radioArray[3].setButtonText("Custom");

        XflashSettings.setRadioColors(radioArray);

        // and set the radio group to the active button
        switch( XflashSettings.getDifficultyMode() )
        {
            case XflashSettings.LWE_DIFFICULTY_EASY:    myGroup.check(R.id.difficulty_easy);    break;
            case XflashSettings.LWE_DIFFICULTY_MEDIUM:  myGroup.check(R.id.difficulty_medium);  break;
            case XflashSettings.LWE_DIFFICULTY_HARD:    myGroup.check(R.id.difficulty_hard);    break;
            case XflashSettings.LWE_DIFFICULTY_CUSTOM:  myGroup.check(R.id.difficulty_custom);  break;
            default:    Log.d(MYTAG,"Error settings active radio");                             break;    
        }

        // last, set the seek bars to the correct levels
        setSeekBars();

        return difficultyLayout;
    }

    // sets the seek bars to the appropriate value depending on difficulty mode
    private void setSeekBars()
    {
        boolean barsEnabled = false;

        switch( XflashSettings.getDifficultyMode() )
        {
            case 0: studyPoolBar.setProgress(XflashSettings.LWE_STUDYPOOL_EASY);
                    frequencyBar.setProgress(XflashSettings.LWE_FREQUENCY_EASY);
                    barsEnabled = false;
                    break;
            case 1: studyPoolBar.setProgress(XflashSettings.LWE_STUDYPOOL_MEDIUM);
                    frequencyBar.setProgress(XflashSettings.LWE_FREQUENCY_MEDIUM);
                    barsEnabled = false;
                    break;
            case 2: studyPoolBar.setProgress(XflashSettings.LWE_STUDYPOOL_HARD);
                    frequencyBar.setProgress(XflashSettings.LWE_FREQUENCY_HARD);
                    barsEnabled = false;
                    break;
            case 3: studyPoolBar.setProgress( XflashSettings.getCustomStudyPool() );
                    frequencyBar.setProgress( XflashSettings.getCustomFrequency() );
                    barsEnabled = true;
                    break;
            default:    Log.d(MYTAG,"Error in setSeekBars()");
                        barsEnabled = false;
                        break;
        }

        // set the bars as movable / immovable 
        if( barsEnabled )
        {
            studyPoolBar.setEnabled(true);
            frequencyBar.setEnabled(true); 
        }
        else
        {
            studyPoolBar.setEnabled(false);
            frequencyBar.setEnabled(false); 
        }

    }  // end setSeekBars()


    // change listener for the difficulty radio group 
    private RadioGroup.OnCheckedChangeListener radioChange = new RadioGroup.OnCheckedChangeListener()
    {
        public void onCheckedChanged(RadioGroup group, int checkedId) 
        {
            switch(checkedId)
            {
                case R.id.difficulty_easy:      XflashSettings.setDifficultyMode(0);    break;
                case R.id.difficulty_medium:    XflashSettings.setDifficultyMode(1);    break;
                case R.id.difficulty_hard:      XflashSettings.setDifficultyMode(2);    break;
                case R.id.difficulty_custom:    XflashSettings.setDifficultyMode(3);    break;
                default:    break;
            }

            setSeekBars();

        } 

    };  // end radioChange radio group listener


    // When someone moves the volume bar
    private SeekBar.OnSeekBarChangeListener barChange =new SeekBar.OnSeekBarChangeListener() 
    {
        public void onProgressChanged(SeekBar seekBar,int progress,boolean fromUser)
        {
        
        }
        
        // Light up the read out when scrolling
        public void onStartTrackingTouch(SeekBar seekBar)
        {
        
        }

        // when they're done adjusting, set the corresponding values
        public void onStopTrackingTouch(SeekBar seekBar)
        {
            int tempInt = seekBar.getProgress(); 
            
            switch( seekBar.getId() )
            {
                case R.id.difficulty_studypool:  XflashSettings.setCustomStudyPool(tempInt);
                                                break;
                case R.id.difficulty_frequency: XflashSettings.setCustomFrequency(tempInt);
                                                break;
                default:                        Log.d(MYTAG,"Error in SeekBar listener");
                                                break;
            }
        }

    };  // end barChange seek listener


}  // end HelpPageFragment class declaration





