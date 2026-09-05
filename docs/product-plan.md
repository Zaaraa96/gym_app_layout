# Gym app product plan

Locked product, data, UX, and architecture for v1. The running app implements slices 1–9 (Welcome through Month). Walk screens against [user-journey.md](user-journey.md).

`lib/main.dart` only binds Flutter and `runApp`. Composition lives in `lib/app/app_bootstrap.dart`.

## Step 1 — Product (confirmed)

Locked decisions:

- Get a plan in by **JSON import** and by **create/edit in the app**.
- Rate difficulty **1–5 per exercise** (not once for the whole day).
- Single local user. **Offline is the normal mode.** No account. HTTP sync is opt-in at compile time (`--dart-define=API_BASE_URL=…`) and is off in the normal binary.
- A **plan** is the prescription. A **session** is what happened on a date.
- Full photo-per-exercise product is out of v1. The day editor can attach a bundled SVG or a gallery pick to a block; that is optional chrome, not a required field.

`common-plan` (abs, corrective, and similar) is **not** a second plan. It is extra named sections on the imported/created program. When the user starts a day they choose which common sections to include. Those blocks are copied into that session only.

v1: import + create/edit, start/resume a day, log sets (weight/reps or duration), rest stopwatch, 1–5 per exercise, month calendar + per-exercise trends.

---

## Step 2 — Data model

Two Isar **collections**. Nested types are `@embedded`. Sessions snapshot the prescription so later plan edits do not rewrite history.

Progress queries load sessions in a date range and fold in Dart. Volume is small (a month of workouts). Do not make `SetLog` its own collection in v1.

### Identity

- Product identity: string `uuid` on plans and sessions (routes and `WorkoutSession.planId` use this).
- Local adapter key: integer `id` (`0` until persisted). Isar collections still use auto-increment `Id` for the row; domain models do not import Isar.
- Nested ids: string UUIDs so a session can point at a day/block/exercise after copy.
- `dirty`: local write not yet acknowledged by optional sync.
- Progress grouping key: `exerciseTitleKey = title.trim().toLowerCase()`. Same name across days and plans rolls up.

### `WorkoutPlan` (collection)

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `Id` / `int` | Local row key. Auto-increment in Isar |
| `uuid` | `String` | Indexed. Product identity |
| `dirty` | `bool` | Sync bookkeeping |
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
| `id` | `Id` / `int` | Local row key |
| `uuid` | `String` | Product identity |
| `dirty` | `bool` | Sync bookkeeping |
| `planId` | `String` | Indexed. `[WorkoutPlan.uuid]`. Plan may later be deleted; snapshots still stand |
| `planDayId` | `String` | |
| `planTitleSnapshot` | `String` | |
| `dayTitleSnapshot` | `String` | |
| `includedCommonSectionIds` | `List<String>` | Chosen at start |
| `startedAt` | `DateTime` | Indexed |
| `endedAt` | `DateTime?` | |
| `updatedAt` | `DateTime` | Last-write-wins for optional sync |
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

`assets/json/plan.json` is valid. Trailing-comma files throw `PlanImportException` with a readable message. Canonical shape:

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

Reviewed against Step 1–2 and the screens already in the app. Locked decisions below replace the earlier “FAB or…”, “local flag or…”, and “completed or abandoned” forks.

### Navigation

**Bottom bar is the home shell only** (Plans | Month). Nested screens (import, plan, day, live, editors) have no bar; back returns toward home.

Skip Welcome whenever `WorkoutPlan` count > 0. No extra local flag.

```
Welcome (plan count == 0)
  ├─ Beginner plan → pick template → save → Home (Today card)
  ├─ Import JSON → preview → save → Plan preview
  ├─ Create plan → title form → Plan preview
  └─ (returning) → Home shell

Home shell
  ├─ Plans tab
  │     ├─ Continue banner → Live workout (resume)
  │     ├─ Today card → Start → (sheet if commons) → Live workout
  │     ├─ Plan preview (photo day cards)
  │     │     ├─ Rename plan (no delete-plan overflow yet)
  │     │     ├─ Add / delete day
  │     │     ├─ Common-section chips → section editor
  │     │     └─ Day preview → Start → (sheet if commons) → Live workout
  │     └─ Import / New  (bottom row, not a FAB)
  └─ Month tab
        ├─ Calendar
        ├─ Day tap → session log (read-only; several sessions list in startedAt order)
        └─ Exercise rows → same-screen trend numbers

Live workout
  ├─ Current block (single, or superset with alternating sets)
  │     ├─ Log set (weight+reps) or Log time (duration countdown)
  │     ├─ Rest stopwatch (manual start/reset)
  │     └─ Rate 1–5 after the block’s prescribed sets (inline, extras until rated)
  ├─ Back / system back → leave `inProgress`
  └─ End → Finish (`completed`) / Discard (`abandoned`) / Keep going
```

