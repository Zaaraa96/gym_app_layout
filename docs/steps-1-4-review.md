# Review: product-plan Steps 1–4

**Historical.** Written when slices 5–9 were still later work. The running app now includes create/edit, start/commons/conflict, live logger, 1–5, and Month. For current screens, use [user-journey.md](user-journey.md) and [product-plan.md](product-plan.md). Do not skip a journey step because this file says a later slice is unfinished.

Reviewed against `docs/product-plan.md` (source of truth for Steps 1–5) and the `main` implementation at the time. Tests were run with Flutter 3.44.9 / Dart 3.12.2. Failures in `plan_editor_test.dart` were fixed; Start-workout enablement on day preview was aligned with Step 3.

Slice numbers below are from Step 5. Steps 1–4 are product, data, UX, and architecture. Slices 1–4 are the first build slices that should already be runnable.

## Verdict

| Area | Status |
| --- | --- |
| Step 1 — Product | Matches. Locked v1 choices are in the model and import path. Live logging / month UI are later slices, as planned. |
| Step 2 — Data model | Matches. Two Isar collections, embeds, import mapping, session snapshot, progress fold. |
| Step 3 — UX (screens that exist) | Mostly matches slices 2–4. Gaps are almost all Step 5 slices 5–9. One slice-4 miss (Start enablement) is now fixed. |
| Step 4 — Architecture | Matches. Layout, bootstrap, repositories, importer, live controller, progress service, `file_picker`. Live route is named but not registered yet (slice 7). |
| Tests after this review | **47 passed** (`flutter test`, Flutter 3.44.9). |

At review time, `README.md` still described the old hardcoded demo (`SinglePlanModel`, launch at `/plan`, counter `widget_test.dart`). That README has since been rewritten; this file has not.

---

## Step 1 — Product

Locked decisions vs code:

| Decision | In code? |
| --- | --- |
| JSON import **and** create/edit | Yes: `JsonPlanImporter`, import preview, `AddNewPlanPage`, day editor. |
| Rate difficulty 1–5 **per exercise** | Model + `WorkoutController.rate`. No live UI yet (slice 8). |
| Single local user, offline | Yes: no HTTP, Isar in documents dir. |
| Plan vs session | Yes: `WorkoutPlan` vs `WorkoutSession` with snapshots. |
| No image-per-exercise in v1 | Yes: picker left as a dependency only. |
| `common-plan` is extra sections, chosen at start | Model + `SessionRepository.start` copies included sections. Start sheet UI is slice 6. |

No Step 1 contradiction found.

---

## Step 2 — Data model

`WorkoutPlan` / `PlanDay` / `CommonSection` / `ExerciseBlock` / `ExercisePrescription` and `WorkoutSession` / `ExerciseLog` / `SetLog` match the field tables, including:

- Auto-increment collection ids; string UUIDs on nested types (`newId()`).
- `exerciseTitleKey = title.trim().toLowerCase()`.
- Indexed `updatedAt`, `planId`, `startedAt`.
- Exactly-one-of reps vs duration enforced at import.
- Rest not stored.
- Sessions snapshot titles and prescriptions so later plan edits do not rewrite history (covered in `isar_bootstrap_test.dart`).

Old `SinglePlanModel` types are gone. `SetLog` is embedded, not a collection.

Progress rules live in `ProgressService` (pure Dart). Month queries in `SessionRepository.forMonth` drop `abandoned` and keep `inProgress` / `completed`.

Import JSON: `assets/json/plan.json` is valid. Trailing-comma files throw `PlanImportException` with a readable message.

---

## Step 3 — UX (what slices 2–4 must already show)

### In place

