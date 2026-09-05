# Patrol flow tests

These are device tests for the journeys in `docs/user-journey.md`. They run
the real app (Isar, native file picker, Android Back). Host widget tests stay
on `flutter test --concurrency=1`.

`patrol_cli` 4.7.0 only accepts files whose names end in `_test.dart`.
`test_directory` is `integration_test/flows/`. Do not pass
`integration_test/*.dart` to `patrol test`.

Never `pumpAndSettle` on Welcome: the Lottie animation does not stop. The
shared robot uses `SettlePolicy.trySettle` with a short timeout, and
`noSettle` on first-run taps.

AndroidX Test Orchestrator is on with `clearPackageData`. Each `patrolTest`
starts from an empty database. Files that need a beginner plan install it
themselves. Do not chain `flow_3_7` after `flow_8` (or the reverse) expecting
shared Isar state.

## Files

| File | Journey |
| --- | --- |
| `smoke_patrol_ready_test.dart` | Patrol + AVD only (no gym screens) |
| `flow_1_2a_welcome_and_beginner_test.dart` | §1 Welcome, §2a beginner full body, same-title reuse, delete plan |
| `flow_2b_create_from_scratch_test.dart` | §2b create; §5d empty start snackbar; discard |
| `flow_2c_import_json_test.dart` | §2c native picker (invalid then `plan.json`) |
| `flow_3_7_home_to_month_test.dart` | §3–7 on full body: home, day, commons, live, 6c/6d, snapshot edit before finish, Month |
| `flow_8_first_week_loop_test.dart` | §8 happy path, own reset |
| `flow_9_6_beginner_two_day_test.dart` | §2a other starter (Beginner 2-day) |

Shared robot: `support/gym_app.dart`.

## Run

```bash
# Smoke (no gym UI)
patrol test -t integration_test/flows/smoke_patrol_ready_test.dart

# First-run + beginner
patrol test -t integration_test/flows/flow_1_2a_welcome_and_beginner_test.dart

# Create / empty start
patrol test -t integration_test/flows/flow_2b_create_from_scratch_test.dart

# Import (push fixtures first)
./tool/push-patrol-import-files.sh
patrol test -t integration_test/flows/flow_2c_import_json_test.dart

# Home → live → month (includes superset + timed plank on Day 1)
patrol test -t integration_test/flows/flow_3_7_home_to_month_test.dart

# Full first-week loop
patrol test -t integration_test/flows/flow_8_first_week_loop_test.dart

# Two-day starter
patrol test -t integration_test/flows/flow_9_6_beginner_two_day_test.dart
```

Pin the AVD with `-d emulator-5554` if Flutter still lists another device.

## Device notes

- Beginner Day 1 already has a super-set (Glute bridge + Bird dog) and timed
  Plank. 6c/6d use that, not `plan.json`.
- Imported / starter day ids are generated. Tap days by title, not
  `day-card-day-1`.
- Process death from the host: `adb shell am force-stop com.zahra.gym_app`.
  The Dart tests use Home then `openApp` so they stay in-band.
- Three-button home row (Import / New / Beginner) can sit under the IME or
  near the nav bar on a phone; the robot scrolls/ensures visible before tap.
