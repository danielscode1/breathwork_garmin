import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

//! How often the clock is sampled. The pattern itself is driven by real elapsed
//! time, so this only decides how promptly the buzz lands on a phase boundary
//! (worst case one tick late) and how smoothly the bar moves.
const BREATH_TICK_MS = 100;

class BreathView extends WatchUi.View {

    hidden var mSession;
    hidden var mTimer;
    hidden var mLastMs;
    hidden var mStarted;
    hidden var mVibeOff;

    hidden var mTxtInhale;
    hidden var mTxtHold;
    hidden var mTxtExhale;
    hidden var mTxtPaused;
    hidden var mTxtDone;
    hidden var mTxtNoVibe;

    function initialize() {
        View.initialize();
        mSession = new BreathSession();
        mTimer = null;
        mLastMs = 0;
        mStarted = false;
        mVibeOff = false;
        mTxtInhale = WatchUi.loadResource(Rez.Strings.PhaseInhale);
        mTxtHold = WatchUi.loadResource(Rez.Strings.PhaseHold);
        mTxtExhale = WatchUi.loadResource(Rez.Strings.PhaseExhale);
        mTxtPaused = WatchUi.loadResource(Rez.Strings.StatePaused);
        mTxtDone = WatchUi.loadResource(Rez.Strings.StateDone);
        mTxtNoVibe = WatchUi.loadResource(Rez.Strings.WarnNoVibe);
    }

    function onShow() {
        if (!mStarted) {
            mStarted = true;
            mVibeOff = !System.getDeviceSettings().vibrateOn;
            mSession.rebuild();
            mSession.start();
            cuePhase(mSession.phaseKind());
        }
        mLastMs = System.getTimer();
        startTimer();
    }

    function onHide() {
        stopTimer();
    }

    // ---------------------------------------------------------------- timing

    hidden function startTimer() {
        if (mTimer == null) {
            mTimer = new Timer.Timer();
        }
        mTimer.start(method(:onTick), BREATH_TICK_MS, true);
    }

    hidden function stopTimer() {
        if (mTimer != null) {
            mTimer.stop();
        }
    }

    function onTick() {
        var now = System.getTimer();
        var elapsed = now - mLastMs;
        mLastMs = now;
        // System.getTimer() wraps eventually, and a tick can be delayed.
        if (elapsed < 0 || elapsed > 5000) {
            elapsed = BREATH_TICK_MS;
        }

        if (!mSession.isRunning()) {
            return;
        }

        if (mSession.advance(elapsed)) {
            if (mSession.isDone()) {
                stopTimer();
                cueFinish();
            } else {
                cuePhase(mSession.phaseKind());
            }
        }
        WatchUi.requestUpdate();
    }

    // ------------------------------------------------------------ user input

    function togglePause() {
        if (mSession.isDone()) {
            // A finished session restarts on the next press.
            mSession.rebuild();
            mSession.start();
            mLastMs = System.getTimer();
            startTimer();
            cuePhase(mSession.phaseKind());
        } else {
            mSession.setRunning(!mSession.isRunning());
            mLastMs = System.getTimer();
        }
        WatchUi.requestUpdate();
    }

    function stopSession() {
        mSession.stop();
        stopTimer();
    }

    // ----------------------------------------------------------------- cues

    //! The point of the whole app: a distinct buzz the moment a phase starts.
    //! Inhale is one long pulse, exhale two short ones, a hold a single soft tap.
    hidden function cuePhase(kind) {
        var power = Config.strength();

        if (kind == PHASE_INHALE) {
            buzz([new Attention.VibeProfile(power, 450)]);
            beep();
        } else if (kind == PHASE_EXHALE) {
            buzz([new Attention.VibeProfile(power, 160),
                  new Attention.VibeProfile(0, 110),
                  new Attention.VibeProfile(power, 160)]);
            beep();
        } else if (Config.vibeHold()) {
            var soft = power / 2;
            if (soft < 10) {
                soft = 10;
            }
            buzz([new Attention.VibeProfile(soft, 110)]);
        }
    }

    hidden function cueFinish() {
        var power = Config.strength();
        buzz([new Attention.VibeProfile(power, 250),
              new Attention.VibeProfile(0, 130),
              new Attention.VibeProfile(power, 250),
              new Attention.VibeProfile(0, 130),
              new Attention.VibeProfile(power, 550)]);
        beep();
        WatchUi.requestUpdate();
    }

    hidden function buzz(profile) {
        if (!(Attention has :vibrate)) {
            return;
        }
        // The watch's own vibration switch wins; warn about it on screen instead.
        if (!System.getDeviceSettings().vibrateOn) {
            return;
        }
        Attention.vibrate(profile);
    }

    hidden function beep() {
        if (!Config.tones()) {
            return;
        }
        if (!(Attention has :playTone)) {
            return;
        }
        if (!System.getDeviceSettings().tonesOn) {
            return;
        }
        Attention.playTone(Attention.TONE_LOUD_BEEP);
    }

    // --------------------------------------------------------------- drawing

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var side = (width < height) ? width : height;
        var cx = side / 2;
        var cy = side / 2;
        // Text column sits slightly left of centre: it balances the level bar on
        // the left and keeps wide numbers clear of the sub-window top right.
        var tx = cx - side * 4 / 100;
        var centre = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        drawLevelBar(dc, side, cy);

        var done = mSession.isDone();
        var big = done ? mSession.cycles().toString() : mSession.remainingSec().toString();
        dc.drawText(tx, cy - side * 3 / 100, Graphics.FONT_NUMBER_MEDIUM, big, centre);

        dc.drawText(tx, cy + side * 22 / 100, Graphics.FONT_SMALL, stateLabel(), centre);

        var footer = footerText();
        if (footer != null) {
            dc.drawText(tx, cy + side * 38 / 100, Graphics.FONT_TINY, footer, centre);
        }
    }

    //! A column on the left edge that fills as you breathe in and empties as you
    //! breathe out, so the phase is readable from the corner of your eye.
    hidden function drawLevelBar(dc, side, cy) {
        var barX = side * 4 / 100;
        var barW = side * 6 / 100;
        var barH = side * 58 / 100;
        var barY = cy - barH / 2;

        dc.setPenWidth(1);
        dc.drawRectangle(barX, barY, barW, barH);

        var filled = (barH * mSession.level()).toNumber();
        if (filled > 0) {
            if (filled > barH) {
                filled = barH;
            }
            dc.fillRectangle(barX, barY + barH - filled, barW, filled);
        }
    }

    hidden function stateLabel() {
        if (mSession.isDone()) {
            return mTxtDone;
        }
        if (!mSession.isRunning()) {
            return mTxtPaused;
        }
        var kind = mSession.phaseKind();
        if (kind == PHASE_INHALE) {
            return mTxtInhale;
        }
        if (kind == PHASE_EXHALE) {
            return mTxtExhale;
        }
        return mTxtHold;
    }

    hidden function footerText() {
        if (mVibeOff) {
            return mTxtNoVibe;
        }
        var left = mSession.sessionRemainingSec();
        if (left == null) {
            return null;
        }
        return Fmt.clock(left);
    }
}

class BreathDelegate extends WatchUi.BehaviorDelegate {

    hidden var mView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    //! GPS button: pause / resume, or restart a finished session.
    function onSelect() {
        mView.togglePause();
        return true;
    }

    //! BACK button: end the session and return to the start screen.
    function onBack() {
        mView.stopSession();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onMenu() {
        return true;
    }

    function onNextPage() {
        return true;
    }

    function onPreviousPage() {
        return true;
    }
}
