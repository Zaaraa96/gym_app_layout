# Gym app product plan

Planning only. This document is the source of truth for Steps 1–5. Do not treat the current hardcoded demo in `lib/main.dart` as the product.

## Step 1 — Product (confirmed)

Locked decisions:

- Get a plan in by **JSON import** and by **create/edit in the app**.
- Rate difficulty **1–5 per exercise** (not once for the whole day).
- Single local user. **Offline is the normal mode.** No account, no network.
- A **plan** is the prescription. A **session** is what happened on a date.
- Image-per-exercise is out of v1.

`common-plan` (abs, corrective, and similar) is **not** a second plan. It is extra named sections on the imported/created program. When the user starts a day they choose which common sections to include. Those blocks are copied into that session only.

v1: import + create/edit, start/resume a day, log sets (weight/reps or duration), rest stopwatch, 1–5 per exercise, month calendar + per-exercise trends.

---

## Step 2 — Data model

Two Isar **collections**. Nested types are `@embedded`. Sessions snapshot the prescription so later plan edits do not rewrite history.

Progress queries load sessions in a date range and fold in Dart. Volume is small (a month of workouts). Do not make `SetLog` its own collection in v1.

### Identity

- Collection ids: Isar `Id` auto-increment.
- Nested ids: string UUIDs so a session can point at a day/block/exercise after copy.
- Progress grouping key: `exerciseTitleKey = title.trim().toLowerCase()`. Same name across days and plans rolls up.

### `WorkoutPlan` (collection)

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `Id` | Auto-increment |
| `title` | `String` | |
| `source` | `PlanSource` | `imported` or `created` |
| `createdAt` | `DateTime` | |
| `updatedAt` | `DateTime` | Indexed |
| `days` | `List<PlanDay>` | `basic-plan` |
| `commonSections` | `List<CommonSection>` | `common-plan` |

### `PlanDay` (embedded)

| Field | Type | Notes |
| --- | --- | --- |
| `dayId` | `String` | UUID |
| `title` | `String` | e.g. `day 1- 4sar` |
| `summary` | `String` | Optional |
| `blocks` | `List<ExerciseBlock>` | Ordered |

### `CommonSection` (embedded)

| Field | Type | Notes |
| --- | --- | --- |
| `sectionId` | `String` | UUID |
| `title` | `String` | e.g. `abs`, `corrective` |
| `blocks` | `List<ExerciseBlock>` | |

### `ExerciseBlock` (embedded)

| Field | Type | Notes |
| --- | --- | --- |
| `blockId` | `String` | UUID |
| `kind` | `BlockKind` | `single` or `superset` |
| `svgPath` | `String?` | Optional icon; may be empty on import |
| `exercises` | `List<ExercisePrescription>` | One item for `single`; two or more for `superset` |

### `ExercisePrescription` (embedded)

| Field | Type | Notes |
| --- | --- | --- |
| `prescriptionId` | `String` | UUID |
| `title` | `String` | |
| `prescribedSets` | `int` | `>= 1` |
| `prescribedReps` | `int?` | JSON `times` |
| `prescribedDurationSeconds` | `int?` | JSON `duration` |
| `targetWeightKg` | `double?` | Unused in v1 UI; store null |

Invariant: **exactly one** of `prescribedReps` or `prescribedDurationSeconds` is non-null. That chooses the live-workout controls (rep logger vs duration timer).

### `WorkoutSession` (collection)

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `Id` | Auto-increment |
| `planId` | `int` | Indexed. Plan may later be deleted; snapshots still stand |
| `planDayId` | `String` | |
| `planTitleSnapshot` | `String` | |
| `dayTitleSnapshot` | `String` | |
| `includedCommonSectionIds` | `List<String>` | Chosen at start |
| `startedAt` | `DateTime` | Indexed |
| `endedAt` | `DateTime?` | |
| `status` | `SessionStatus` | `inProgress`, `completed`, `abandoned` |
| `exerciseLogs` | `List<ExerciseLog>` | Day blocks, then included common blocks, in order |

At most **one** `inProgress` session. Starting another: resume the existing one, or mark it `abandoned` and start fresh.

### `ExerciseLog` (embedded)

Copied from the prescription when the session starts.

