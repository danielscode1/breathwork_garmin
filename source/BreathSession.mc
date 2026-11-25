import Toybox.Lang;

enum {
    PHASE_INHALE,
    PHASE_HOLD_FULL,
    PHASE_EXHALE,
    PHASE_HOLD_EMPTY
}

//! The breathing clock. It knows nothing about the screen or the vibration
//! motor: it is fed elapsed milliseconds and reports when a phase boundary is
//! crossed. Time is accumulated from real clock deltas, so the pattern does not
//! drift even if a timer tick is late.
class BreathSession {

    hidden var mKinds;        // phase kinds for one full cycle
    hidden var mDurations;    // matching durations in ms
    hidden var mIndex;        // current phase
    hidden var mPhaseMs;      // elapsed inside the current phase
    hidden var mTotalMs;      // elapsed in the session
    hidden var mLimitMs;      // 0 = open ended
    hidden var mCycles;
    hidden var mRunning;
    hidden var mDone;

    function initialize() {
        rebuild();
    }

    //! Re-read the settings and lay out one cycle. Phases set to 0 s are dropped,
    //! so "4-0-6-0" box breathing simply behaves like 4:6 even breathing.
    function rebuild() {
        var kinds = [];
        var durations = [];
        var boxed = (Config.mode() == Config.MODE_BOX);

        append(kinds, durations, PHASE_INHALE, Config.inhale());
        if (boxed) {
            append(kinds, durations, PHASE_HOLD_FULL, Config.holdFull());
        }
        append(kinds, durations, PHASE_EXHALE, Config.exhale());
        if (boxed) {
            append(kinds, durations, PHASE_HOLD_EMPTY, Config.holdEmpty());
        }

        if (kinds.size() < 2) {
            kinds = [PHASE_INHALE, PHASE_EXHALE];
            durations = [4000, 4000];
        }

        mKinds = kinds;
        mDurations = durations;
        mLimitMs = Config.lengthMin() * 60 * 1000;
        reset();
    }

    hidden function append(kinds, durations, kind, seconds) {
        if (seconds > 0) {
            kinds.add(kind);
            durations.add(seconds * 1000);
        }
    }

    hidden function reset() {
        mIndex = 0;
        mPhaseMs = 0;
        mTotalMs = 0;
        mCycles = 0;
        mRunning = false;
        mDone = false;
    }

    function start() {
        reset();
        mRunning = true;
    }

    function setRunning(running) {
        if (!mDone) {
            mRunning = running;
        }
    }

    function stop() {
        mRunning = false;
    }

    function isRunning() {
        return mRunning;
    }

    function isDone() {
        return mDone;
    }

    //! Feed it the milliseconds since the last call.
    //! Returns true when a new phase has just begun (or the session just ended),
    //! which is the moment the watch should buzz.
    function advance(elapsedMs) {
        if (!mRunning || mDone) {
            return false;
        }

        mPhaseMs += elapsedMs;
        mTotalMs += elapsedMs;

        var duration = mDurations[mIndex];
        if (mPhaseMs < duration) {
            return false;
        }

        mPhaseMs -= duration;
        mIndex++;
        if (mIndex >= mKinds.size()) {
            mIndex = 0;
            mCycles++;
            // Finish on a whole cycle so the session always ends on an exhale.
            if (mLimitMs > 0 && mTotalMs >= mLimitMs) {
                mDone = true;
                mRunning = false;
            }
        }
        return true;
    }

    function phaseKind() {
        return mKinds[mIndex];
    }

    function phaseCount() {
        return mKinds.size();
    }

    function phaseIndex() {
        return mIndex;
    }

    function cycles() {
        return mCycles;
    }

    //! 0.0 at the start of the phase, 1.0 at its end.
    function phaseProgress() {
        var duration = mDurations[mIndex];
        if (duration <= 0) {
            return 0.0;
        }
        var p = mPhaseMs.toFloat() / duration;
        if (p < 0.0) {
            return 0.0;
        }
        if (p > 1.0) {
            return 1.0;
        }
        return p;
    }

    //! How full the lungs are, 0.0 - 1.0. Drives the bar on screen.
    function level() {
        var kind = mKinds[mIndex];
        if (kind == PHASE_INHALE) {
            return phaseProgress();
        }
        if (kind == PHASE_HOLD_FULL) {
            return 1.0;
        }
        if (kind == PHASE_EXHALE) {
            return 1.0 - phaseProgress();
        }
        return 0.0;
    }

    //! Whole seconds left in the current phase, counting down to 1.
    function remainingSec() {
        var left = mDurations[mIndex] - mPhaseMs;
        if (left < 0) {
            left = 0;
        }
        return (left + 999) / 1000;
    }

    //! Seconds left in the session, or null when it is open ended.
    function sessionRemainingSec() {
        if (mLimitMs <= 0) {
            return null;
        }
        var left = mLimitMs - mTotalMs;
        if (left < 0) {
            left = 0;
        }
        return left / 1000;
    }
}
