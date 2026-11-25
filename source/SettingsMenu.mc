import Toybox.Lang;
import Toybox.WatchUi;

//! The on-watch settings menu. Every row writes straight to the stored
//! properties, so the phone settings and this menu always agree.
class SettingsMenu extends WatchUi.Menu2 {

    hidden var mRows;

    function initialize() {
        Menu2.initialize({:title => WatchUi.loadResource(Rez.Strings.AppName)});
        mRows = {};

        addRow(:start, Rez.Strings.MenuStart);
        addRow(:mode, Rez.Strings.MenuMode);
        addRow(:inhale, Rez.Strings.MenuInhale);
        addRow(:holdFull, Rez.Strings.MenuHoldFull);
        addRow(:exhale, Rez.Strings.MenuExhale);
        addRow(:holdEmpty, Rez.Strings.MenuHoldEmpty);
        addRow(:lengthMin, Rez.Strings.MenuLength);
        addToggle(:vibeHold, Rez.Strings.MenuVibeHold, Config.vibeHold());
        addRow(:strength, Rez.Strings.MenuStrength);
        addToggle(:tones, Rez.Strings.MenuTones, Config.tones());

        refresh();
    }

    hidden function addRow(id, labelResource) {
        var item = new WatchUi.MenuItem(WatchUi.loadResource(labelResource), "", id, {});
        mRows.put(id, item);
        addItem(item);
    }

    hidden function addToggle(id, labelResource, enabled) {
        var item = new WatchUi.ToggleMenuItem(
            WatchUi.loadResource(labelResource), "", id, enabled, {});
        mRows.put(id, item);
        addItem(item);
    }

    //! Re-reads every value and updates the sub-labels in place.
    function refresh() {
        setSub(:start, Fmt.pattern());
        setSub(:mode, Fmt.modeName());
        setSub(:inhale, Fmt.seconds(Config.inhale()));
        setSub(:holdFull, Fmt.seconds(Config.holdFull()));
        setSub(:exhale, Fmt.seconds(Config.exhale()));
        setSub(:holdEmpty, Fmt.seconds(Config.holdEmpty()));
        setSub(:lengthMin, Fmt.minutes(Config.lengthMin()));
        setSub(:strength, Fmt.percent(Config.strength()));
    }

    hidden function setSub(id, text) {
        var item = mRows.get(id);
        if (item != null && item has :setSubLabel) {
            item.setSubLabel(text);
        }
    }
}

class SettingsDelegate extends WatchUi.Menu2InputDelegate {

    hidden var mMenu;

    function initialize(menu) {
        Menu2InputDelegate.initialize();
        mMenu = menu;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :start) {
            var view = new BreathView();
            WatchUi.pushView(view, new BreathDelegate(view), WatchUi.SLIDE_IMMEDIATE);
            return;
        }

        if (item instanceof WatchUi.ToggleMenuItem) {
            // Menu2 has already flipped the switch by the time we get here.
            if (id == :vibeHold) {
                Config.set(Config.K_VIBE_HOLD, item.isEnabled());
            } else if (id == :tones) {
                Config.set(Config.K_TONES, item.isEnabled());
            }
            return;
        }

        if (id == :mode) {
            var modeLabels = [WatchUi.loadResource(Rez.Strings.ModeBox),
                              WatchUi.loadResource(Rez.Strings.ModeEven)];
            push(Rez.Strings.MenuMode, Config.K_MODE,
                 [Config.MODE_BOX, Config.MODE_EVEN], modeLabels, Config.mode());

        } else if (id == :inhale) {
            pushSeconds(Rez.Strings.MenuInhale, Config.K_INHALE, 1, Config.inhale());

        } else if (id == :holdFull) {
            pushSeconds(Rez.Strings.MenuHoldFull, Config.K_HOLD_FULL, 0, Config.holdFull());

        } else if (id == :exhale) {
            pushSeconds(Rez.Strings.MenuExhale, Config.K_EXHALE, 1, Config.exhale());

        } else if (id == :holdEmpty) {
            pushSeconds(Rez.Strings.MenuHoldEmpty, Config.K_HOLD_EMPTY, 0, Config.holdEmpty());

        } else if (id == :lengthMin) {
            var lenValues = [0, 1, 2, 3, 5, 8, 10, 15, 20, 30, 45, 60];
            var lenLabels = [];
            for (var i = 0; i < lenValues.size(); i++) {
                lenLabels.add(Fmt.minutes(lenValues[i]));
            }
            push(Rez.Strings.MenuLength, Config.K_LENGTH, lenValues, lenLabels,
                 Config.lengthMin());

        } else if (id == :strength) {
            var powerValues = [];
            var powerLabels = [];
            for (var p = 10; p <= 100; p += 10) {
                powerValues.add(p);
                powerLabels.add(Fmt.percent(p));
            }
            push(Rez.Strings.MenuStrength, Config.K_STRENGTH, powerValues, powerLabels,
                 Config.strength());
        }
    }

    hidden function pushSeconds(titleResource, key, lowest, current) {
        var values = [];
        var labels = [];
        for (var v = lowest; v <= 20; v++) {
            values.add(v);
            labels.add(Fmt.seconds(v));
        }
        values.add(25);
        labels.add(Fmt.seconds(25));
        values.add(Config.MAX_PHASE_SEC);
        labels.add(Fmt.seconds(Config.MAX_PHASE_SEC));
        push(titleResource, key, values, labels, current);
    }

    hidden function push(titleResource, key, values, labels, current) {
        var menu = new ValueMenu(WatchUi.loadResource(titleResource), labels, values, current);
        WatchUi.pushView(menu, new ValueDelegate(key, values, mMenu), WatchUi.SLIDE_IMMEDIATE);
    }
}

//! A list of choices for one setting. The value in use is marked with a star.
class ValueMenu extends WatchUi.Menu2 {

    function initialize(title, labels, values, current) {
        Menu2.initialize({:title => title});
        for (var i = 0; i < values.size(); i++) {
            var mark = (values[i] == current) ? "*" : "";
            addItem(new WatchUi.MenuItem(labels[i], mark, i, {}));
        }
    }
}

class ValueDelegate extends WatchUi.Menu2InputDelegate {

    hidden var mKey;
    hidden var mValues;
    hidden var mParent;

    function initialize(key, values, parent) {
        Menu2InputDelegate.initialize();
        mKey = key;
        mValues = values;
        mParent = parent;
    }

    function onSelect(item) {
        var index = item.getId();
        if (index instanceof Lang.Number && index >= 0 && index < mValues.size()) {
            Config.set(mKey, mValues[index]);
            if (mParent != null) {
                mParent.refresh();
            }
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
