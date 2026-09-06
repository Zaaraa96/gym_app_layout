# Gym app user journey

What a person actually does in the current app (offline, one local user). Screens store everything in Isar. There is no account. Optional HTTP sync exists only if the binary is built with `API_BASE_URL`; the normal app does not use the network.

Welcome, Plans, live workout, and Month all exist and are wired. Judge this file against the running app, not against older slice notes.

## 1. First launch — Welcome

The app opens on **Welcome** when no plans exist. Later launches skip Welcome whenever any plan is stored and go to **Plans**.

On-screen copy:

- Title: **Welcome To the Amazing Gym app**
- Subtitle: **Start with a plan. Grab a beginner template, import one you already have, or build it here.**
- A looping gym Lottie animation

Three full-width actions, no bottom nav:

1. **Start with a beginner plan**
2. **Import a plan**
3. **Create a plan**

## 2. Get a plan in

### 2a. Beginner template (typical first run)

1. Tap **Start with a beginner plan** (Welcome, or empty Plans) or **Beginner** (Plans, when at least one plan already exists).
2. On **Beginner plans** (“Start with a plan you can do this week. You can edit every exercise later.”), pick:
   - **Beginner full body** (badge **Recommended**) — three days plus abs/mobility commons
   - **Beginner 2-day** — A/B, no commons
3. Tap **Use this plan**.
4. The plan is saved locally. The app jumps to **Plans** (Today card + Your plans). It does **not** open the plan preview.

Tapping the same starter twice does not duplicate it (same title is reused). After the first save, **Beginner** on Plans reopens the same picker so a second template can still be added.

### 2b. Create from scratch

1. Tap **Create a plan** (Welcome) or **New** (Plans).
2. On **New Plan**, enter a **title** (required) and optional **summary** (used as Day 1’s summary). Empty title shows **Add a title before saving**. The confirm control is labeled **save**.
3. Land on that plan’s preview. It starts with one empty **Day 1**. Common sections are listed even when empty, with **Add section**.
4. Open Day 1: **No exercises on this day yet.** **Start workout** is disabled until the day has a block **or** the plan has a common section.

### 2c. Import JSON

1. Tap **Import a plan** (Welcome) or **Import** (Plans).
2. Pick a `.json` file in the v1 shape (`name`, `basic-plan`, optional `common-plan`). Linux desktop needs a file-dialog helper (`zenity`, `qarma`, or `kdialog`).
3. Invalid JSON stays on the current screen with a snackbar, for example: **This file is not valid JSON. Remove trailing commas or other syntax errors and try again.**
4. Valid files open **Import preview**: file name, plan title, expandable days (block summaries), common-section chips, **Save plan** / **Cancel**.
5. **Save plan** writes the plan and opens **that plan’s preview** (not Plans). Back returns toward home.

Checked-in sample: `assets/json/plan.json` (`plan 1`, one day, abs + corrective).

## 3. Home — Plans tab

Returning users land here. Bottom nav (**Plans** | **Month**) is on this shell only.

- **Continue workout** banner if a live session exists (title **Continue workout**, subtitle is the day name). Tap to resume logging. Commons are not asked again.
- **Today** card: the next startable day on the **newest** startable plan (`updatedAt`). A blank created plan does not steal the card; an imported plan with exercises does.
  - No completed session yet: headline **Today: {day}**, prompt **Start with {first exercise}, then log what you did.**, button **Start today's workout**.
  - Already completed a session today: headline **Next up: {day}**, prompt **You already trained today…**, button **Start next day**.
- **Your plans** list (title + “1 day” / “N days”). Newest first. Tap a row to open the plan.
- Bottom buttons when plans exist: **Import**, **New**, and **Beginner** (reopens starter templates). **Beginner** is not on the empty-home row; that state uses a single **Start with a beginner plan** action instead.

Deleting the last plan (overflow on plan preview) lands on empty home: **No plans yet. Start with a beginner template, import one, or create your first.** plus **Start with a beginner plan**. Logged sessions still show on **Month**, and an in-progress session still shows **Continue workout**.

## 4. Open a plan and a day

