---
name: walk-docs-flows
description: Builds and runs the gym app, walks every user-facing flow in docs/, and gives a video as output of each step. Reports bugs as a step to step guideline of how to resolve it, and suggests places the journey can improve so a new design can come from it. Use when the user asks to build and run the app, go through docs flows, QA the user journey, record walkthrough videos, or test Welcome, plans, import, live workout, or Month.
---

# Walk every docs flow

Do not skip this skill to “just run tests.” Widget tests are not a substitute for the recorded journeys.

## Sources of truth

Read these before launching, in this order:

1. `docs/user-journey.md` — the step list to walk and record
2. `docs/product-plan.md` — expected product, UX, and start/live/month rules
3. This skill’s [report-template.md](report-template.md) — required output shape

`README.md` tracks the running app at a high level. For screen copy and the step list, still prefer `docs/user-journey.md` and `docs/product-plan.md`.

`docs/steps-1-4-review.md` is a historical review. Do not skip a journey step because that file says a later slice is unfinished. Judge the running app against the journey and the product plan.

## Build and run

Native Linux desktop only. Web is not a v1 target (Isar 3 / `dart:ffi`).

```bash
flutter pub get
flutter config --enable-linux-desktop
flutter run -d linux
```

Leave the app running after the walk. Do not `pkill -f`. Stop a prior instance only by its PID.

First launch (Welcome) needs an empty local DB. Stop the app, then **execute** (do not rewrite):

```bash
.cursor/skills/walk-docs-flows/scripts/reset-isar.sh
```

Then `flutter run -d linux` again. Welcome is skipped whenever any plan exists.

File import uses the desktop picker (`zenity` is installed in this environment). Sample JSON: `assets/json/plan.json`. Beginner templates live in `assets/json/beginner-full-body.json` and `assets/json/beginner-two-day.json`.

## How to walk

Use the `computerUse` subagent for GUI. Drive the app as a person would: tap, type, submit, navigate. A screenshot of a screen is not a completed step.

Give **videos as output of each step**. One recording per numbered section in `docs/user-journey.md`. Split §2 into three videos (`2a`, `2b`, `2c`).

For each step:

1. `RecordScreen` `START_RECORDING`
2. Exercise the flow end to end
3. `RecordScreen` `SAVE_RECORDING` with a name like `01-welcome`, `02a-beginner-template`
4. Save artifacts under `/opt/cursor/artifacts`
5. Follow the walkthrough-artifacts skill for naming, length, and what “good” looks like

Do not batch unrelated journeys into one video. §8 (full first-week loop) is the one continuous path; still record it as its own video even if pieces appeared in earlier steps.

### Suggested order (state)

| Video | Data setup |
| --- | --- |
| 1 Welcome | `reset-isar.sh`, cold launch |
| 2a Beginner template | still first-run; tap **Start with a beginner plan** |
| 3–7 Home, plan/day, start, live, month | keep the beginner plan; do not reset |
| 8 First-week loop | can be the same install; one continuous recording |
| 2b Create from scratch | reset, then Welcome **Create a plan** (also hit **New** on Plans in a later pass if 2b already used Welcome) |
| 2c Import JSON | from Plans **Import**, or reset and Welcome **Import a plan** |

Hunt regressions on every screen that shares state with the step you just ran (Plans vs Month, Today card vs live session, Continue banner).

## What “pass” means

Match `docs/user-journey.md` plus the locked UX in `docs/product-plan.md` Step 3. Misses that are easy to skip:

- Welcome only when plan count is 0; three actions; later launches go to Plans
- Same beginner title twice reuses the stored plan
- Blank created plan: empty Day 1; Start disabled until a block exists **or** a common section exists
- Invalid JSON: readable error; valid `assets/json/plan.json` preview then save
- Bottom nav on the home shell only
- Commons sheet default **off**; in-progress conflict: Resume / Abandon and start / Cancel
- Live: session is a snapshot; supersets alternate; rest is manual and not saved; rate 1–5 after prescribed sets; all rated → complete; Finish vs Discard
- Month: dots ignore abandoned; trends per `exerciseTitleKey`

## Bugs

If a step fails, is blocked, or disagrees with the docs, report it. Do not silently skip.

Use this heading **verbatim** for the fix section of every bug:

**Step to step guideline of how to resolve it**

Write an ordered list a developer can follow (files, expected vs actual, what to change, how to re-verify). Do not only name the symptom. Do not implement the fix unless the user asked to fix it.

## Journey improvements

If there are places that the journey can improve, suggest them so a new design can come from it.

Frame each item as design input, not a code patch: friction, extra taps, dead ends, missing copy, empty states, unclear next action, or a gap between Welcome / Plans / live / Month. Do not implement a new visual language unless asked.

## Final reply

Fill in [report-template.md](report-template.md). Embed each step’s video with an HTML `<video>` tag whose `src` is the absolute `/opt/cursor/artifacts/…` path. Put bugs and journey suggestions in their template sections. If a step could not be recorded, say why in that step’s row — still walk the rest.
