using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Lang as Lang;

var background;
var colorDate;
var colorHour;
var colorMin;
var colorSec;
var colorDigit;
var animationTime;
var arcsOn;
var arcsRoundedOn;
var simpleModeOnSleep;
var handsOn;
var orbitsOn;
var digitsOn;
var statusOn;
var fontSize;
var widthSize;

const MAXWIDTH = 60;

class AnalogHands extends Ui.Drawable {
		
	var simpleMode;
	var sleepMode;
	var font;
	
    function initialize() {
       Drawable.initialize( { :identifier => "Hands" } );
       width = MAXWIDTH;   
       sleepMode = true;
       
    }
    function draw(dc){
       
        var hourAngle;
        var minAngle;
        var secAngle;
        
        var fontHeight;
                     
        var info = Calendar.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$", [info.day_of_week.substring(0,2), info.day]);
        var clockTime = Sys.getClockTime();
        
        var offset = dc.getHeight() > dc.getWidth() ? dc.getWidth() : dc.getHeight();
        var ringWidth = offset /widthSize;
        
        font = fontSize;
                
        if ( font < 0 ) {

	        font = Gfx.FONT_LARGE;
	        var fontHeight = Gfx.getFontHeight(font) - Gfx.getFontDescent(font)*2;
	
		    if ( fontHeight > ringWidth ) {
		   		font = Gfx.FONT_MEDIUM;
		   		fontHeight = Gfx.getFontHeight(font) - Gfx.getFontDescent(font)*2;
		    }
		    if ( fontHeight > ringWidth ) {
		   		font = Gfx.FONT_SMALL;
		   		fontHeight = Gfx.getFontHeight(font) - Gfx.getFontDescent(font)*2;
		    }
		    if ( fontHeight > ringWidth ) {
		   		font = Gfx.FONT_TINY;
		   		fontHeight = Gfx.getFontHeight(font) - Gfx.getFontDescent(font)*2;
		    }
		   	if ( fontHeight > ringWidth ) {
		   		font = Gfx.FONT_XTINY;
		   		fontHeight = Gfx.getFontHeight(font) - Gfx.getFontDescent(font)*2;
		    }
	    } 
	    fontHeight = Gfx.getFontHeight(font) - Gfx.getFontDescent(font)*2;
	   
	   if ( !sleepMode && !digitsOn && statusOn ) {
	   		dc.setColor(colorDate, Gfx.COLOR_TRANSPARENT);
	   		drawPower(dc, 0, -ringWidth - fontHeight/4, fontHeight/2 + fontHeight/8, fontHeight - fontHeight/8, Sys.getSystemStats().battery);
	   		if ( Sys.getDeviceSettings().phoneConnected ) {
       			drawBluetoot(dc, 0, ringWidth + fontHeight/4, fontHeight/2 + fontHeight/8, fontHeight - fontHeight/8);
       		}
	   	    
	   }

        // Draw the hour
        hourAngle = ( ( clockTime.hour % 12 ) * 60 ) + clockTime.min ;
        hourAngle = ( (( width.toLong() + hourAngle / 12) % 60 ) / 60.0 ) * Math.PI * 2;
        dc.setColor(colorHour ,Gfx.COLOR_TRANSPARENT);
		drawRing(dc, sleepMode && simpleModeOnSleep || (width + (( ( clockTime.hour % 12 ) * 60 ) + clockTime.min) /12 ) < 60 ? hourAngle : 0, hourAngle, offset/2 - ringWidth*2 - ringWidth/4, ringWidth, orbitsOn, digitsOn ? clockTime.hour == 12 ? 12 : System.getDeviceSettings().is24Hour ? clockTime.hour : clockTime.hour % 12 : null); 
         
        // Draw the minute  
        minAngle = ( (( width.toLong() + clockTime.min ) % 60 ) / 60.0 ) * Math.PI * 2;     
        dc.setColor(colorMin ,Gfx.COLOR_TRANSPARENT);
        drawRing(dc, sleepMode && simpleModeOnSleep || (width + clockTime.min) < 60 ? minAngle : 0, minAngle, offset/2 - ringWidth + ringWidth/3, ringWidth, orbitsOn, digitsOn ? clockTime.min : null);
        
	
	    // Draw the second
	    secAngle = ( (( width.toLong() + clockTime.sec) % 60 ) / 60.0 ) * Math.PI * 2;
		if ( !sleepMode ){
	        
	        dc.setColor(colorSec ,Gfx.COLOR_TRANSPARENT);
	        drawRing(dc,  secAngle, secAngle, offset/2 - ringWidth + ringWidth/3, ringWidth, false, digitsOn ? clockTime.sec : null);
	    }
	    		
		//Draw the date    
		dc.setColor(colorDate, Gfx.COLOR_TRANSPARENT);
		if ( digitsOn ){     
        	drawRing(dc, 0, 0, 0, ringWidth*2 + ringWidth/4, false, dateStr);
        	if ( !sleepMode && statusOn ) {
        		dc.setColor(colorDigit, Gfx.COLOR_TRANSPARENT);
        		drawPower(dc, 0, -ringWidth - fontHeight/4, fontHeight/2 + fontHeight/8, fontHeight - fontHeight/8, Sys.getSystemStats().battery);
       			if ( Sys.getDeviceSettings().phoneConnected ) {
       				drawBluetoot(dc, 0, ringWidth + fontHeight/4, fontHeight/2 + fontHeight/8, fontHeight - fontHeight/4);
       			}       
       		}
       	} else {
       		drawRing(dc, 0, 0, 0, ringWidth/2, false, "");
       	}


    }

    
    function drawHand(dc, angle, length, width)
    {
        // Map out the coordinates of the watch hand
        var coords = [ [-(width/2),0], [-(width/2), -length], [width/2, -length], [width/2, 0] ];
        var result = new [4];
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ centerX+x, centerY+y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
        dc.fillCircle(centerX + (length * sin), centerY - (length * cos), width/2 );

    }
        