| Field | Type | Notes |
| --- | --- | --- |
| `prescriptionId` | `String` | From the template |
| `blockId` | `String` | |
| `blockKind` | `BlockKind` | |
| `fromCommonSection` | `bool` | |
| `exerciseTitle` | `String` | Snapshot |
| `exerciseTitleKey` | `String` | Snapshot of normalized name |
| `prescribedSets` | `int` | |
| `prescribedReps` | `int?` | |
| `prescribedDurationSeconds` | `int?` | |
| `sets` | `List<SetLog>` | |
| `difficulty` | `int?` | 1–5. Required to mark this exercise complete |
| `completedAt` | `DateTime?` | Set when difficulty is saved |

An exercise is **complete** when `difficulty != null`. Sets can be logged before rating. Rating is the last step for that movement.

### `SetLog` (embedded)

| Field | Type | Notes |
| --- | --- | --- |
| `setIndex` | `int` | 1-based |
| `reps` | `int?` | Strength / rep work |
| `weightKg` | `double?` | Null = bodyweight or not entered |
| `durationSeconds` | `int?` | Timed work |
| `completedAt` | `DateTime` | |

Rest is **not** stored. The rest stopwatch is UI-only in v1.

### Import JSON (v1)

Evolve `assets/json/plan.json`. The checked-in file has a trailing comma and is not valid JSON; the importer must reject invalid JSON with a readable error. Canonical shape:

```json
{
  "name": "plan 1",
  "days": 3,
  "basic-plan": [
    {
      "name": "day 1- 4sar",
      "exercises": [
        {
          "type": "super-set",
          "exercise": [
            { "title": "kang squat", "sets": 3, "times": 12, "duration": null },
            { "title": "leg extension", "sets": 3, "times": 12, "duration": null }
          ]
        },
        {
          "type": "single",
          "exercise": {
            "title": "reverse lunges+ Press",
            "sets": 3, "times": 12, "duration": null
          }
        }
      ]
    }
  ],
  "common-plan": [
    {
      "name": "abs",
      "exercises": [
        {
          "type": "single",
          "exercise": {
            "title": "shoot out", "sets": 1, "times": null, "duration": 30
          }
        }
      ]
    }
  ]
}
```

Mapping:

- `name` → `WorkoutPlan.title`
- `basic-plan[]` → `days[]` (`name` → `title`, `exercises` → `blocks`)
- `type: "single"` → one `ExercisePrescription`
- `type: "super-set"` → one `ExerciseBlock` with several prescriptions
- `times` → `prescribedReps`; `duration` → `prescribedDurationSeconds`
- `common-plan[]` → `commonSections[]` (`name` → `title`)
- `days` (count) is informational; trust the array length

### Progress rules (month)

Load sessions whose `startedAt` falls in the visible month and `status` is `inProgress` or `completed`. Ignore `abandoned`. Group `ExerciseLog`s by `exerciseTitleKey`.

For each group, order sessions by `startedAt`.

**Primary metric** (first match):

1. If any set has `weightKg != null` → **weight**
2. Else if the prescription is duration (`prescribedDurationSeconds != null`) → **duration**
3. Else → **sets / reps**

**Weight.** Session working weight = max `weightKg` among that log’s sets. Month trend = last session’s working weight minus first session’s. Up is better.

**Duration.** Session duration = max `durationSeconds` among that log’s sets (best hold / longest timed work). Higher is better (planks, stretches, holds). Rest time is never this metric. Completion flag: a set counts as meeting the prescription when `durationSeconds >= prescribedDurationSeconds`.

**Sets / reps.** Session completed sets = `sets.length`. Session reps = sum of `reps`. Trend uses completed sets vs `prescribedSets` (completion ratio), and total reps as a secondary number.

**Difficulty (secondary).** If the primary load is the same or better (weight, duration, or reps) and `difficulty` went **down**, show “felt easier”. 1 = easy, 5 = hard.

Do not use rest length as improvement.

### Replace

Drop `SinglePlanModel` / `SingleDayPlanModel` / `SingleExerciseWithRound` / `ExerciseWithRepetitionModel`. No production data to migrate.

---

## Step 3 — UX design

Keep Material 3, deep purple seed, photo day cards, Lottie welcome. No new visual language before code. Full Figma is optional; this screen map is enough to build.

### Navigation

After first run, a **bottom bar**: Plans | Month.