Resume: if `inProgress` exists, the **home shell** (both tabs) shows **Continue workout**. Tapping it opens that session’s live screen. Common-section choices are not asked again.

Starting while another session is `inProgress`:

- Same plan + same day → resume (no new sheet).
- Anything else → dialog: **Resume existing** | **Abandon and start this day** | **Cancel**.

### Screen inventory

| Screen | Purpose | Reuse |
| --- | --- | --- |
| Welcome | First-run fork: beginner template, import, or create | `welcome_page.dart` |
| Starter plans | Pick a bundled beginner program | `starter_plans_page.dart` |
| Plans home | List plans; continue session; Today card; Import / New; Month tab | `plans_home_page.dart` |
| Import preview | Show parsed days/blocks; confirm save | `import_preview_page.dart` |
| Plan preview | Photo day cards; rename; add/delete days; common-section chips. **No delete-plan overflow yet** | `plan_page.dart` |
| Day preview | Block list + Start | `day_preview_page.dart` |
| Day editor | One day’s title, summary, blocks; optional SVG/gallery media | `day_editor_page.dart` + block dialog |
| Common-section editor | One named section’s blocks; same block dialog as the day editor | `day_editor_page.dart` with `sectionId` |
| Create-plan title | Title (+ optional Day 1 summary) then Plan preview | `add_plan_page.dart` |
| Common-section sheet | Toggles before start; skip when the plan has none | Dialog in `start_workout.dart` |
| In-progress conflict | Resume vs abandon-and-start | Dialog in `start_workout.dart` |
| Live workout | Current block, set logger, rest | `live_workout_page.dart` |
| Rate exercise | Inline 1–5 on the exercise row after prescribed sets; not a blocking dialog | On `live_workout_page.dart` |
| End-workout sheet | Finish (`completed`), Discard (`abandoned`), or Keep going | Sheet on `live_workout_page.dart` |
| Month | Calendar + trends | `month_tab.dart` |
| Session log | Read-only history for one session, or a day list when several | `session_log_page.dart` |

There is **no** all-in-one “plan editor” screen. Plan-level actions live on Plan preview; exercise editing is per day (and per common section).

### Wireframes (layout, not pixels)

**Welcome.** Centered Lottie, title, subtitle, three full-width actions: Start with a beginner plan | Import a plan | Create a plan. Returning users never see this once any plan exists.

**Plans home.** App bar “Plans” (or “Month” on that tab). Continue banner above the body when `inProgress` exists. **Today** card with the next plan day and a Start CTA. List of plan titles + day count. Bottom row: Import | New. Bottom nav: Plans, Month.

**Import preview.** File name, plan title, expandable days (block summaries: `3×12 kang squat + leg extension`). Common sections listed as chips. Primary: Save plan. Secondary: Cancel.

**Plan preview.** Photo cards (keep `assets/image/0–2.png`). App bar: title, edit icon **renames** the plan, add-day icon. **Delete plan is not in the app yet** (sessions would stay, per Step 2, when it lands). Add day from the app bar / FAB. Card tap opens Day preview. **Common sections** is always shown: **Add section**, then chips (tap to edit, delete on the chip) or empty copy. Day cards can delete that day.

**Day preview.** Keep alternating summary rows (SVG, names × reps or duration, set/round badge). **Edit day** opens the day editor. Bottom: Start workout.

Start is enabled when the day has at least one block, **or** the plan has common sections (the user can train commons only). Otherwise disable Start.

**Start sheet.** Shown only when the plan has one or more `CommonSection`s. Title “Include today”. One switch per section, **default off**. Confirm copies the day’s blocks, then each enabled section’s blocks, into `ExerciseLog`s and creates the `inProgress` session.

**Live workout (make-or-break).**

```
[ Day 1  ·  Kang squat  ·  set 2 of 3  ·  rest 0:45 ]

Superset
  Kang squat          3 × 12     ← active
  Leg extension       3 × 12

Active: Kang squat
  Weight [     ] kg     Reps [  12  ]
  [ Log set ]

Rest stopwatch  [ Start ]  [ Reset ]
```

