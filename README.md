# pomosky-mobile

Flutter app for [Pomosky](https://pomosky-c157de.eastasia.cloudapp.azure.com): shared pomodoro
rooms under a live sky that follows the real weather of the host's city. It talks to the Go
backend over HTTP and one WebSocket per room; **the server owns the timer**, the app only shows it.

## What it does

- Join a room by link or 8-letter code, or create one (you become its host).
- A countdown ring, the live sky (sun, moon with its phase, stars, clouds, rain, snow, fog,
  lightning) and the weather with its age ("updated 4 min ago").
- Host: choose a city, start a focus or break phase, pause, resume, reset.
- Everyone: reactions, the people in the room, a name of your own, share the room link.
- End of a phase: a six-second chime and vibration; a notification when the app is in the
  background; the countdown stays in the **Dynamic Island** and on the Lock Screen (iOS).
- The screen stays on while a phase runs; the connection is re-established after the app
  returns from the background; a room that vanished is reported as not found.

Login is optional (there is none in the app). The phone never asks for a location: only the host
chooses a city, and the server rounds it to about 1 km.

## Run

```bash
flutter pub get
flutter run                                              # the live site
flutter run --dart-define=BASE_URL=http://localhost:8080 # a local backend
flutter run --dart-define=INITIAL_ROUTE=/r/<id>          # open a room at launch (development)
```

In a debug build `/sky-lab` is a playground for the sky (presets for noon, dusk, night, rain,
storm, snow, fog); `/sky-lab?auto=1` cycles through them.

`pomosky:///r/<id>` opens a room from outside the app (iOS and Android).

## Check

```bash
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

End-to-end tests run against a real backend (start one, create a room):

```bash
flutter test integration_test/host_flow_test.dart   -d <device> --dart-define=BASE_URL=http://localhost:8098
flutter test integration_test/room_flow_test.dart   -d <device> --dart-define=BASE_URL=... --dart-define=ROOM=<id>
flutter test integration_test/signal_flow_test.dart -d <device> --dart-define=BASE_URL=... --dart-define=ROOM=<id>
```

`room_flow_test` needs a room whose host started a timer; `signal_flow_test` a room whose host
started a 40-second phase just before.

## Layout

```
lib/core       pure Dart: clock offset, reconnect backoff, sun and moon, chime synthesis
lib/domain     pure Dart: timer model and maths, host actions, phase end, nickname, room ids
lib/data       protocol models, WebSocket and HTTP clients, storage, platform wrappers
lib/features   screens and state, one folder per feature (home, room, lab)
lib/ui         theme, timer ring, the sky (palette, layers, painter)
ios/           the Live Activity widget extension (Swift)
```

`core` and `domain` import nothing from the layers above and no Flutter code. Platform things
(sound, vibration, notifications, wake lock, Live Activity, share) sit behind small interfaces
with silent defaults, so tests need no devices; `main.dart` installs the real ones.

## Status

Verified on the iOS simulator against a local backend. Not verified: Android builds (the
Android toolchain on the development machine is incomplete), a real device, and the expanded
Dynamic Island layout. Android notifications use inexact scheduling (`TODO(verify)` in
`lib/data/phase_notifier.dart`).
