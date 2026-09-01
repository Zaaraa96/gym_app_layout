# Gym app user journey

What a person actually does in the current app (offline, one local user). Screens still store everything in Isar. There is no account.

## 1. First launch — Welcome

The app opens on **Welcome** when no plans exist.

The user sees a gym animation and three choices:

1. **Start with a beginner plan**
2. **Import a plan**
3. **Create a plan**

After any plan is saved, later launches skip Welcome and go to **Plans**.

## 2. Get a plan in

### 2a. Beginner template (typical first run)

1. Tap **Start with a beginner plan**.
2. On **Beginner plans**, pick **Beginner full body** or **Beginner 2-day**.
3. Tap **Use this plan**.
4. The plan is saved locally. The app jumps to **Plans**.

Tapping the same starter twice does not duplicate it (same title is reused).

### 2b. Create from scratch

1. Tap **Create a plan** (Welcome) or **New** (Plans).
2. Enter a **title** (required) and optional **summary**.
3. Tap **Save**.
4. Land on that plan. It starts with one empty **Day 1**. The user must add exercises before a workout can start.

### 2c. Import JSON

1. Tap **Import a plan** (Welcome) or **Import** (Plans).
2. Pick a `.json` file in the v1 shape (`name`, `basic-plan`, optional `common-plan`).
3. Confirm the preview. Invalid JSON is rejected with a readable error.

## 3. Home — Plans tab

Returning users land here.

- **Continue workout** banner if a live session exists. Tap to resume logging.
- **Today** card: next startable day on the newest plan, or “already trained today / next day”.
  - **Start today's workout** or **Start next day**.
- **Your plans** list (title + day count). Tap a row to open the plan.
- Bottom buttons: **Import** and **New**.
- Bottom nav: **Plans** | **Month**.

## 4. Open a plan and a day

1. Tap a plan.
2. See days (and common sections if any). Rename the plan, add a day, or add a common section.
3. Tap a day card → **read-only day preview** (blocks, reps or duration).
4. **Edit day** opens the editor (add/edit/delete blocks, pick exercise media).
5. **Start workout** on the preview starts or resumes that day.

## 5. Start a workout

1. If another day is already live, a dialog asks:
   - **Resume existing**
   - **Abandon and start this day**
   - **Cancel**
2. If the plan has common sections (abs, etc.), **Include today** lets the user turn extras on. They are off unless toggled. **Start** confirms.
3. If the day has no exercises and no commons were included, a snackbar says to add an exercise or turn on a section.
4. The live logger opens.

## 6. Live workout

Copied from the plan at start. Later plan edits do not change this session.

1. Log the **active** exercise:
   - Rep work: optional weight, reps (prefilled), **Log set**.
   - Timed work: **Start timer**, then **Log time** (or log without starting; that stores the prescribed time).
2. **Start rest** / **Reset rest** (stopwatch only; not saved).
3. On a **superset**, prescribed sets alternate between partners. Rating is blocked until both have their prescribed sets.
4. After prescribed sets, extras can still be logged, then rate **1–5** (1 easy · 5 hard). Rating completes that exercise.
5. When every exercise is rated, the session completes automatically.
6. **End** can **Finish workout** (keep a partial log) or **Discard workout** (abandoned; hidden on the month view).
7. After finish: **Workout complete** / “Nice work. What you logged is saved.” then **Done**.
8. Back on Plans: **Continue workout** is gone. If they already trained today, the card becomes **Next up** with **Start next day**.

## 7. Month tab

1. Switch to **Month**.
2. Calendar for the visible month. Dots on days with a non-abandoned session.
3. Prev/next month.
4. Tap a dotted day:
   - One session → that session’s log.
   - Several → list for the day, then pick one.
5. Per-exercise trends for the month (weight, duration, or sets/reps; “felt easier” when load holds and difficulty drops).

## 8. A full first-week loop

1. Welcome → **Beginner full body**.
2. Start **today’s** day from the home card.
3. Include commons if offered, or leave them off.
4. Log prescribed sets, rest as needed, rate each movement 1–5.
5. Land back on Plans; today card moves to the next day.
6. Open the plan, peek at another day, optionally edit.
7. Open **Month** and confirm a dot + trend row for what was logged.

Import is optional. Creating a blank plan is optional and needs exercises before Start works.
