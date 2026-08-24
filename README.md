# Gym App

Flutter app for browsing a gym workout plan: days, exercise groups (supersets), reps, and rounds. It is a UI-first prototype with a hardcoded demo plan, GetX navigation, and an unfinished Isar persistence path for creating plans.

**Intended product** (not built yet): import or create a plan, log a live workout offline, rate each exercise 1–5, and see a monthly progress view. The locked plan is [docs/product-plan.md](docs/product-plan.md).

Package name: `gym_app`  
Application ID: `com.zahra.gym_app`

## What it can do today

| Capability | Status |
|---|---|
| Welcome screen with Lottie animation | Working (route exists; app currently starts on the plan) |
| View a 4-day demo plan with photo cards | Working (hardcoded in `main.dart`) |
| Open a day and see exercise groups | Working |
| Open one exercise group (rounds + reps) | Working |
| Pick a photo/video for an exercise and preview it | Working locally; not saved on the plan |
| Create a new plan (title/summary form) | Form UI only; save writes a hardcoded `"test"` plan to Isar |
| Load plans from JSON (`assets/json/plan.json`) | Data file exists; not wired into the UI |
| Persist the full nested plan graph | Model is Isar-ready; no single shared database instance |

The launch route is `/plan`, so you land on the demo plan immediately. Use `/` for the welcome screen.

## User flow

```
Welcome (/)  →  Plan (/plan)  →  Day (/day)  →  Exercise (/exercise)
                     ↑
              New plan (/new-plan)  [not linked from the current screens]
```

1. **Welcome** — Lottie gym animation, short copy, “Let’s get started!” → `/plan`.
2. **Plan** — Collapsing app bar + a card per day. Backgrounds cycle `assets/image/0.png`–`2.png`. Arrow opens that day.
3. **Day** — List of `SingleExerciseWithRound` rows (SVG, exercise names × reps, round badge). Tap a row → `/exercise`.
4. **Exercise** — Same summary row plus an image picker (`ImagePicker.pickMedia`). Chosen media is copied into the app documents directory and shown as a 100×100 preview. It is not attached to the model.
5. **New plan** — Background `assets/image/new.png`, title/summary fields, Save. Save opens Isar, inserts `SinglePlanModel(title: 'test', dayPlans: [])`, and prints the stored title. Field values are ignored.

## Data model

Defined in `lib/features/single_plan/single_plan_model.dart` (Isar collection + embedded types; generated code in `single_plan_model.g.dart`).

```
SinglePlanModel          // @collection, auto-increment id
  title
  dayPlans[]
    SingleDayPlanModel   // @embedded
      title, summary
      exercises[]
        SingleExerciseWithRound   // @embedded  (a round/superset block)
          roundNum
          svgPath                 // e.g. assets/image/upper-body.svg
          exerciseWithRepetitionModels[]
            ExerciseWithRepetitionModel   // @embedded
              title, repetition
```

`assets/json/plan.json` is a richer draft schema (supersets vs singles, `sets`/`times`/`duration`, “basic-plan” vs “common-plan” such as abs and corrective work). That shape is **not** mapped to the Dart model yet.

## Architecture

- **UI:** Flutter Material 3, seed color `Colors.deepPurple`.
- **Navigation:** GetX `GetMaterialApp` named routes. Day and exercise screens receive models via `Get.arguments`.
- **State:** GetX stubs exist (`SinglePlanLogic` / `SinglePlanState` / unused `view.dart`) but the live plan page is a `StatelessWidget` that takes the plan as a constructor argument.
- **Local DB:** Isar 3. Opened ad hoc on the add-plan screen; not initialized in `main()`.
- **Shared widgets:** `AppScaffold` (horizontal padding), `AppText` + shared text styles, `AppElevatedButton`, `AppTextField`.

```
lib/
  main.dart                          # routes + hardcoded demo plan
  common/
    app_theme.dart
    list_of_plan.dart                # unused (commented)
    widgets/
  features/
    welcome_page.dart
    add_plan_page.dart
    single_day_plan_page.dart
    single_exercise_page.dart
    single_exercise_summery_item.dart
    single_plan/
      single_plan_page.dart          # used
      single_plan_model.dart
      view.dart / logic.dart / state.dart   # GetX stubs, unused
```

## Platforms

Configured as a Flutter app with **Android**, **iOS**, and **web**. Camera/gallery usage on the exercise screen needs the usual `image_picker` platform permissions if you ship it (not yet declared in `AndroidManifest.xml` / iOS `Info.plist`).

## Run

Requires Flutter 3.5+ (developed against Flutter 3.44 / Dart 3.12).

```bash
flutter pub get
flutter run
```

Regenerate Isar code after changing the model:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Dependencies

| Package | Role |
|---|---|
| `get` | Routing and (planned) controllers |
| `isar` / `isar_flutter_libs` | Local persistence |
| `isar_generator` + `build_runner` | Isar codegen |
| `lottie` | Welcome animation (`assets/json/gym.json`) |
| `flutter_svg` | Exercise-group icons |
| `image_picker` | Media on the exercise screen |
| `path_provider` | App documents directory |

**Isar is kept on 3.1.x.** The official 3.x line is the last stable API this model uses. Jumping to Isar 4 (or a community fork) would need a migration, not a version bump.

## Known gaps

- Demo plan is constructed in `MyApp`, not loaded from storage or JSON.
- Add-plan form does not bind text fields or navigate after save.
- Duplicate `SinglePlanPage` class in unused `view.dart`.
- Default counter widget test in `test/widget_test.dart` does not match the app.
- Typo in day summaries: `ٖcorrective`.
- TODO in `main.dart`: “add getX for storage”.
