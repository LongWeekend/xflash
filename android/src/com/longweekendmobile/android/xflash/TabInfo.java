package com.longweekendmobile.android.xflash;

//  TabInfo.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  an information class for tab fragments

import android.os.Bundle;
import android.support.v4.app.Fragment;

public class TabInfo {
    
    public String tag;
    public Class<?> clss;
    public Bundle args;
    public Fragment fragment;
    
    TabInfo(String inTag,Class<?> inClass,Bundle inArgs)
    {
        tag = inTag;
        clss = inClass;
        args = inArgs;
    }

}  // end TabInfo class declaration