A **superset is alternating sets**, not “finish A then B”. Both prescriptions stay visible; **active** is the next exercise in the block that still has unlogged prescribed sets, cycling in prescription order: A1 → B1 → A2 → B2 → … Weight may be empty (`null` = bodyweight). Reps are required for rep work.

After each logged set, rest is **manual** (user starts the stopwatch). Do not auto-start rest.

**Prescribed phase.** Only the active exercise accepts Log set / Log time. Keep alternating until every log in the block has `sets.length >= prescribedSets`. Do not rate yet if the partner still has prescribed sets left (A3 then B3, not A3-rate-B3).

**Then extras + rating.** 1–5 appears **inline** on each unrated row in that block — never a modal that replaces logging. Log set stays on that row until they tap a digit. Extra sets are allowed only in this phase, and only on an unrated exercise. Tapping 1–5 writes `difficulty` and `completedAt` and hides Log set for that movement. No skip.

Duration exercises replace weight/reps with a countdown from `prescribedDurationSeconds`, paused until Start. The countdown may run past 0 (overtime). **Log time** stores actual seconds: if the timer ran, elapsed (`prescribed − remaining`, remaining can be negative); if they log without starting, store the prescribed value. No separate control to type remaining.

Header must name the **active exercise** and that exercise’s set index, not only “set 2 of 3”.

Persist every logged set immediately. App-bar back and system back leave the session `inProgress` with no extra prompt.

**End.** A live-workout action (not back) opens Finish | Discard | Keep going. Finish → `completed` (partial logs stay; unrated `difficulty` stays null). Discard → `abandoned` (month view ignores it, per Step 2). Keep going dismisses the sheet.

**Rate.** Required to mark the movement complete. Five equal tappable digits. Confirm writes `difficulty` and `completedAt`.

**Month.** Month title with prev/next. Empty month: calendar with no dots and “No workouts this month.” Dots on days with a non-abandoned session. Below: list of `exerciseTitleKey`s this month with primary metric, delta vs first session in the month, and optional “felt easier”. Tap a dotted day → session log (one session) or a day list (several, oldest first). Tap a day with no session → “No workouts this day.” Trend rows expand in place.

### Out of v1 UI

Auto-start rest, target weight field, required photos, accounts, suggested next load, reordering days, duplicating days, prefill weight from last session, delete-plan overflow.

---

## Step 4 — Technical architecture

### Keep

- Flutter Material 3 theme (`lib/common/app_theme.dart`)
- GetX `GetMaterialApp` named routes (`lib/app/app_routes.dart`)
- Isar **3.1.x** + `isar_flutter_libs` + `isar_generator` (no Isar 4)
- Shared widgets: `AppScaffold`, `AppText`, `AppElevatedButton`, `AppTextField`
- Lottie welcome, SVG icons, day photo assets
- `path_provider` for the Isar directory
- Domain types and repository **interfaces** stay Isar-free. Pages do not import `isar_*_repository.dart`. `kIsWeb` belongs at composition (`bootApp` / adapters), not in pages.

### Dropped (done)

- Hardcoded `SinglePlanModel` in `main.dart`
- Opening Isar inside the add-plan button
- Unused `view.dart` / `SinglePlanLogic`
- Default counter `widget_test.dart`

`image_picker` is used by the day-editor media sheet.

### Pieces

| Piece | Role |
| --- | --- |
| `lib/app/app_bootstrap.dart` | `bootApp`: open storage, register ports, pick welcome vs home |
| `lib/data/isar_service.dart` | Open Isar once, register schemas |
| `lib/domain/plan_repository.dart` | Plan CRUD interface (Isar-free) |
| `lib/domain/session_repository.dart` | Session CRUD interface; month; in-progress |
| `lib/data/isar_plan_repository.dart` | Isar adapter |
| `lib/data/isar_session_repository.dart` | Isar adapter |
| `lib/data/memory_*_repository.dart` | Web / test stand-ins |
| `lib/data/json_plan_importer.dart` | Parse and map JSON → domain `WorkoutPlan` |
| `lib/features/workout/workout_controller.dart` | Live session state; log set; rest clock; rate |
| `lib/domain/progress_service.dart` | Pure Dart month fold of the rules in Step 2 |
| `lib/data/sync/sync_service.dart` | Optional HTTP last-write-wins when `API_BASE_URL` is set |
| `file_picker` | Pick `.json` from the device |

