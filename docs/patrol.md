# Patrol device tests

Host widget tests stay on `flutter test --concurrency=1`. These files run on an
Android emulator (or a phone) with Patrol.

## What this repo expects

- JDK 17
- `ANDROID_HOME` / `ANDROID_SDK_ROOT` pointing at an Android SDK (platform 36
  plus Build-Tools 28.0.3 / 34 / 35 / 36)
- AVD named `patrol_pixel` (created by the Cloud image)
- `patrol_cli` on `PATH` (`dart pub global activate patrol_cli 4.7.0`)

Cloud Agent installs put those in `/opt/android-sdk` and start the emulator from
`tool/cloud-start-emulator.sh`. `patrol_cli` is pinned to 4.7.0 to match
`patrol` 4.9.x.

`patrol_cli` 4.7.0 only accepts targets whose names end in `_test.dart`.

If a Cloud Agent shell cannot find `flutter`, `adb`, or `patrol`, source
`tool/android-env.sh` (install also appends that to `~/.bashrc`).

The emulator needs `/dev/kvm` writable for a fast boot. Without KVM it still
starts (`-accel off`) and `start` waits up to 15 minutes for
`sys.boot_completed`.

## Run

```bash
# Smoke: Patrol + AVD only (no gym screens).
# -d is required if Flutter still lists Chrome as a device.
patrol test -d emulator-5554 -t integration_test/flows/smoke_patrol_ready_test.dart

# Later flow files — see docs/patrol-flows.md
# patrol test -t integration_test/flows/flow_1_2a_welcome_and_beginner_test.dart
# dart run tool/push_patrol_import_files.dart
# patrol test -t integration_test/flows/flow_2c_import_json_test.dart
```

Existing `integration_test/*.dart` wrappers are host/device runners for widget
tests. Do not pass that folder to `patrol test`. Patrol only looks in
`integration_test/flows/` (`test_directory` in `pubspec.yaml`).

Never `pumpAndSettle` on Welcome: the Lottie animation does not stop.

## Device data

Import tests need JSON and a `.gymplan` package on the emulator. From the repo
root:

```bash
dart run tool/push_patrol_import_files.dart
```

That copies `valid-plan.json`, `broken.json`, and a generated
`pack.gymplan` into Downloads (MediaStore-indexed so DocumentsUI lists
unknown `.gymplan` extensions).

Windows PowerShell cannot run `./tool/push-patrol-import-files.sh` — it treats
`.sh` as a document and asks which app should open it. Use the `dart run`
command above, or `.\tool\push-patrol-import-files.ps1`. Git Bash and macOS /
Linux can also run `bash tool/push-patrol-import-files.sh`.

Force-stop (process death):

```bash
adb shell am force-stop com.zahra.gym_app
```
