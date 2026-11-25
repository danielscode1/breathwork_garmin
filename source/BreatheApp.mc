import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BreatheApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [new HomeView(), new HomeDelegate()];
    }

    //! Fired when the settings are changed from the phone.
    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}
