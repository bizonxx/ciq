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

class OrbitClock extends Ui.Drawable {
		
	var simpleMode;
	var sleepMode;
	var font;
	
    function initialize() {
       Drawable.initialize( { :identifier => "OrbitClock" } );
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
    
    function drawPower(dc, x, y, width, height, power){
    
    	x = dc.getWidth() / 2 + x;
        y = dc.getHeight() / 2 + y;
            		    	        

    	dc.fillPolygon([[x + width/2 -1 , y + height/2]
    					,[x - width/2, y + height/2]
    					,[x - width/2, y - height/3]
    					,[x - width/3, y - height/3]
    					,[x - width/3, y - height/2]
    					,[x + width/3, y - height/2]
    					,[x + width/3, y - height/3]
    					,[x + width/2, y - height/3]
    					,[x + width/2, y + height/2]
    					
    					,[x + width/2 -1, y + height/2]
    					,[x + width/2 -1, y - height/3 +1]
    					,[x - width/2 +1, y - height/3 +1]
    					,[x - width/2 +1, y + height/2 -1 - ((height - height/3) * (power/100))]
    					,[x + width/2 -1, y + height/2 -1 - ((height - height/3) * (power/100))]
    					]);
    }
    
    function drawBluetoot(dc, x, y, width, height){
    
    	x = dc.getWidth() / 2 + x;
        y = dc.getHeight() / 2 + y;
   
    	dc.fillPolygon([[x - width/2 -2, y - height/4]
    					,[x + width/2, y + height/4]
    					,[x, y + height/2]
    					,[x, y - height/2]
    					,[x + width/2, y - height/4]
    					,[x - width/2 -2, y + height/4]    
    										
    					,[x - width/2, y + height/4 +2]
    					,[x + width/2 +4, y - height/4]
    					,[x -2, y - height/2 -4]
    					,[x -2, y + height/2 +4]
    					,[x + width/2 +4, y + height/4]
    					,[x - width/2, y - height/4 -2]
    					]);
    	
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

class OrbitWatchFaceView extends Ui.WatchFace {

	var drawable;
    function initialize() {
        WatchFace.initialize();
    }

    //! Load your resources here
    function onLayout(dc) {
        drawable = new OrbitClock();
    }

    //! Update the view
    function onUpdate(dc) {

		dc.setColor(background, background);
		dc.clear();
		
		if ( drawable != null) {
    		drawable.draw(dc);
    	}
		
	    
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	if ( drawable != null) {
    		drawable.sleepMode = false;
    		Ui.animate(drawable, :width, Ui.ANIM_TYPE_EASE_IN_OUT , 0, MAXWIDTH, animationTime, null);
    	}
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	if ( drawable != null) {
    		drawable.sleepMode = true;
    		drawable.width = MAXWIDTH;
    		Ui.requestUpdate();
    	}
    }

}

	function getSettings(){
	
		background = getProperty( "Background" );
    	background = background != null ? background : Gfx.COLOR_BLACK;
    	
    	colorDate = getProperty( "ColorDate" );
        colorDate = colorDate != null ? colorDate : Gfx.COLOR_YELLOW;
        
        colorHour = getProperty( "ColorHour" );
        colorHour = colorHour != null ? colorHour : Gfx.COLOR_BLUE;
        
        colorMin = getProperty( "ColorMin" );
        colorMin = colorMin != null ? colorMin : Gfx.COLOR_GREEN;        
        
        colorSec = getProperty( "ColorSec" );
        colorSec = colorSec != null ? colorSec : Gfx.COLOR_RED;
        
        colorDigit = getProperty( "ColorDigit" );
        colorDigit = colorDigit != null ? colorDigit : Gfx.COLOR_BLACK;
    	
    	animationTime = getProperty( "AnimationTime" );
        animationTime = animationTime != null ? animationTime : 2;
        
        arcsOn = getProperty( "ArcsOn" );
        arcsOn = arcsOn != null ? arcsOn : false;
        
        arcsRoundedOn = getProperty( "ArcsRoundedOn" );
        arcsRoundedOn = arcsRoundedOn != null ? arcsRoundedOn : true;
        
        simpleModeOnSleep = getProperty( "SimpleModeOnSleep" );
        simpleModeOnSleep = simpleModeOnSleep != null ? simpleModeOnSleep : true;
        
        handsOn = getProperty( "HandsOn" );
        handsOn = handsOn != null ? handsOn : false;
        
        orbitsOn = getProperty( "OrbitsOn" );
        orbitsOn = orbitsOn != null ? orbitsOn : true;

        digitsOn = getProperty( "DigitsOn" );
        digitsOn = digitsOn != null ? digitsOn : true;
        
        statusOn = getProperty( "StatusOn" );
        statusOn = statusOn != null ? statusOn : true;
        
        fontSize = getProperty( "FontSize" );
        fontSize = fontSize != null ? fontSize : -1;
        
        widthSize = getProperty( "WidthSize" );
        widthSize = 25 - (widthSize != null ? widthSize : 15);
	}

class OrbitWatchFaceApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
		getSettings();
    }

    //! onStart() is called on application start up
    function onStart() {
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    }
    
     function onSettingsChanged() {
    
    	getSettings();
    	
        Ui.requestUpdate();
    }

    //! Return the initial view of your application here
    function getInitialView() {
    
        return [ new OrbitWatchFaceView() ];
    }

}