### App start

```
WidgetsFlutterBinding.ensureInitialized()
runApp(AppBootstrap)          # first frame is a loader, not a black view
bootApp:
  native → IsarService + Isar*Repository
  web    → Memory*Repository  (Isar 3 will not open)
  put SessionLifecycle, PlanImportPicker, AppPorts
  optional SyncService if API_BASE_URL is non-empty
initialRoute: plans exist ? /home : /
```

### Live workout state

`WorkoutController` is a GetX controller created with the session uuid. It:

- Loads the session from the session repository
- Tracks which `ExerciseLog` is **active**. On a single, that log stays active through extras until it is rated. On a superset, after each logged set in the prescribed phase the active log becomes the next partner in the same `blockId` with `sets.length < prescribedSets`. After every log in the block has its prescribed sets, extras and inline 1–5 are available on each unrated log in that block; rating one does not hide the partner
- Holds rest elapsed seconds with `Stopwatch` + `Timer.periodic` (1s). Rest is not written to Isar
- Duration work: countdown `int` remaining, paused until Start; Log time stores `prescribed - remaining` if the timer ran, or the prescribed value if they log without starting; persist `durationSeconds`
- Calls `sessionRepository.update` after each set and after rating so process death does not lose the log

No extra timer package.

### Offline

Offline is normal. Import is a local file. HTTP is not the UI source of truth. Compile with `--dart-define=API_BASE_URL=https://host` to enable optional sync. Target **Android and iOS** for v1; Linux desktop is the Cloud Agent run target. Web may compile (memory repositories) but Isar 3 web is not a v1 goal.

### Permissions

`file_picker` needs the usual Android/iOS document access. Gallery picks in the day editor need `image_picker` platform permissions if you ship that path.

### File layout

```
lib/
  main.dart                 # binding + runApp
  app/
    app_bootstrap.dart      # bootApp, AppBootstrap, MyApp
    app_routes.dart         # GetPage table
  domain/                   # Isar-free models, repository interfaces, start/progress rules
  data/                     # Isar adapters, importer, memory/web, optional HTTP remotes
  common/                   # theme, widgets, route name constants
  features/
    welcome/
    plans/                  # home, preview, editor, import, starters
    workout/                # start, live logger
    progress/               # month tab, session log
```

Routes: `/`, `/home`, `/starters`, `/import`, `/new-plan`, `/plan`, `/day`, `/edit-day`, `/edit-section`, `/session`, `/day-log`, `/session-log`. Month is a tab on `/home`. Live workout is `/session`. Plan and session arguments are **uuids**, not Isar row ids.

---

## Step 5 — Implementation slices

Slices **1–9 are in the running app** (Welcome, import/create, plan/day editors, start/commons/conflict, live logger + 1–5, Month). Slice **10** (harden) is largely in: resume after back, one in-progress session, invalid JSON error, analyze/CI, widget tests. Remaining product gaps:

- **Delete plan** overflow (sessions should stay)
- Auto-start rest, target weight, accounts, suggested next load, reorder/duplicate days
- HTTP sync only when `API_BASE_URL` is set

Historical build order (already shipped):

1. **Isar bootstrap + new models**
2. **Empty home + welcome fork**
3. **JSON import**
4. **Plan preview + day preview from Isar**
5. **Create / edit plan** (rename, add/delete day, common-section editor). Delete-plan overflow still missing.
6. **Start session**
7. **Live logger**
8. **Per-exercise 1–5** (End also offers Keep going)
9. **Month overview**
10. **Harden**

### Workout-first additions (locked with slices 6–8)

The first useful session should not require JSON or a blank plan editor.

- **Beginner defaults.** Bundled programs in `assets/json/beginner-full-body.json` (3 days + abs/mobility) and `beginner-two-day.json` (A/B, no commons). Welcome’s primary button opens `/starters`. One tap writes a real `WorkoutPlan` (`PlanSource.imported`) and lands on home. Installing the same title twice reuses the stored plan.
- **Today card.** Home recommends the next day on the newest startable plan. No history → day 1. After a completed session → the next startable day, wrapping around. If they already completed a session **today**, the card is “Next up” for the following day instead of repeating the same one. The prompt names the first exercise and asks them to log what they did.
- **Start from Today.** Same start flow as day preview (commons sheet, in-progress conflict, live logger). No need to open the plan first.
