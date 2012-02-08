package com.longweekendmobile.android.xflash;

//  XflashRadio.java
//  Xflash
//
//  Created by Todd Presson on 2/3/2012.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//      *** ALL METHODS STATIC ***
//

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.util.Log;
import android.widget.RadioButton;

public class XflashRadio extends RadioButton
{
    // TODO - I have no idea how this will render on smaller screens

    private static final float LWE_RADIO_WIDTH = 70;
    private static final float LWE_RADIO_HEIGHT = 34;
    
    private float xOffset;
    private String buttonText;
    private Paint myPaint = new Paint();

    public XflashRadio(Context context)
    {
        super(context);
        setTextAttrs();
    }

    public XflashRadio(Context context, AttributeSet attrbs)
    { 
        super(context, attrbs);
        setTextAttrs();
    }
    
    @Override
    protected void onDraw(Canvas canvas) 
    {
        super.onDraw(canvas);
        
        canvas.drawText(buttonText,xOffset,22,myPaint);
    }       

    public void setButtonText(String inText)
    {
        buttonText = inText;
        
        // measure the input text, set display offset to center
        float tempWidth = myPaint.measureText(buttonText);
        xOffset = ( ( LWE_RADIO_WIDTH / 2 ) - ( tempWidth / 2 ) );
    }

    private void setTextAttrs()
    {
        // set the button text to white, size myPaint.setColor(0xFFFFFFFF);
        myPaint.setColor(0xFFFFFFFF);
        myPaint.setTextSize((float)15);
    }

}  // end XflashRadio class declaration


