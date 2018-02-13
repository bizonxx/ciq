//
// Copyright 2016-2017 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application;


var partialUpdatesAllowed = false;

// This implements an analog watch face
// Original design by Austen Harbour
class AnalogView extends WatchUi.WatchFace
{
	var fontClock;
    var font;
    var bkgImage;
    var bkgColor;
    var forColor;
    var isAwake;
    var screenShape;
    var stepsIcon;
    var phoneIcon;
    var nophoneIcon;
    var dndIcon;
    var alarmIcon;
    var notiIcon;
    var offscreenBuffer;
    var curClip;
    var screenCenterPoint;
    var fullScreenRefresh;
    var analogHands;

    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        screenShape = System.getDeviceSettings().screenShape;
        fullScreenRefresh = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // Load the custom font we use for drawing the 3, 6, 9, and 12 on the watchface.
        fontClock = WatchUi.loadResource(Rez.Fonts.id_font_arkitect);
        font = WatchUi.loadResource(Rez.Fonts.id_font_black_diamond);

		// Load the background image into memory
		bkgImage = null;//WatchUi.loadResource(Rez.Drawables.BackgroundImage);
		
		stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon); 
		if (System.getDeviceSettings() has :phoneConnected) {
			phoneIcon = WatchUi.loadResource(Rez.Drawables.PhoneIcon); 
			nophoneIcon = WatchUi.loadResource(Rez.Drawables.NoPhoneIcon); 
		} else {
			phoneIcon = null;
			nophoneIcon = null;
		}
		if (System.getDeviceSettings() has :doNotDisturb) {
            dndIcon = WatchUi.loadResource(Rez.Drawables.DndIcon);
        } else {
            dndIcon = null;
        }
        
        if (System.getDeviceSettings() has :alarmCount ) {
            alarmIcon = WatchUi.loadResource(Rez.Drawables.AlarmIcon);
        } else {
            alarmIcon = null;
        }
        
        if (System.getDeviceSettings() has :notificationCount ) {
            notiIcon = WatchUi.loadResource(Rez.Drawables.NotificationIcon);
        } else {
            notiIcon = null;
        }
	
		   
        // If this device supports BufferedBitmap, allocate the buffers we use for drawing
        if(Toybox.Graphics has :BufferedBitmap) {
            // Allocate a full screen size buffer with a palette of only 5 colors to draw
            // the background image of the watchface.  This is used to facilitate blanking
            // the second hand during partial updates of the display
            offscreenBuffer = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>dc.getHeight(),
                :palette=> [
                    Graphics.COLOR_LT_GRAY,
                    Graphics.COLOR_DK_RED,
                    Graphics.COLOR_RED,
                    Graphics.COLOR_BLACK,
                    Graphics.COLOR_WHITE
                ]
                //,:bitmapResource => bkgImage
            });

        } else {
            offscreenBuffer = null;
        }

        curClip = null;

        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
        
        analogHands = new AnalogHands(screenCenterPoint[0], screenCenterPoint[1], (screenCenterPoint[0] > screenCenterPoint[1] ? screenCenterPoint[1] : screenCenterPoint[0]) - 2);
       
    }

    // Handle the update event
    function onUpdate(dc) {
        var width;
        var height;
    	var clockTime = System.getClockTime();
        var secondHand;
        var targetDc = null;

        bkgColor = Graphics.COLOR_BLACK;//Application.getApp().getProperty("BackgroundColor");
        forColor = Graphics.COLOR_WHITE;//Application.getApp().getProperty("ForegroundColor");
 
        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullScreenRefresh = true;

        if(null != offscreenBuffer) {
            dc.clearClip();
            curClip = null;
            // If we have an offscreen buffer that we are using to draw the background,
            // set the draw context of that buffer as our target.
            targetDc = offscreenBuffer.getDc();
        } else {
            targetDc = dc;
        }

        width = targetDc.getWidth();
        height = targetDc.getHeight();
        

        // Fill the entire background with Black.
        targetDc.setColor(bkgColor, Graphics.COLOR_WHITE);
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

		// Draw background image
		if(bkgImage != null){
			targetDc.drawBitmap(width/2 - 150/2, height/2 - 140/2 , bkgImage); 
		}
        
  		// Draw status icons
        drawStatusIcons(targetDc, width * 0.5 ,  dc.getFontHeight(fontClock)*1.5 );
         //Draw the date string 
    	drawDateString( targetDc, width *0.75  , height *0.5 - dc.getFontHeight(font)/2 +3);
    	if( width <=height ){
   			drawBattString( targetDc, width*0.12 , height *0.5 - dc.getFontHeight(font)*0.5);
   			drawStepsString( targetDc, width /2, (height - dc.getFontHeight(fontClock)*2) );
 		}
        // Draw the tick marks around the edges of the screen
    	drawHashMarks(targetDc);
        // Draw hands 
        //drawHands (targetDc, clockTime);

		analogHands.draw(targetDc);
        // Output the offscreen buffers to the main display if required.
        drawBackground(dc);   
        
        if( partialUpdatesAllowed ){
        	onPartialUpdate(dc);
        }
	        
        fullScreenRefresh = false;
    }

  // Draws the clock tick marks around the outside edges of the screen.
    function drawHashMarks(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
		
		dc.setColor(bkgColor != Graphics.COLOR_WHITE ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        // Draw hashmarks differently depending on screen geometry.
        if (System.SCREEN_SHAPE_ROUND == screenShape) {
            var sX, sY;
            var eX, eY;
            var outerRad = width / 2;
            var innerRad = outerRad - 10;
            // Loop through each 15 minute block and draw tick marks.
            for (var i = Math.PI/6; i <= 11 * Math.PI / 6; i += (Math.PI / 3)) {
           // for (var i = Math.PI/2; i <= 3 * Math.PI / 2; i += (Math.PI / 2)) {
                // Partially unrolled loop to draw two tickmarks in 15 minute block.
                sY = outerRad + innerRad * Math.sin(i);
                eY = outerRad + outerRad * Math.sin(i);
                sX = outerRad + innerRad * Math.cos(i);
                eX = outerRad + outerRad * Math.cos(i);
                dc.drawLine(sX, sY, eX, eY);
                i += Math.PI / 6;// 2;
                sY = outerRad + innerRad * Math.sin(i);
                eY = outerRad + outerRad * Math.sin(i);
                sX = outerRad + innerRad * Math.cos(i);
                eX = outerRad + outerRad * Math.cos(i);
                dc.drawLine(sX, sY, eX, eY);
            }
        } else {
        	//dc.fillPolygon([[ width / 2.0 -1 , 2], [width / 2.0 -1, 12], [width / 2.0 +1, 12], [width / 2.0 +1, 2]]);
        	//dc.fillPolygon([[ width / 2.0 -1 , height - 2], [width / 2.0 -1, height -12], [width / 2.0 +1, height- 12], [width / 2.0 +1,height- 2]]);
        	//dc.fillPolygon([[ 2, height / 2.0 - 1], [12, height / 2.0 - 1], [12, height / 2.0 + 1], [2, height / 2.0 + 1]]);
        	//dc.fillPolygon([[ width -2, height / 2.0 - 1], [ width -12, height / 2.0 - 1], [width - 12, height / 2.0 + 1], [width -2, height / 2.0 + 1]]);
 			
 			var coords = [0, width / 4, (3 * width) / 4, width];
            for (var i = 0; i < coords.size(); i += 1) {
                var dx = ((width / 2.0) - coords[i]) / (height / 2.0);
                var upperX = coords[i] + (dx * 10);
                // Draw the upper hash marks.
                dc.fillPolygon([[coords[i] - 1, 2], [upperX - 1, 12], [upperX + 1, 12], [coords[i] + 1, 2]]);
                // Draw the lower hash marks.
                dc.fillPolygon([[coords[i] - 1, height-2], [upperX - 1, height - 12], [upperX + 1, height - 12], [coords[i] + 1, height - 2]]);
            }
            
        }
      
        // Draw the 3, 6, 9, and 12 hour labels.
        dc.drawText((width / 2), 0, fontClock, "12", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width , (height / 2) - 15, fontClock, "3", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(width / 2, height - 30, fontClock, "6", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(0, (height / 2) - 15, fontClock, "9", Graphics.TEXT_JUSTIFY_LEFT);
 
 
    }
    // Draw the date string into the provided buffer at the specified location
    function drawDateString( dc, x, y ) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        //var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
        var dateStr = Lang.format("$1$", [info.day]);
        var fontHeight = dc.getFontHeight( font /*Graphics.FONT_TINY*/);

        dc.setColor(forColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, fontHeight+4, fontHeight-3);
        // draw frame
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, fontHeight+4, fontHeight-3);
        dc.setPenWidth(1);
        
        dc.setColor(bkgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + fontHeight/2 +2 , y-2 , font /*Graphics.FONT_TINY*/,dateStr, Graphics.TEXT_JUSTIFY_CENTER); 
    }
    
   // draw status Icons
   function drawStatusIcons(dc, x, y) {
   
   		
   		var icons = new [4];

   		var width = 0;
   		
   		// Draw phone connection status Icon
   		if (null != alarmIcon && System.getDeviceSettings().alarmCount >0 ){
         	icons[0] = alarmIcon;
         	width += icons[0].getWidth();
        }
        if (null != phoneIcon ){
         	icons[1] = System.getDeviceSettings().phoneConnected ? phoneIcon : nophoneIcon;
         	width += icons[1].getWidth();
        }
        if (null != dndIcon && System.getDeviceSettings().doNotDisturb){
         	icons[2] = dndIcon;
         	width += icons[2].getWidth();
        }
        
         if (null != notiIcon && System.getDeviceSettings().notificationCount >0 ) {
            icons[3] = notiIcon;
            width += icons[3].getWidth();
        } 
        
        width = x - width/2;
   		for ( var i =0 ; i < 4 ;i++ ){
   			if(icons[i] != null){
   				dc.drawBitmap(width, y, icons[i]);
   				width += icons[i].getWidth();
   			}
   		}
   }
    // Draw the baterry string into the provided buffer at the specified location
    function drawBattString( dc, x, y ) {

   		// Draw the battery percentage directly to the main screen.
        var dataString ="";// (System.getSystemStats().battery + 0.5).toNumber().toString() + "%";
		var fontHeight = dc.getFontHeight(font/*Graphics.FONT_TINY*/);
        // Also draw the background process data if it is available.
        /*var backgroundData = Application.getApp().temperature;
        if(backgroundData != null) {
            dataString += " - " + backgroundData;
        }*/
        dc.setColor(forColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font/* Graphics.FONT_TINY*/, dataString, Graphics.TEXT_JUSTIFY_RIGHT);
        
       // draw battery
        dc.drawRectangle(x+5, y+fontHeight/4.0+2, fontHeight, fontHeight/2);
        dc.drawRectangle(x+5+fontHeight, y+fontHeight/3.0+3, fontHeight/8+1, fontHeight/4+1);
        dc.fillRectangle(x+5 +2, y+fontHeight/4.0+2 +2, (fontHeight-4)*(System.getSystemStats().battery + 0.5).toNumber()/100, fontHeight/2-4);

    }
    
    function drawStepsString( dc, x, y ) {
      
        // get ActivityMonitor info
		var info = ActivityMonitor.getInfo();

		var steps = info.steps;	
        
		var stepsString = Lang.format("$1$", [steps]);
		var width = stepsIcon.getWidth() + 5 + dc.getTextWidthInPixels(stepsString, font/*Graphics.FONT_TINY*/);
		dc.drawBitmap(x- width/2 ,y , stepsIcon);
			
        dc.setColor(forColor, Graphics.COLOR_TRANSPARENT);
        //dc.drawText(x - width/2 + stepsIcon.getWidth() + 5, y, Graphics.FONT_TINY, stepsString, Graphics.TEXT_JUSTIFY_LEFT);
        //Anti-aliasing font no need full palette buffer
        dc.drawText(x - width/2 + stepsIcon.getWidth() + 5, y, font, stepsString, Graphics.TEXT_JUSTIFY_LEFT);
        
   }
    
    // Handle the partial update event
    function onPartialUpdate( dc ) {
        // If we're not doing a full screen refresh we need to re-draw the background
        // before drawing the updated second hand position. Note this will only re-draw
        // the background in the area specified by the previously computed clipping region.

        if(!fullScreenRefresh) {
            drawBackground(dc);
        }

        var clockTime = System.getClockTime();
        var secondHand = (clockTime.sec / 60.0) * Math.PI * 2;
        var secondHandPoints = analogHands.getSecondHandPoints(clockTime);
    	    
        // Update the cliping rectangle to the new location of the second hand.
        curClip = getBoundingBox( secondHandPoints);
        
        var bboxwidth = curClip[1][0] - curClip[0][0] + 1;
        var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
        dc.setClip(curClip[0][0], curClip[0][1], bboxwidth, bboxHeight);
        
        analogHands.drawSecondHand(dc, secondHandPoints);
        
        //dc.drawRectangle(curClip[0][0], curClip[0][1], bboxwidth, bboxHeight);

    }

    // Compute a bounding box from the passed in points
    function getBoundingBox( points ) {
        var min = [9999,9999];
        var max = [0,0];

        for (var i = 0; i < points.size(); ++i) {
            if(points[i][0] < min[0]) {
                min[0] = points[i][0];
            }

            if(points[i][1] < min[1]) {
                min[1] = points[i][1];
            }

            if(points[i][0] > max[0]) {
                max[0] = points[i][0];
            }

            if(points[i][1] > max[1]) {
                max[1] = points[i][1];
            }
        }

        return [min, max];
    }

    // Draw the watch face background
    // onUpdate uses this method to transfer newly rendered Buffered Bitmaps
    // to the main display.
    // onPartialUpdate uses this to blank the second hand from the previous
    // second before outputing the new one.
    function drawBackground(dc) {

        //If we have an offscreen buffer that has been written to
        //draw it to the screen.
        if( null != offscreenBuffer ) {
            dc.drawBitmap(0, 0, offscreenBuffer);
        	
        }

    }

    // This method is called when the device re-enters sleep mode.
    // Set the isAwake flag to let onUpdate know it should stop rendering the second hand.
    function onEnterSleep() {
        isAwake = false;
        analogHands.sleepMode = true;
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
        if ( analogHands != null) {
    		analogHands.sleepMode = false;
    		WatchUi.animate(analogHands, :angleOffset, WatchUi.ANIM_TYPE_EASE_IN_OUT , 0, MAXWIDTH, 2, null);
    	}
    }
}

class AnalogDelegate extends WatchUi.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }
}
