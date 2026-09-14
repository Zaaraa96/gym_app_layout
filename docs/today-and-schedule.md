# Today and schedule

Product rules for **which plans feed Today**, **how a plan advances**, **rest**, and the **horizontal Today list**. Implementing agents treat this as the source of truth for schedule behavior. Cross-links: [product-plan.md](product-plan.md), [user-journey.md](user-journey.md), [plan-builder-stepper.md](plan-builder-stepper.md).

## Why this exists

Today currently picks the **newest** startable **active** plan and always wraps day order. That confuses “builder finished” with “I am following this plan,” and it invents a silent **Repeat** loop with no rest and no weekday map.

## Locked decisions

- **Two schedule modes only:** `once` | `week`. There is **no** separate Repeat mode. Wanting the plan to recur means choosing **Week schedule**.
- **Choose schedule while making the plan** (Review & create, before **Finish plan**). Edit later on Plan preview → Schedule.
- **On schedule** (bool) is separate from `draft` / `active`. Only on-schedule active plans feed Today.
- Multi-plan Today: **horizontal list** of every due item (workout and rest tiles).
- Rest is first-class (see below).
- One simple reminder: toggle + time; fires only when ≥1 **workout** is due.

## Status vs schedule (two axes)

| Concept | Meaning |
| --- | --- |
| `draft` / `active` | Build readiness. Drafts cannot start. Unchanged. |
| `onSchedule` | Participates in Today. User-controlled. Default **on** when finishing or installing a starter. |

Turning **On schedule** off parks a finished plan in the library without deleting it.

## Schedule modes (not three)

### Run once (`once`)

Ordered days (workout and optional Rest). Advance to the next incomplete day after each completed session for that plan. After the last day is done → plan is **finished** (off Today, or show Completed on Plan preview). Does **not** wrap.

### Week schedule (`week`)

User maps each plan day to one or more weekdays. The map **repeats every calendar week**. That is the only recurring mode.

- A weekday with a mapped **workout** day → that workout is due.
- A weekday with a mapped **Rest** day → Rest tile for that plan.
- A weekday with **no** mapping → rest for that plan (no day row required).

Do **not** also offer “Repeat: after last day, start over.” That duplicates Week schedule badly and hides rest.

## Rest

1. **Explicit Rest days** in the day list (`kind: rest`, no blocks). Used in `once` sequences and optionally on `week` maps.
2. **Empty weekdays** on `week` (unmapped) → rest for that plan.
3. **Today Rest tile** when the due item is rest, or when every on-schedule plan has no workout due.

Actions on a Rest tile: **Rested** (marks the rest slot done for `once` advancement / ack for `week`) and optional **Train anyway** (does not skip the slot unless they mark rest done).

Reminders: **workout due only**, never rest-only.

## Where the user sets this

### While creating (required)

On **Review & create**, before **Finish plan**:

1. **On schedule** toggle (default on).
2. **How you follow this plan:** **Run once** | **Week schedule** (exactly one).
3. If **Week schedule:** weekday map for each day (Finish stays disabled until every workout day has ≥1 weekday). Empty weekdays are rest.

Starters: land as **On schedule + Week schedule** with a sensible default map (e.g. Beginner 2-day: Day A Mon+Thu, Day B Tue+Fri — or Mon/Thu only; document the chosen defaults in product-plan). No silent infinite wrap without a calendar.

### After create (edit)

Plan preview → **Schedule** section: same controls + **Add rest day**. Progress block lives on the same preview (see below).

```mermaid
flowchart TD
  review[Review and create]
  choose[Run once or Week schedule]
  finish[Finish plan]
  today[Today horizontal list]
  preview[Plan preview Schedule]
  review --> choose --> finish --> today
  preview -->|"edit later"| today
```

## Today decision maker

Inputs: on-schedule active plans + completed sessions + schedule mode + week map + clock.

Per plan, compute today’s item (or none):

- **`once`:** next incomplete day in order; if none left → not due (finished).
- **`week`:** days mapped to today’s weekday; if none → that plan contributes rest implicitly (no workout tile).

Aggregate:

| Situation | UI |
| --- | --- |
| 0 on-schedule plans | Banner: Import / New / Beginner — no fake Today |
| ≥1 on-schedule, 0 workout due | Horizontal Rest tile(s) (or one aggregated Rest card) |
| ≥1 workout due | Horizontal list: one card per due workout (+ rest tiles if another plan is resting) |

One in-progress session rule unchanged (conflict dialog on start).

## Per-plan progress + charts

On Plan preview (below Schedule / days):

- Completion for current `once` run, or adherence for current week on `week`
- Last trained
- Plan-scoped exercise trends + simple charts (weight over sessions; weekly volume/session count)

Month tab stays the **cross-plan** calendar.

## Notifications

- Settings: one **Workout reminder** toggle + time (default 07:00 local)
- Local notification only
- Fire only if Today has ≥1 **workout** due

## Data fields (add to product-plan)

On `WorkoutPlan` (names illustrative):

- `onSchedule: bool`
- `scheduleMode: once | week`
- `weekdayMap: List<{ dayId, weekdays: List<int> }>` (used when `week`; Mon=1…Sun=7 or app convention)
- Optional reminder prefs are **app-level**, not per plan: `reminderEnabled`, `reminderTimeLocal`

On `PlanDay`:

- `kind: workout | rest`

Migration: existing active plans → `onSchedule: true`, `scheduleMode: week`, map days in order onto Mon… until days run out (or product picks starter-like defaults); do **not** migrate to a silent Repeat enum.

## Implementation phases (follow-on agent)

1. **Model + migration** — fields above; migrate active plans to on-schedule + week defaults
2. **Today engine** — multi-due list; rest vs workout; empty banner; drop newest-active wrap
3. **Schedule on Review + Plan preview** — once|week, map, onSchedule, Add rest day
4. **Per-plan Progress + charts**
5. **Reminder** — workout-due only
6. **Tests + journey / patrol** updates

## Out of scope

- Multiple concurrent live sessions
- Smart load / target weight
- Per-day reminder times
- Accounts / sync changes
