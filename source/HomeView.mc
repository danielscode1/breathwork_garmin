import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! Start screen: shows the pattern that is about to run, and how to get going.
//! Everything is drawn in the lower part of the screen, because the Instinct's
//! round sub-window sits over the top right of the drawing surface.
class HomeView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        // On the Instinct the sub-window can make the drawing surface wider than
        // the visible round face, so centre on the smaller of the two.
        var side = (width < height) ? width : height;
        var cx = side / 2;
        var cy = side / 2;
        var centre = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(cx, cy, Graphics.FONT_MEDIUM, Fmt.pattern(), centre);
        dc.drawText(cx, cy + side * 16 / 100, Graphics.FONT_TINY, Fmt.summary(), centre);

        dc.drawText(cx, cy + side * 30 / 100, Graphics.FONT_TINY,
                    WatchUi.loadResource(Rez.Strings.HintStart), centre);
        dc.drawText(cx, cy + side * 42 / 100, Graphics.FONT_TINY,
                    WatchUi.loadResource(Rez.Strings.HintSetup), centre);
    }
}

class HomeDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    //! GPS button: straight into a session.
    function onSelect() {
        var view = new BreathView();
        WatchUi.pushView(view, new BreathDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onNextPage() {
        return openSettings();
    }

    function onPreviousPage() {
        return openSettings();
    }

    function onMenu() {
        return openSettings();
    }

    hidden function openSettings() {
        var menu = new SettingsMenu();
        WatchUi.pushView(menu, new SettingsDelegate(menu), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
