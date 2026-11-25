# Breathe — guided breathwork for Garmin Instinct 2

A Connect IQ device app that paces your breathing with the vibration motor.
Every phase boundary gets its own buzz, so you can run a session with the watch
on your wrist and your eyes closed.

- **Box breathing** — inhale / hold / exhale / hold, each leg set independently
  (so "4-7-8" works just as well as a square 4-4-4-4).
- **Even breathing** — inhale / exhale with no holds, e.g. 5:5.
- Every phase length is configurable from 1–30 s, on the watch or from the phone.
- Session length 1–60 minutes, or open ended until you stop it.

## The buzz patterns

| Event | Vibration |
|---|---|
| Inhale starts | one long pulse (450 ms) |
| Exhale starts | two short pulses |
| Hold starts | one soft tap (switch off with *Buzz on hold*) |
| Session finishes | three pulses, the last one long |

Strength is adjustable (10–100 %). The timing is driven by the real clock, not
by counting timer ticks, so the pattern does not drift over a long session; the
buzz lands within 100 ms of the phase boundary.

If the watch's own vibration setting is off, nothing can buzz — the app detects
this and shows `BUZZ OFF` on the session screen instead of the session clock.

## Controls

**Start screen** — shows the pattern you are about to run.

- `GPS` — start a session straight away
- `UP` / `DOWN` — open the setup menu (it also has *Start* at the top)
- `BACK` — leave the app

**During a session**

- `GPS` — pause / resume. On the DONE screen it starts a fresh session.
- `BACK` — end the session, back to the start screen

**Session screen** — a bar on the left edge fills as you breathe in and empties
as you breathe out, with the seconds left in the current phase in the middle and
the phase name below it. The top right of the screen is deliberately left empty:
on the Instinct that area sits under the round sub-window.

## Settings

Editable on the watch (setup menu) and from the phone
(Garmin Connect → your device → Connect IQ Apps → Breathe → Settings). Both
write the same stored properties, so they always agree.

| Setting | Default | Notes |
|---|---|---|
| Pattern | Box | Box (with holds) or Even (no holds) |
| Inhale | 4 s | 1–30 s |
| Hold (full) | 4 s | 0–30 s, box only; 0 drops the phase |
| Exhale | 4 s | 1–30 s |
| Hold (empty) | 4 s | 0–30 s, box only |
| Session | 5 min | 0 = run until you stop it; ends on a whole cycle |
| Buzz on hold | on | off = only inhale/exhale buzz |
| Buzz strength | 75 % | |
| Beep too | off | adds the watch tone to inhale/exhale |

## Building

You need the Connect IQ SDK (4.0.10 or newer — that is the release that added
the Instinct 2) and the **Instinct 2** device added in the SDK Manager.

The easy path is VS Code with Garmin's *Monkey C* extension: open this folder,
then `Ctrl/Cmd+Shift+P` → **Monkey C: Build for Device**.

From the command line:

```sh
# one-off: developer key
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER \
    -in developer_key.pem -out developer_key.der -nocrypt

# build
monkeyc -f monkey.jungle -o Breathe.prg -y developer_key.der -d instinct2

# try it in the simulator
connectiq &
monkeydo Breathe.prg instinct2
```

## Installing on the watch

1. Connect the Instinct 2 by USB and wait for it to mount.
2. Copy `Breathe.prg` into `GARMIN/APPS/` on the watch.
3. Eject and unplug. The app appears in the activity/app list (`GPS` from the
   watch face), listed as **Breathe**.

If you later want it through the Connect IQ store instead, the manifest already
targets `instinct2`, `instinct2s` and `instinct2x`.

## Layout of the code

```
manifest.xml              app id, targets, min API level
monkey.jungle             build config
resources/
  strings/strings.xml     all UI text (one place to translate)
  settings/properties.xml persisted values + defaults
  settings/settings.xml   the phone-side settings screen
  drawables/              launcher icon
source/
  BreatheApp.mc           entry point
  Config.mc               typed, clamped access to the stored properties
  BreathSession.mc        the breathing clock — no UI, no vibration
  BreathView.mc           session screen, timer, vibration cues
  HomeView.mc             start screen
  SettingsMenu.mc         on-watch menus
  Fmt.mc                  shared text formatting
```

`BreathSession` is deliberately free of UI and hardware calls: it is fed elapsed
milliseconds and reports when a phase boundary has been crossed, which is the
single place the vibration is triggered from.

## Notes for tweaking

- Vibration patterns live in `cuePhase()` / `cueFinish()` in `BreathView.mc`.
- `BREATH_TICK_MS` (top of `BreathView.mc`) trades buzz latency against battery;
  50 ms tightens it, 200 ms is gentler on the battery.
- Device apps on the Instinct 2 get only 96 KB, so this one keeps resources and
  classes lean — worth remembering before adding bitmaps or layouts.
