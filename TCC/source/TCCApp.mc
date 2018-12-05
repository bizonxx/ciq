using Toybox.Application;

class TCCApp extends Application.AppBase {


    var temperature = null;
    var digital = false; 
    var View = null;
    
    function initialize() {
        AppBase.initialize();
        digital = getProperty("Digital");
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
		View = new TCCView();
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [View, new TCCDelegate()];
        } else {
            return [ new TCCView() ];
        }

    }

}