# Gym App

Offline workout app: get a plan in (beginner template, JSON import, or create), log a live session, rate each exercise 1–5, and see a month calendar with per-exercise trends. One local user. Data lives in Isar. The locked product is [docs/product-plan.md](docs/product-plan.md). What a person actually taps is [docs/user-journey.md](docs/user-journey.md).

Package name: `gym_app`  
Application ID: `com.zahra.gym_app`

## What it can do today

| Capability | Status |
|---|---|
| Welcome when no plans exist | Working. Later launches go to Plans |
| Beginner templates | Working (`Beginner full body`, `Beginner 2-day`) |
| Import JSON (`name` / `basic-plan` / `common-plan`) | Working. Invalid JSON shows a readable error |
| Create a plan | Working. Empty Day 1; Start stays disabled until a block or common section exists |
| Plan / day preview and editors | Working. Rename, add/delete days, common sections. No delete-plan overflow yet |
| Start / resume a day | Working. Commons default off. In-progress conflict: Resume / Abandon and start / Cancel |
| Live logger | Working. Snapshot session, alternating supersets, rest stopwatch, duration timer, inline 1–5 |
| Finish / Discard | Working. Partial finish is `completed`. Discard is hidden on Month |
| Month tab | Working. Dots, session log, per-exercise trends |
| HTTP as the UI source of truth | No. Optional sync only if compiled with `API_BASE_URL` |

## User flow

```
Welcome (/)  →  Beginner plans / Import preview / New plan
                     ↓
              Plans home (/home)  —  Plans | Month
                     ↓
              Plan → Day preview → Live workout (/session)
                     ↓
              Month calendar → session log
```

1. **Welcome** — Lottie gym animation, three actions: Start with a beginner plan, Import a plan, Create a plan. Skipped once any plan exists.
2. **Plans** — Continue banner if a session is live, Today card (next startable day on the newest startable plan), plan list, Import | New.
3. **Plan / day** — Photo day cards, common-section chips, read-only day preview, editor, Start workout.
4. **Live** — Log weight/reps or duration, rest, rate 1–5, End → Finish, Discard, or Keep going.
5. **Month** — Calendar dots, empty-month / empty-day copy, expandable trends.

## Architecture

- **UI:** Flutter Material 3, seed color `Colors.deepPurple`.
- **Navigation:** GetX named routes. Plan and session ids on routes are **uuids**.
- **Domain:** `lib/domain` — models, repository interfaces, start/progress rules. No Isar imports.
- **Data:** Isar 3 adapters, JSON importer, in-memory stand-ins for web/tests, optional HTTP remotes.
- **Composition:** `lib/app/app_bootstrap.dart` opens storage and picks Welcome vs Plans. `kIsWeb` stays here, not in pages.

```
lib/
  main.dart
  app/           # boot + GetX page table
  domain/        # Isar-free
  data/          # Isar, importer, memory, optional sync
  common/        # theme, widgets, route names
  features/
    welcome/
    plans/
    workout/
    progress/
```

## Platforms

Configured for **Android**, **iOS**, **web**, and **Linux desktop**.

> **Web is not a v1 Isar target.** Native builds open Isar 3 (`dart:ffi`). Web uses in-memory repositories so the UI can still compile. Use Android, iOS, or Linux desktop for real persistence.

Linux import uses `file_picker`, which expects `zenity`, `qarma`, or `kdialog`.

## Run

Requires Flutter 3.5+ (developed against Flutter 3.44 / Dart 3.12).

```bash
flutter pub get
flutter run
```

### Linux desktop / headless environments

```bash
flutter run -d linux
```

Linux desktop needs the GTK toolchain (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`, a matching `libstdc++-*-dev`) and `xdg-user-dirs` so `path_provider` can resolve the documents directory. The reproducible setup lives in [`.cursor/Dockerfile`](.cursor/Dockerfile) and [`.cursor/environment.json`](.cursor/environment.json).

First-run Welcome needs an empty local DB. Stop the app (by PID), then:

```bash
.cursor/skills/walk-docs-flows/scripts/reset-isar.sh
```

Regenerate Isar code after changing `lib/data/isar` models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Dependencies

| Package | Role |
|---|---|
| `get` | Routing and live-workout controller |
| `isar` / `isar_flutter_libs` | Local persistence (native) |
| `isar_generator` + `build_runner` | Isar codegen |
| `lottie` | Welcome animation (`assets/json/gym.json`) |
| `flutter_svg` | Exercise-group icons |
| `file_picker` | JSON import |
| `image_picker` | Optional gallery media in the day editor |
| `path_provider` | App documents directory |
| `http` | Optional remotes when `API_BASE_URL` is set |

**Isar is kept on 3.1.x.** Jumping to Isar 4 would need a migration, not a version bump.

## Known gaps

- No overflow to delete a whole plan (sessions should remain if that lands).
- Auto-start rest, target weight, accounts, suggested next load, reorder/duplicate days are out of v1.
