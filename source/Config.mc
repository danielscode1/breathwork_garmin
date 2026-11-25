import Toybox.Application;
import Toybox.Lang;

//! Persistent settings, stored as app properties so that they survive a restart
//! and can also be edited from the phone (Garmin Connect > Connect IQ Apps).
module Config {

    // Property keys - these must match resources/settings/properties.xml.
    const K_MODE = "mode";
    const K_INHALE = "inhale";
    const K_HOLD_FULL = "holdFull";
    const K_EXHALE = "exhale";
    const K_HOLD_EMPTY = "holdEmpty";
    const K_LENGTH = "lengthMin";
    const K_VIBE_HOLD = "vibeHold";
    const K_STRENGTH = "strength";
    const K_TONES = "tones";

    const MODE_BOX = 0;
    const MODE_EVEN = 1;

    const MAX_PHASE_SEC = 30;

    function readNumber(key, fallback) {
        var value = null;
        try {
            value = Application.Properties.getValue(key);
        } catch (ex) {
            value = null;
        }
        if (value == null) {
            return fallback;
        }
        if (value has :toNumber) {
            var n = value.toNumber();
            if (n != null) {
                return n;
            }
        }
        return fallback;
    }

    function readBoolean(key, fallback) {
        var value = null;
        try {
            value = Application.Properties.getValue(key);
        } catch (ex) {
            value = null;
        }
        if (value == true) {
            return true;
        }
        if (value == false) {
            return false;
        }
        return fallback;
    }

    function set(key, value) {
        try {
            Application.Properties.setValue(key, value);
        } catch (ex) {
            // Nothing sensible to do here; the session just keeps its old value.
        }
    }

    function clamp(value, low, high) {
        if (value < low) {
            return low;
        }
        if (value > high) {
            return high;
        }
        return value;
    }

    function mode() {
        return clamp(readNumber(K_MODE, MODE_BOX), MODE_BOX, MODE_EVEN);
    }

    function inhale() {
        return clamp(readNumber(K_INHALE, 4), 1, MAX_PHASE_SEC);
    }

    function holdFull() {
        return clamp(readNumber(K_HOLD_FULL, 4), 0, MAX_PHASE_SEC);
    }

    function exhale() {
        return clamp(readNumber(K_EXHALE, 4), 1, MAX_PHASE_SEC);
    }

    function holdEmpty() {
        return clamp(readNumber(K_HOLD_EMPTY, 4), 0, MAX_PHASE_SEC);
    }

    //! 0 means "run until the user stops it".
    function lengthMin() {
        return clamp(readNumber(K_LENGTH, 5), 0, 60);
    }

    function vibeHold() {
        return readBoolean(K_VIBE_HOLD, true);
    }

    //! Vibration duty cycle, 10-100.
    function strength() {
        return clamp(readNumber(K_STRENGTH, 75), 10, 100);
    }

    function tones() {
        return readBoolean(K_TONES, false);
    }
}
