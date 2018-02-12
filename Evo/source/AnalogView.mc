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
    var font;
    var bkgImage;
    var bkgColor;
    var forColor;
    var isAwake;
    var screenShape;
    var stepsIcon;
    var offscreenBuffer;
    var curClip;
    var screenCenterPoint;
    var fullScreenRefresh;

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
        font = WatchUi.loadResource(Rez.Fonts.id_font_black_diamond);

		// Load the background image into memory
		bkgImage = WatchUi.loadResource(Rez.Drawables.BackgroundImage);
		
		stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon); 
               
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

    }

    // This function is used to generate the coordinates of the 4 corners of the polygon
    // used to draw a watch hand. The coordinates are generated with specified length,
    // tail length, and width and rotated around the center point at the provided angle.
    // 0 degrees is at the 12 o'clock position, and increases in the clockwise direction.
      function generateHandCoordinates(centerPoint, angle, handLength, tailLength, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width/2), tailLength], [-(width / 2), -handLength], [width / 2, -handLength]  , [width/2 , tailLength]];
        
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }
    
    function generateHandCoordinates1(centerPoint, angle, handLength, tailLength, width, tailWidthLength) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width*0.75), tailLength], [-(width*0.75), tailWidthLength ] , [-(width /2), tailWidthLength ], [-(width / 2), -handLength], [ 1 / 2, - handLength - width], [width / 2, -handLength] ,[width / 2, tailWidthLength]  , [width*0.75 , tailWidthLength] , [width*0.75 , tailLength]];
        //var coords = [[-(width/2), tailLength], [-(width / 2), -handLength], [width / 2, -handLength]  , [width/2 , tailLength]];
        
        var result = new [9];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
	
        // Transform the coordinates
        for (var i = 0; i < 9; i += 1) {
            
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
         }
       
        return result;
    }
    
    function generateHandCoordinates2(centerPoint, angle, handLength, tailLength, widthStart, widthEnd ) {
        // Map out the coordinates of the watch hand
        var coords = [[-(widthStart / 2), tailLength], [-(widthEnd / 2), -handLength], [widthEnd / 2, -handLength], [widthStart / 2, tailLength]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }
    
    function generateHandCoordinates3(centerPoint, angle, handLength, tailLength, widthStart, widthEnd ) {
        // Map out the coordinates of the watch hand
        var coords = [[-(widthStart / 2), tailLength], [-(widthEnd / 2), -handLength], [1 / 2, -handLength], [1 / 2, tailLength]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }
    function generateHandCoordinates4(centerPoint, angle, handLength, tailLength, widthStart, widthEnd ) {
        // Map out the coordinates of the watch hand
        var coords = [[-(1 / 2), tailLength], [-(1 / 2), -handLength], [widthEnd / 2, -handLength], [widthStart / 2, tailLength]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
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
            //for (var i = Math.PI/6; i <= 11 * Math.PI / 6; i += (Math.PI / 3)) {
            for (var i = Math.PI/2; i <= 3 * Math.PI / 2; i += (Math.PI / 2)) {
                // Partially unrolled loop to draw two tickmarks in 15 minute block.
                sY = outerRad + innerRad * Math.sin(i);
                eY = outerRad + outerRad * Math.sin(i);
                sX = outerRad + innerRad * Math.cos(i);
                eX = outerRad + outerRad * Math.cos(i);
                dc.drawLine(sX, sY, eX, eY);
                i += Math.PI / 2;//6;
                sY = outerRad + innerRad * Math.sin(i);
                eY = outerRad + outerRad * Math.sin(i);
                sX = outerRad + innerRad * Math.cos(i);
                eX = outerRad + outerRad * Math.cos(i);
                dc.drawLine(sX, sY, eX, eY);
            }
        } else {
        	dc.fillPolygon([[ width / 2.0 -1 , 2], [width / 2.0 -1, 12], [width / 2.0 +1, 12], [width / 2.0 +1, 2]]);
        	dc.fillPolygon([[ width / 2.0 -1 , height - 2], [width / 2.0 -1, height -12], [width / 2.0 +1, height- 12], [width / 2.0 +1,height- 2]]);
        	dc.fillPolygon([[ 2, height / 2.0 - 1], [12, height / 2.0 - 1], [12, height / 2.0 + 1], [2, height / 2.0 + 1]]);
        	dc.fillPolygon([[ width -2, height / 2.0 - 1], [ width -12, height / 2.0 - 1], [width - 12, height / 2.0 + 1], [width -2, height / 2.0 + 1]]);
 			
 			/*var coords = [0, width / 4, (3 * width) / 4, width];
            for (var i = 0; i < coords.size(); i += 1) {
                var dx = ((width / 2.0) - coords[i]) / (height / 2.0);
                var upperX = coords[i] + (dx * 10);
                // Draw the upper hash marks.
                dc.fillPolygon([[coords[i] - 1, 2], [upperX - 1, 12], [upperX + 1, 12], [coords[i] + 1, 2]]);
                // Draw the lower hash marks.
                dc.fillPolygon([[coords[i] - 1, height-2], [upperX - 1, height - 12], [upperX + 1, height - 12], [coords[i] + 1, height - 2]]);
            }*/
            
        }
      
        // Draw the 3, 6, 9, and 12 hour labels.
  /*       dc.drawText((width / 2), 2, font, "12", Graphics.TEXT_JUSTIFY_CENTER);
       dc.drawText(width - 2, (height / 2) - 15, font, "3", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(width / 2, height - 30, font, "6", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(2, (height / 2) - 15, font, "9", Graphics.TEXT_JUSTIFY_LEFT);
 */
 
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
		targetDc.drawBitmap(width/2 - 150/2, height/2 - 140/2 , bkgImage);
        
        
         //Draw the date string 
	    	drawDateString( targetDc, width *0.75 + dc.getFontHeight(font)/2 , height *0.5 - dc.getFontHeight(font)/2 +2);
	    	if( width <=height ){
	   			drawBattString( targetDc, width /2 , dc.getFontHeight(font)*0.5);
	   			drawStepsString( targetDc, width /2, (height - dc.getFontHeight(font)*1.5) );
	   		}
	   		
        if ( !Application.getApp().digital ){
        	

			
            // Draw the tick marks around the edges of the screen
        	drawHashMarks(targetDc);
	        // Draw hands 
	        drawHands (targetDc, clockTime);
	
	        // Output the offscreen buffers to the main display if required.
	        drawBackground(dc);   
	        //drawHands (targetDc, clockTime);   
	  
	        if ( isAwake ) {
	            // Otherwise, if we are out of sleep mode, draw the second hand
	            // directly in the full update method.
	            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
	            secondHand = (clockTime.sec / 60.0) * Math.PI * 2;
	
	            dc.fillPolygon(generateHandCoordinates1(screenCenterPoint, secondHand, screenCenterPoint[0]*0.95, screenCenterPoint[0]*0.40, 6 , screenCenterPoint[0]*0.20));
	            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_BLACK);
       			//dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], 6);

		       dc.fillPolygon(generateHandCoordinates1(screenCenterPoint, secondHand, screenCenterPoint[0]*0.95-2, screenCenterPoint[0]*0.40-2, 4, screenCenterPoint[0]*0.20 +2));
		       dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
		       dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], 3);
	        } else if( partialUpdatesAllowed ) {
	            // If this device supports partial updates and they are currently
	            // allowed run the onPartialUpdate method to draw the second hand.
	            dc.setColor(Graphics.COLOR_DK_RED,Graphics.COLOR_BLACK);
	            onPartialUpdate( dc );
	            }
        } else {

        		drawBackground(dc);  
        
		        var timeFormat = "$1$:$2$";
		        var clockTime = System.getClockTime();
		        var hours = clockTime.hour;
		        if (!System.getDeviceSettings().is24Hour) {
		            if (hours > 12) {
		                hours = hours - 12;
		            }
		        } 
		        
				var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
				
		        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
		        dc.drawText(width/2,height/2 - dc.getFontHeight(Graphics.FONT_SYSTEM_NUMBER_THAI_HOT)/2, Graphics.FONT_SYSTEM_NUMBER_THAI_HOT, timeString, Graphics.TEXT_JUSTIFY_CENTER);

        }
    
	        
        fullScreenRefresh = false;
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
    
  
    // Draw the baterry string into the provided buffer at the specified location
    function drawBattString( dc, x, y ) {

	   		// Draw the battery percentage directly to the main screen.
	        var dataString = (System.getSystemStats().battery + 0.5).toNumber().toString() + "%";
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
    
    function drawHands( dc , clockTime ) { 

    	var width = dc.getWidth();
        var height = dc.getHeight();
        var minuteHandAngle;
        var hourHandAngle;
        var secondHand;
        var maxHand = (width > height ? height : width)/2 - 2;
        

        //Use gray to draw the hour hands
        dc.setColor(bkgColor, Graphics.COLOR_TRANSPARENT);
        // Draw the hour hand. Convert it to minutes and compute the angle.
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;

        dc.fillPolygon(generateHandCoordinates2(screenCenterPoint, hourHandAngle, maxHand*0.7, maxHand*0.3, maxHand*0.15, maxHand*0.08));
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(generateHandCoordinates3(screenCenterPoint, hourHandAngle, maxHand*0.7-2, maxHand*0.3-2, maxHand*0.15-2, maxHand*0.08-2));
        dc.setColor(forColor, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(generateHandCoordinates4(screenCenterPoint, hourHandAngle, maxHand*0.7-2, maxHand*0.3-2, maxHand*0.15-2, maxHand*0.08-2));

        //Use gray to draw the minute hands
        dc.setColor(bkgColor, Graphics.COLOR_TRANSPARENT);
        // Draw the minute hand.
        minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        
        dc.fillPolygon(generateHandCoordinates2(screenCenterPoint, minuteHandAngle, maxHand*0.9,  maxHand*0.3, maxHand*0.12, maxHand*0.05));
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(generateHandCoordinates3(screenCenterPoint, minuteHandAngle, maxHand*0.9- 2, maxHand*0.3-2, maxHand*0.12-2, maxHand*0.05-2));
        dc.setColor(forColor, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(generateHandCoordinates4(screenCenterPoint, minuteHandAngle, maxHand*0.9 -2, maxHand*0.3-2, maxHand*0.12-2, maxHand*0.05-2));

        // Draw the arbor in the center of the screen.
        dc.setColor(bkgColor != Graphics.COLOR_WHITE ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(width / 2, height / 2, 12);
        dc.setColor(bkgColor,Graphics.COLOR_BLACK);
        dc.fillCircle(width / 2, height / 2, 6);
        dc.drawCircle(width / 2, height / 2, 12);
        dc.setColor(Graphics.COLOR_DK_RED,Graphics.COLOR_BLACK);
        dc.fillCircle(width / 2, height / 2, 5);
        
        
    }

    // Handle the partial update event
    function onPartialUpdate( dc ) {
        // If we're not doing a full screen refresh we need to re-draw the background
        // before drawing the updated second hand position. Note this will only re-draw
        // the background in the area specified by the previously computed clipping region.
      
      	if ( Application.getApp().digital ) { return; }
      
        if(!fullScreenRefresh) {
            drawBackground(dc);
        }

		
		
        var clockTime = System.getClockTime();
        var secondHand = (clockTime.sec / 60.0) * Math.PI * 2;
        var secondHandPoints = generateHandCoordinates(screenCenterPoint, secondHand, screenCenterPoint[0]*0.95, screenCenterPoint[0]*0.40, 5);
        //var secondHandPoints =generateHandCoordinates1(screenCenterPoint, secondHand, screenCenterPoint[0]*0.95-2, screenCenterPoint[0]*0.40-2, 5, screenCenterPoint[0]*0.20 );
		    
        // Update the cliping rectangle to the new location of the second hand.
        curClip = getBoundingBox( secondHandPoints);
        
        //curClip = getBoundingBox( [secondHandPoints[0], secondHandPoints[3], secondHandPoints[4],secondHandPoints[5] ,secondHandPoints[8]]);
        var bboxWidth = curClip[1][0] - curClip[0][0] + 1;
        var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
        dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);
 
 		
        // Draw the second hand to the screen.
        dc.setColor(Graphics.COLOR_DK_RED,Graphics.COLOR_BLACK);
        //dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], 7);
      
        dc.fillPolygon(secondHandPoints);
    
       // dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
       //dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], 5);

       // dc.fillPolygon(generateHandCoordinates(screenCenterPoint, secondHand, screenCenterPoint[0]*0.90-2, 58, 4, 22));
       // dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
       // dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], 3);
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
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
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
