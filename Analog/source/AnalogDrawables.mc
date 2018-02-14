using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;


const MAXWIDTH = 60;

class AnalogHandsClassy extends AnalogHands{

	function initialize(x , y, lenght) {
       
       AnalogHands.initialize(x, y, lenght);     
    }
	function drawHands (dc ,clockTime){
	
	    var minuteHandAngle;
        var hourHandAngle;
        var secondHandAngle;
        
        
        // Draw the hour hand. Convert it to minutes and compute the angle.
        // :angleOffset drawable variable used for animation 
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);       
        hourHandAngle = ( (( angleOffset.toLong() + hourHandAngle / 12) % 60 ) / 60.0 ) * Math.PI * 2;        
        dc.setColor(handColor ,Gfx.COLOR_TRANSPARENT);     
        dc.fillPolygon(generateHandCoordinates([centerX, centerY], hourHandAngle, maxLenght*0.7, 0, 10 ));
        dc.fillCircle(centerX + (maxLenght*0.7 * Math.sin(hourHandAngle)), centerY - (maxLenght*0.7 * Math.cos(hourHandAngle)), 5 );
        dc.setColor(Gfx.COLOR_BLACK ,Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(generateHandCoordinates([centerX + maxLenght*0.3* Math.sin(hourHandAngle), centerY - maxLenght*0.3* Math.cos(hourHandAngle) ], hourHandAngle, maxLenght*0.4, 0, 6 ));
        dc.fillCircle(centerX + maxLenght*0.7* Math.sin(hourHandAngle), centerY - maxLenght*0.7* Math.cos(hourHandAngle), 3 );
   
        
        // Draw the minute hand.
        minuteHandAngle = ( (( angleOffset.toLong() + clockTime.min ) % 60 ) / 60.0 ) * Math.PI * 2;       
        dc.setColor(handColor ,Gfx.COLOR_TRANSPARENT); 
        dc.fillPolygon(generateHandCoordinates([centerX , centerY], minuteHandAngle, maxLenght*0.9, 0, 8));    
        dc.fillCircle(centerX + (maxLenght*0.9 * Math.sin(minuteHandAngle)), centerY - (maxLenght*0.9 * Math.cos(minuteHandAngle)), 4 );    
        dc.setColor(Gfx.COLOR_BLACK ,Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(generateHandCoordinates([centerX + maxLenght*0.3* Math.sin(minuteHandAngle), centerY - maxLenght*0.3* Math.cos(minuteHandAngle) ], minuteHandAngle, maxLenght*0.6, 0, 4 ));
        dc.fillCircle(centerX + maxLenght*0.9* Math.sin(minuteHandAngle), centerY - maxLenght*0.9* Math.cos(minuteHandAngle), 2 );
   
        
        dc.setColor(Gfx.COLOR_DK_RED ,Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 5);
        if ( ! sleepMode ){
        	 var points = getSecondHandPoints(clockTime);
	         drawSecondHand(dc, points);
        }
	}
}

class AnalogHands extends Ui.Drawable {
		
	var angleOffset;
	var sleepMode;
	var handColor;
	
	hidden var centerX;
	hidden var centerY;
	hidden var maxLenght;

    function initialize(x , y, lenght) {
       Drawable.initialize( { :identifier => "AnalogHands" } );

       angleOffset = MAXWIDTH;
       sleepMode = true;
       handColor = Gfx.COLOR_WHITE;
       
       centerX = x;
       centerY = y;
       maxLenght = lenght;
       
    }
       
    
    function draw(dc){
       
        var clockTime = Sys.getClockTime();
        
        // Draw hands
        drawHands(dc, clockTime); 
    	
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
    
    function generateHandCoordinates1(centerPoint, angle, handLength, tailLength, width, tailwidthLength) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width*0.75), tailLength], [-(width*0.75), tailwidthLength ] , [-(width /2), tailwidthLength ], [-(width / 2), -handLength], [ 1 / 2, - handLength - width], [width / 2, -handLength] ,[width / 2, tailwidthLength]  , [width*0.75 , tailwidthLength] , [width*0.75 , tailLength]];
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
    
    function drawHands(dc, clockTime)
    {
    
        var minuteHandAngle;
        var hourHandAngle;
        var secondHandAngle;
        
        dc.setColor(handColor ,Gfx.COLOR_TRANSPARENT);
        // Draw the hour hand. Convert it to minutes and compute the angle.
        // :angleOffset drawable variable used for animation 
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);       
        hourHandAngle = ( (( angleOffset.toLong() + hourHandAngle / 12) % 60 ) / 60.0 ) * Math.PI * 2;        
        dc.fillPolygon(generateHandCoordinates([centerX , centerY], hourHandAngle, maxLenght*0.7, maxLenght*0.1, maxLenght*0.05));
        
        // Draw the minute hand.
        minuteHandAngle = ( (( angleOffset.toLong() + clockTime.min ) % 60 ) / 60.0 ) * Math.PI * 2;       
        dc.fillPolygon(generateHandCoordinates([centerX , centerY], minuteHandAngle, maxLenght*0.9, maxLenght*0.1, maxLenght*0.03));
        
        dc.setColor(Gfx.COLOR_DK_RED ,Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, 6);
        if ( ! sleepMode ){
        	 var points = getSecondHandPoints(clockTime);
	         drawSecondHand(dc, points);
        }

         
    }
    
    function getSecondHandPoints(clockTime)
    {
        var secondHandPoints;
        var secondHandAngle;
 
        secondHandAngle = ( (( angleOffset.toLong() + clockTime.sec ) % 60 ) / 60.0 ) * Math.PI * 2; 
        secondHandPoints = generateHandCoordinates([centerX , centerY], secondHandAngle, maxLenght-2, maxLenght*0.2, maxLenght*0.02);
 
        return secondHandPoints;
    }
    
    function drawSecondHand(dc, secondHandPoints)
    {
    	dc.setColor(Gfx.COLOR_DK_RED ,Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(secondHandPoints);

    }
        
       
}

