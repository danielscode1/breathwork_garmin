import Toybox.Lang;
import Toybox.WatchUi;

//! Small text helpers shared by the home screen and the menus.
module Fmt {

    function pattern() {
        if (Config.mode() == Config.MODE_EVEN) {
            return Config.inhale().toString() + ":" + Config.exhale().toString();
        }
        return Config.inhale().toString() + "-" + Config.holdFull().toString() + "-"
             + Config.exhale().toString() + "-" + Config.holdEmpty().toString();
    }

    function modeName() {
        if (Config.mode() == Config.MODE_EVEN) {
            return WatchUi.loadResource(Rez.Strings.ModeEven);
        }
        return WatchUi.loadResource(Rez.Strings.ModeBox);
    }

    function seconds(value) {
        return value.toString() + " " + WatchUi.loadResource(Rez.Strings.UnitSec);
    }

    function minutes(value) {
        if (value <= 0) {
            return WatchUi.loadResource(Rez.Strings.Unlimited);
        }
        return value.toString() + " " + WatchUi.loadResource(Rez.Strings.UnitMin);
    }

    function percent(value) {
        return value.toString() + "%";
    }

    //! Seconds as m:ss.
    function clock(totalSeconds) {
        var minutesPart = totalSeconds / 60;
        var secondsPart = totalSeconds % 60;
        return minutesPart.toString() + ":" + secondsPart.format("%02d");
    }

    function summary() {
        return modeName() + "  " + minutes(Config.lengthMin());
    }
}