- Material 3, deep purple seed, Lottie welcome, photo day cards (`assets/image/0–2.png`).
- Bottom bar on the **home shell only** (Plans \| Month). Nested screens have no bar.
- Welcome when plan count is 0; otherwise `/home`. No extra local flag.
- Welcome actions: Import a plan \| Create a plan.
- Plans home: list + day count, bottom row Import \| New (not a FAB).
- Import preview: file name, title, expandable day summaries, common-section chips, Save / Cancel.
- Plan preview: photo cards, rename (edit icon), add day (app bar + FAB), card tap → day preview.
- Day preview: alternating block rows (SVG, `x12` / `x30s`, set badge), Edit day, Start workout.
- Month tab is a placeholder until slice 9.

### Intentionally later (not a Steps 1–4 miss)

| Gap | Slice |
| --- | --- |
| Delete plan overflow (sessions stay) | 5 |
| Common-section chips / Add section / section editor | 5 |
| Continue workout banner | 6 |
| Start sheet (commons default off) | 6 |
| In-progress conflict dialog | 6 |
| Live workout, rest stopwatch, inline 1–5, Finish/Discard | 7–8 |
| Month calendar + session log | 9 |

### Slice 4 miss, now fixed

Step 3: Start is enabled when the day has at least one block **or** the plan has common sections; otherwise disabled.

Previously Start was always enabled and showed a snackbar. It now uses a nullable `onPressed`. Logging is still a snackbar until slice 6.

---

## Step 4 — Technical architecture

### Keep / drop

- Theme, GetX named routes, Isar 3.1.x, shared widgets, Lottie/SVG/photos, `path_provider`: kept.
- Hardcoded demo plan, opening Isar in add-plan, `view.dart` / `SinglePlanLogic`, default counter test: gone.
- `image_picker` still in `pubspec.yaml` (plan says leave until a later slice).

### New pieces

| Piece | Present |
| --- | --- |
| `lib/data/isar_service.dart` | Yes, `Get.put` in `main()` |
| `plan_repository.dart` | Yes |
| `session_repository.dart` | Yes (CRUD, month, in-progress, start snapshot) |
| `json_plan_importer.dart` | Yes |
| `features/workout/workout_controller.dart` | Yes (no live page yet) |
| `features/progress/progress_service.dart` | Yes (no month UI yet) |
| `file_picker` | Yes |

App start matches the plan: `ensureInitialized` → open Isar → put services → `initialRoute` from plan count.

File layout matches the target tree. Routes: `/`, `/home`, `/import`, `/new-plan`, `/plan`, `/day`, `/edit-day`. `AppRoutes.session` is defined but not in `getPages` (slice 7).

No HTTP. Android/iOS (and Linux desktop for this environment). Web is documented as not a v1 Isar target.

---

## Tests

### First run (`flutter test`)

47 cases ran. 4 failed, all in `test/features/plan_editor_test.dart`:

1. **Add day / Rename / Add exercise** — GetX page transitions take ~300ms. The old `settle` only advanced ~12 frames (~200ms), so the incoming screen was still sliding. AppBar actions sat past the 800px test view. `settleApp` now pumps 400ms, then waits for Isar.
2. **Reps + duration / superset** — `findsOneWidget` on the block summary. After slice 4, the plan page stays under the editor and shows the same `formatBlock` string, so two matches.

Data, import, welcome-fork, day-preview, workout-controller, and progress tests passed on that run.

### Fixes

- Tap `Key('add-day')` (app bar) and `tooltip: Rename plan`.
- Assert summaries **inside** `DayEditorPage`.
- `settleApp` pumps 400ms so GetX route transitions finish (AppBar actions were still off-screen).
- Clear the invalid-JSON snackbar before opening import preview so it cannot cover **Save plan**.
- Disable Start when the day has no blocks and the plan has no common sections; cover both sides with widget tests.
- Allow `AppElevatedButton.onPressed` to be null so Start can disable.

---

## What is not a bug

- Start still shows “Starting a workout comes next”: slice 6.
- No live `/session` page: slices 7–8.
- No calendar: slice 9.
- `WorkoutController` / `ProgressService` existing before those UIs: Step 4 asked for those pieces; Step 5 said do not start a later **UI** slice until earlier slices store real data. The data path is already there.
