# Gym app user journey

What a person actually does in the current app (offline, one local user). Screens store everything in Isar. There is no account. Optional HTTP sync exists only if the binary is built with `API_BASE_URL`; the normal app does not use the network.

Welcome, Plans, live workout, and Month all exist and are wired. Judge this file against the running app, not against older slice notes.

## 1. First launch — Welcome

The app opens on **Welcome** when no plans exist. Later launches skip Welcome whenever any plan is stored — including a draft — and go to **Plans**.

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
   - **Beginner full body** (badge **Recommended**) — three training days plus abs and mobility, imported as extra days
   - **Beginner 2-day** — A/B
3. Tap **Use this plan**.
4. The plan is saved locally. The app jumps to **Plans** (Today card + Your plans). It does **not** open the plan preview.

Tapping the same starter twice does not duplicate it (same title is reused). After the first save, **Beginner** on Plans reopens the same picker so a second template can still be added.

### 2b. Create from scratch

1. Tap **Create a plan** (Welcome) or **New** (Plans).
2. A draft is created immediately. The screen is **Create plan**, a vertical stepper: Plan details, Day 1, Review & create.
3. Plan details: **Plan name** (required), optional description (120 chars), optional goals. **CONTINUE** stays on details until the name is filled.
4. Each day has one **Add exercise** action. It opens a full-screen editor where the user chooses **Single exercise** or **Superset**, then commits with **ADD EXERCISE** / **ADD SUPERSET**. **Add another day** lives in **Review & create** with **Finish plan**; tapping it inserts a day and opens that day step.
5. Back or **EXIT FOR NOW** returns to Plans. The row shows a **Draft** badge with **Resume** / **Delete**. Empty names list as **Untitled plan**.
6. **Finish plan** is disabled until every day has a valid block. After finish, the active plan preview opens. **Start workout** is disabled until that day has a block.

### 2c. Import JSON

1. Tap **Import a plan** (Welcome) or **Import** (Plans).
2. Pick a `.json` file in the v1 shape (`name`, `basic-plan`, optional `common-plan`). Linux desktop needs a file-dialog helper (`zenity`, `qarma`, or `kdialog`).
3. Invalid JSON stays on the current screen with a snackbar, for example: **This file is not valid JSON. Remove trailing commas or other syntax errors and try again.**
4. Valid files open **Import preview**: file name, plan title, expandable days (block summaries). Legacy `common-plan` sections become regular days and are explained as **Former common sections**. **Save plan** / **Cancel**.
5. **Save plan** writes the plan and opens **that plan’s preview** (not Plans). Back returns toward home.

Checked-in sample: `assets/json/plan.json` (`plan 1`, one training day plus abs and corrective imported as extra days).

## 3. Home — Plans tab

Returning users land here. Bottom nav (**Plans** | **Month**) is on this shell only.

- **Continue workout** banner if a live session exists (title **Continue workout**, subtitle is the day name). Tap to resume logging.
- **Today** card: the next startable day on the **newest** startable **active** plan (`updatedAt`). Drafts never appear here. A blank created plan does not steal the card; an imported plan with exercises does.
  - No completed session yet: headline **Today: {day}**, prompt **Start with {first exercise}, then log what you did.**, button **Start today's workout**.
  - Already completed a session today: headline **Next up: {day}**, prompt **You already trained today…**, button **Start next day**.
- **Your plans** list (title + “1 day” / “N days”). Newest first. Tap a row to open the plan. Drafts show a **Draft** badge with **Resume** / **Delete**. Empty names list as **Untitled plan**.
- Bottom buttons when plans exist: **Import**, **New**, and **Beginner** (reopens starter templates). **Beginner** is not on the empty-home row; that state uses a single **Start with a beginner plan** action instead.

Deleting the last plan (overflow on plan preview) lands on empty home: **No plans yet. Start with a beginner template, import one, or create your first.** plus **Start with a beginner plan**. Logged sessions still show on **Month**, and an in-progress session still shows **Continue workout**.

## 4. Open a plan and a day

1. Tap a plan.
2. Plan preview (no bottom nav):
   - Photo day cards (`assets/image/0–2.png`).
   - App bar: back, title, **Rename plan** (pencil), **Add day**, overflow **More** → **Delete plan**.
   - Confirm: **Delete this plan?** / **Workouts already logged stay on Month.** **Cancel** or **Delete**. Delete returns to Plans.
   - Each day card: title, optional summary, first-block summary, exercise count, **Delete day**.
   - FAB **Add day** when at least one day exists.
3. Tap a day card → **read-only day preview** (SVG, names × reps or duration, set badge; supersets on one row).
4. **Edit day** opens the same day layout as Create plan (day name, summary, block cards with edit/delete/reorder, Add exercise). List delete asks **Remove this exercise from the day?** then saves immediately.
5. **Start workout** on the preview starts or resumes that day. Disabled when the day has no blocks or the plan is still a draft.

## 5. Start a workout

Same flow from the Today card or from day preview.

1. If another **different** day is already live, a dialog:
   - Title **A workout is already in progress**
   - **Resume existing** | **Abandon and start this day** | **Cancel**
   Same plan + same day resumes with no new sheet.
2. If the day has no exercises, a snackbar: **Add an exercise first.**
3. The live logger opens.

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
3. Log prescribed sets, rest as needed, rate each movement 1–5 (or **Finish workout** on a partial log).
4. Land back on Plans; today card moves to the next day.
5. Open the plan, peek at another day, optionally edit.
6. Open **Month** and confirm a dot + trend row for what was logged.

Import is optional. Creating a plan from scratch uses the stepper builder; **Start workout** needs at least one exercise on that day.
