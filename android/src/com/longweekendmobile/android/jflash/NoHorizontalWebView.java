package com.longweekendmobile.android.jflash;

//  NoHorizontalWebView.java
//  jFlash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  a custom WebView that will not scroll horizontally

import android.os.Bundle;
import android.content.Context;
import android.util.AttributeSet;
import android.webkit.WebView;

public class NoHorizontalWebView extends WebView 
{
    public NoHorizontalWebView(Context context)
    {
        super(context);
    }
     
    public NoHorizontalWebView(Context context, AttributeSet attrs)
    {
        super(context,attrs);
    }
     
    // for any scroll event, override with 0 for x values
    @Override
    public void scrollBy(int x,int y)
    {
        super.scrollBy(0,y);
    }

    @Override
    public void scrollTo(int x,int y)
    {
        super.scrollTo(0,y);
    }

}  // end NoHorizontalWebView class declaration