```
Welcome
  ├─ Import JSON → preview → save → Plan preview
  ├─ Create plan → editor → Plan preview
  └─ (returning) → Plans home

Plans home
  ├─ Plan preview (day cards)
  │     ├─ Edit plan
  │     └─ Day preview → Start (common-section toggles) → Live workout
  └─ Import / Create

Live workout
  ├─ Block (single or superset)
  │     ├─ Log set (weight+reps or duration timer)
  │     ├─ Rest stopwatch
  │     └─ Rate 1–5 when that exercise’s sets are done
  └─ End early → session completed or abandoned

Month
  ├─ Calendar
  ├─ Day tap → session log (read-only)
  └─ Exercise row → simple trend for that name
```

Resume: if `inProgress` exists, Plans home shows **Continue workout** above the list.

### Screen inventory

| Screen | Purpose | Reuse |
| --- | --- | --- |
| Welcome | First-run fork: import or create | `welcome_page.dart` |
| Plans home | List plans; continue session; import/create actions | New |
| Import preview | Show parsed days/blocks; confirm save | New |
| Plan preview | Day cards | `single_plan_page.dart` |
| Day preview | Block list | `single_day_plan_page.dart` + start CTA |
| Common-section sheet | Toggles before start | New |
| Plan editor | Title, days, blocks, exercises | Replace `add_plan_page.dart` |
| Live workout | Current block, set logger, rest | Replaces `single_exercise_page.dart` |
| Rate exercise | 1–5 | New (can be a dialog) |
| Month | Calendar + trends | New |
| Session log | Read-only day history | New |

### Wireframes (layout, not pixels)

**Welcome.** Centered Lottie, title, subtitle, two full-width actions: Import a plan | Create a plan. Returning users skip this if any plan exists (open Plans home). Show welcome once via a local flag, or skip whenever `WorkoutPlan` count > 0.

**Plans home.** App bar “Plans”. If in-progress: banner Continue. List of plan titles + day count. FAB or bottom actions: Import, New. Bottom nav: Plans (selected), Month.

**Import preview.** File name, plan title, expandable days (block summaries: `3×12 kang squat + leg extension`). Common sections listed as chips. Primary: Save plan. Secondary: Cancel.

**Plan preview.** Keep current sliver + photo cards. App bar: title, edit icon. Card arrow still opens the day.

**Day preview.** Keep alternating summary rows (SVG, names × reps or duration, set/round badge). Bottom: Start workout.

**Start sheet.** “Include today” with switches for each `CommonSection`. Confirm starts a `WorkoutSession` and copies logs.

**Live workout (make-or-break).**

```
[ Day 1  ·  set 2 of 3  ·  0:45 rest ]

Superset
  Kang squat          3 × 12
  Leg extension       3 × 12

Active: Kang squat
  Weight [  40  ] kg     Reps [  12  ]
  [ Log set ]

Rest stopwatch  [ Start ]  [ Reset ]

When sets for Kang squat are done:
  How hard?  1  2  3  4  5
```

Superset: both prescriptions stay visible; one is **active**. After rating exercise A, active becomes B in the same block. Duration exercises replace weight/reps with a countdown from `prescribedDurationSeconds` and a Log time action (stores actual seconds, which may be more or less than prescribed).

Persist every logged set immediately. Back leaves the session `inProgress`.

**Rate.** Required. Five equal tappable digits. Confirm writes `difficulty` and `completedAt`. No skip in v1.

**Month.** Month title with prev/next. Calendar: dots on days with a non-abandoned session. Below: list of `exerciseTitleKey`s this month with primary metric, delta vs first session in the month, and optional “felt easier”. Tap a calendar day → session log (exercises, sets, ratings). Tap an exercise row → the same numbers, no extra screen required in v1 if the list is enough.

### Out of v1 UI

Auto-start rest, target weight field, photos, accounts, suggested next load, reordering days, duplicating days.

---

## Step 4 — Technical architecture

### Keep

- Flutter Material 3 theme (`lib/common/app_theme.dart`)
- GetX `GetMaterialApp` named routes
- Isar **3.1.x** + `isar_flutter_libs` + `isar_generator` (no Isar 4)
- Shared widgets: `AppScaffold`, `AppText`, `AppElevatedButton`, `AppTextField`
- Lottie welcome, SVG icons, day photo assets
- `path_provider` for the Isar directory

### Drop or replace