    function drawRing(dc, angleStart, angle, length, width, orbit, text)
    {
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        
        if ( handsOn ){
        	drawHand(dc, angle, length + width/4, width/2);       
        }
        
        return;
                
        if( orbit ) {

 			dc.setPenWidth(1);
			dc.drawCircle(centerX, centerY , length);
			
        } 
        
	    if( angleStart != angle ){
	    	if ( arcsOn ){
	        	if( dc has :drawArc ){			
					dc.setPenWidth(width);
			 		dc.drawArc(centerX, centerY, length,  Gfx.ARC_CLOCKWISE, -( angleStart/(Math.PI * 2)*360 )+90, -( angle/(Math.PI * 2)*360 )+90);
			 		if ( arcsRoundedOn ){
			 			dc.fillCircle(centerX, centerY - length, width/2);
			 			dc.fillCircle(centerX + (length * Math.sin(angle)), centerY - (length * Math.cos(angle)), width/2 );
			 		}
		  
		 		} else {
	 				dc.drawText(centerX, centerY+50, Gfx.FONT_SMALL, "Please,", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
	 				dc.drawText(centerX, centerY+65, Gfx.FONT_SMALL, "update firmware", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
	 			}
 			}
 		} 
 		 
 		if ( text != null ){
	 		dc.fillCircle(centerX + ( length * Math.sin(angle) ), centerY - ( length * Math.cos(angle) ), width/2 + width/3);
	        dc.setColor(colorDigit, Gfx.COLOR_TRANSPARENT);
	        dc.drawText(centerX + ( length * Math.sin(angle) ), centerY - ( length * Math.cos(angle) ), font, text, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
		} else if( !handsOn && (!arcsOn || sleepMode && simpleModeOnSleep) ){
			dc.fillCircle(centerX + (length * Math.sin(angle)), centerY - (length * Math.cos(angle)), width/2 );
		}
	    

    }
    
}

