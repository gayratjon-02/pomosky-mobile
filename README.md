# pomosky-mobile

Flutter app for [Pomosky](https://pomosky-c157de.eastasia.cloudapp.azure.com): shared pomodoro
rooms under a live sky. It talks to the Go backend over HTTP and a WebSocket; the server owns the timer.

## Run

```bash
flutter pub get
flutter run                                   # simulator or a connected phone
flutter run --dart-define=BASE_URL=http://localhost:8080
```

## Check

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Layout

```
lib/core       pure Dart helpers (timer maths, clock offset)
lib/domain     room and timer state, no I/O
lib/data       protocol models, WebSocket and HTTP clients
lib/features   screens and widgets, one folder per feature
lib/ui         theme and shared widgets
```