- Hardcoded `SinglePlanModel` in `main.dart`
- Opening Isar inside the add-plan button
- Unused `view.dart` / empty `SinglePlanLogic` (replace with real controllers)
- `image_picker` flow on the exercise screen (leave the dependency until a later slice if unused)
- Default counter `widget_test.dart` (replace with a smoke test of `MyApp` once routing is stable)

### New pieces

| Piece | Role |
| --- | --- |
| `lib/data/isar_service.dart` | Open Isar once in `main()`, register schemas, expose as GetxService |
| `lib/data/plan_repository.dart` | CRUD plans |
| `lib/data/session_repository.dart` | CRUD sessions; query by month; find in-progress |
| `lib/data/json_plan_importer.dart` | Parse and map JSON → `WorkoutPlan` |
| `lib/features/workout/workout_controller.dart` | Live session state; log set; rest clock; rate |
| `lib/features/progress/progress_service.dart` | Pure Dart month fold of the rules in Step 2 |
| `file_picker` | Pick `.json` from the device |

### App start

```
WidgetsFlutterBinding.ensureInitialized()
open Isar (path_provider documents dir)
Get.put(IsarService)
runApp
initialRoute: plans exist ? /home : /
```

### Live workout state

`WorkoutController` is a GetX controller created with the session id. It:

- Loads the session from Isar
- Tracks `activeLogIndex`
- Holds rest elapsed seconds with `Stopwatch` + `Timer.periodic` (1s). Rest is not written to Isar
- Duration work: countdown `int` remaining; Log time stores `prescribed - remaining` or elapsed, whichever the UI shows; persist `durationSeconds`
- Calls `sessionRepository.update` after each set and after rating so process death does not lose the log

No extra timer package.

### Offline

No HTTP. Import is a local file. Export (later) would be a local file. Target **Android and iOS** for v1. Web may compile but Isar 3 web is not a v1 goal.

### Permissions

`file_picker` needs the usual Android/iOS document access. No camera permission until photos return.

### File layout (target)

```
lib/
  main.dart
  data/
    isar_service.dart
    plan_repository.dart
    session_repository.dart
    json_plan_importer.dart
    models/          # WorkoutPlan, WorkoutSession, enums, embeds
  common/            # theme, widgets (keep)
  features/
    welcome/
    plans/           # home, preview, editor, import
    workout/         # day start, live, rate
    progress/        # month, session log
```

Routes (names can shift slightly at implementation): `/`, `/home`, `/import`, `/plan`, `/plan/edit`, `/day`, `/session`, `/month`.

---

## Step 5 — Implementation slices

Build in this order. Each slice should be runnable. Do not start a later slice until the earlier one stores and shows real data.

1. **Isar bootstrap + new models**  
   Schemas, `IsarService` in `main`, codegen. No UI change except the app still launches.

2. **Empty home + welcome fork**  
   If no plans → Welcome with Import / Create. If plans exist → Plans home list (empty actions still visible). Remove hardcoded `/plan` demo as the launch route.

3. **JSON import**  
   File picker, parse, preview, save `WorkoutPlan`. Ship a valid sample (fix `assets/json/plan.json`). Open Plan preview from the saved plan.

4. **Plan preview + day preview from Isar**  
   Wire existing day cards and block list to `WorkoutPlan` / `PlanDay` (map duration vs reps in the summary row).

5. **Create / edit plan**  
   Replace add-plan stub: title, days, single/superset blocks, reps or duration. Save updates `updatedAt`.

6. **Start session**  
   Common-section toggles, copy `ExerciseLog`s, create `inProgress` session, Continue banner.

7. **Live logger**  
   Active exercise, log set (weight+reps or duration timer), rest stopwatch, persist each set. Superset keeps both lines visible.

8. **Per-exercise 1–5**  
   After prescribed sets (or when the user marks the movement done), require rating. Advance to the next log. End session when all logs are rated, or End early → `completed` with partial logs (rated ones keep ratings; unrated stay null).

9. **Month overview**  
   Calendar + day session log + per-exercise primary metric and delta using `progress_service.dart`.

10. **Harden**  
    Resume after kill, one in-progress session rule, invalid JSON error, analyze/lints, replace counter test with a shallow widget test that does not need a device file picker.

Slice 10 is the last v1 planning slice. Photos, cloud, auto rest, and target weight stay later.
