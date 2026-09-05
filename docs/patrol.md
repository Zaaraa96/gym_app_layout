# Patrol device tests

Host widget tests stay on `flutter test --concurrency=1`. These files run on an
Android emulator (or a phone) with Patrol.

## What this repo expects

- JDK 17
- `ANDROID_HOME` / `ANDROID_SDK_ROOT` pointing at an Android SDK
- AVD named `patrol_pixel` (created by the Cloud image)
- `patrol_cli` on `PATH` (`dart pub global activate patrol_cli`)

Cloud Agent installs put those in `/opt/android-sdk` and start the emulator from
`tool/cloud-start-emulator.sh`. `patrol_cli` is pinned to 4.7.0 to match
`patrol` 4.9.x.

## Run

```bash
# Smoke: Patrol + AVD only (no gym screens)
patrol test -t integration_test/flows/smoke_patrol_ready.dart

# Later flow files (same language as the device plan)
# Flow 1 + 2a
# patrol test -t integration_test/flows/flow_1_2a_welcome_and_beginner.dart
```

Existing `integration_test/*.dart` wrappers are host/device runners for widget
tests. Do not pass that folder to `patrol test`. Patrol only looks in
`integration_test/flows/` (`test_directory` in `pubspec.yaml`).

Never `pumpAndSettle` on Welcome: the Lottie animation does not stop.

## Device data

Import tests need JSON on the emulator:

```bash
adb push assets/json/plan.json /sdcard/Download/plan.json
```

Force-stop (process death):

```bash
adb shell am force-stop com.zahra.gym_app
```