1. Tap a plan.
2. Plan preview (no bottom nav):
   - Photo day cards (`assets/image/0–2.png`).
   - App bar: back, title, **Rename plan** (pencil), **Add day**, overflow **More** → **Delete plan**.
   - Confirm: **Delete this plan?** / **Workouts already logged stay on Month.** **Cancel** or **Delete**. Delete returns to Plans.
   - **Common sections** heading, **Add section**, then chips (tap to edit, delete on the chip) or empty copy: **Optional extras like abs. Include them when you start a day.**
   - Each day card: title, optional summary, first-block summary, exercise count, **Delete day**.
   - FAB **Add day** when at least one day exists.
3. Tap a day card → **read-only day preview** (SVG, names × reps or duration, set badge; supersets on one row). Copy **Common sections can be included when you start.** when the plan has sections.
4. **Edit day** opens the editor (day title/summary, add/edit/delete blocks, pick bundled SVG or gallery media). Back without saving destructive edits is safe.
5. **Start workout** on the preview starts or resumes that day. Disabled when the day has no blocks and the plan has no common sections.

## 5. Start a workout

Same flow from the Today card or from day preview.

1. If another **different** day is already live, a dialog:
   - Title **A workout is already in progress**
   - **Resume existing** | **Abandon and start this day** | **Cancel**
   Same plan + same day resumes with no new sheet.
2. If the plan has common sections, **Include today**:
   - **These extras are off unless you turn them on.**
   - One switch per section, **default off**
   - **Cancel** / **Start**
3. If the day has no exercises and no commons were included, a snackbar: **Turn on a section or add an exercise first.**
4. The live logger opens.

## 6. Live workout

Copied from the plan at start. Later plan edits do not change this session. App-bar back leaves the session **in progress** (Continue banner on home).

1. Header names the **active** exercise and set: `{title}  ·  set 1 of 3` (or `set N  ·  extra` after prescribed sets). Copy: **Log what you did on this set.**
2. Log the active exercise:
   - Rep work: optional **Weight (kg)** (`empty = bodyweight`), **Reps** (prefilled), **Log set**.
   - Timed work: countdown, **Start timer**, then **Log time** (or log without starting; that stores the prescribed time).
3. **This block** lists partners with `3 × 10 · 0/3`. On a **superset**, prescribed sets alternate. Rating is blocked until both have their prescribed sets.
4. **Start rest** / **Reset rest** (stopwatch only; not saved). Rest does not auto-start.
5. After prescribed sets, extras can still be logged, then rate **1–5** inline (**How hard was that? 1 easy · 5 hard**). Rating completes that exercise (★n) and moves on.
6. When every exercise is rated, the session completes automatically.
7. **End** (not back) opens:
   - **Finish workout** — keep a partial log (`completed`)
   - **Discard workout** — abandoned; hidden on the month view
   - **Keep going**
8. After finish: **Workout complete** / **Nice work. What you logged is saved.** then **Done** (pops back to the screen that opened live).
9. On Plans: **Continue workout** is gone. If they already trained today, the card is **Next up** with **Start next day**.

## 7. Month tab

1. Switch to **Month** (bottom nav stays).
2. Calendar for the visible month, prev/next. Dots on days with a non-abandoned session. Empty month: calendar with no dots and **No workouts this month.**
3. Tap a dotted day:
   - One session → that session’s read-only log (plan title, day, status, sets, ratings).
   - Several → list for the day (oldest first), then pick one.
4. Tap a day **without** a dot → **No workouts this day.**
5. **This month** lists per-exercise trends (`exerciseTitleKey`): primary metric (weight, duration, or reps), delta vs first session in the month when there are two or more, optional **felt easier**. Rows expand to per-session numbers.

## 8. A full first-week loop

1. Welcome → **Beginner full body**.
2. Start **today’s** day from the home card.
3. Include commons if offered, or leave them off.
4. Log prescribed sets, rest as needed, rate each movement 1–5 (or **Finish workout** on a partial log).
5. Land back on Plans; today card moves to the next day.
6. Open the plan, peek at another day, optionally edit.
7. Open **Month** and confirm a dot + trend row for what was logged.

Import is optional. Creating a blank plan is optional and needs exercises (or a common section) before Start works.
