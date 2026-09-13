# Live logger comfort pass

Design for the live workout screen: fewer mid-set decisions, calmer rest, clearer orientation, softer rating, companion tone, safer leave.

## What overlaps (combine these)

The seven asks share four surfaces. Build **modes + one voice**, not seven separate features.

| Mode / surface | Owns |
| --- | --- |
| **Work mode** | Steppers + bodyweight hint; GIF/still; progress line + “your turn”; companion logging copy |
| **Rest mode** | Auto-start after save; full-screen calm clock; hide weight/reps; “next up” line |
| **Rate moment** | Human 1–5 labels; Skip for now; same companion voice |
| **Done beat → end** | Short quote from the last rating, then the ended screen with a concrete log line |

Shared across modes:

- **Progress math** feeds the quiet `N of M · ~T left` line and rest “next up”.
- **Movement identity** (media + title) lives in the work header; rest only names the next movement.
- **Companion copy** is one string set (not one-off rewrites).
- **Safe leave** is one strip under the app bar + Finish as the primary End action.

Explicitly **out of this pass**: prefill weight from a *previous session* (still the biggest comfort gap, still deferred). In-session last-set weight prefill stays.

## Screen modes

### Work

```
[←] Day title                         End
Leaving keeps this workout — Continue on Plans.

3 of 8 · ~12 min left

[ GIF / still for active movement ]

Your turn: Kang squat
then Leg extension          ← only when block has a partner

This block
  Kang squat      3 × 12 · 1/3   ← active louder
  Leg extension   3 × 12 · 1/3

Done with this set? Save it.
  [−] [ Weight ] [+]    [−] [ Reps ] [+]
  Bodyweight is fine — leave weight blank.   ← when weight empty
  [ Save set ]
```

- No competing rest strip in work mode.
- Steppers: weight ±2.5 kg (empty + starts at 2.5); reps ±1 (floor 1). Fields stay editable.
- Media: catalog still when title matches (form GIF stays on Exercises detail); else no media chrome.

### Rest (takes over after Save set / Log time)

```
3 of 8 · ~12 min left

0:45

Breathe.
Next: Leg extension

[ Skip ]
```

- Auto-starts when a set/time is saved.
- Weight/reps (and rate UI) are hidden while resting.
- Rest is a **countdown** (default 60s) with **+15s** and **Skip**. **Skip** ends rest early and returns to work (or rate). Hitting 0 auto-ends rest.
- Manual Start rest is gone from the default path; Reset is not needed on this surface.

### Rate

After prescribed sets for the block:

- Prompt: **How did that feel?**
- Buttons labeled: **Easy · Light · Solid · Hard · Brutal** (values 1–5).
- **Skip for now** completes the movement (`completedAt` set, `difficulty` left null) so the session can advance without homework.
- Rating or skip both count as “done” for block advance and session completion.

### Done beat → ended

When the last movement is rated or skipped:

1. Brief beat (not instant end state): quote from the last rating, e.g. Easy → “That felt easy — nice.”; mid → “Nice. Session done.”; Brutal → “Brutal. And you finished.”; skip → “Saved. Session done.”
2. Then **Workout complete** with **Nice work…** plus one concrete line from the log (`3 sets of Kang squat saved`).
3. **Done** leaves as today.

Manual **Finish workout** from End skips the beat and goes straight to the ended view (partial is fine).

## End / leave

- Strip always visible while live: **Leaving keeps this workout — Continue on Plans.**
- End sheet: **Finish workout** primary; **Discard workout** secondary/destructive; **Keep going**.
- Back / system back unchanged: leave `inProgress`.

## Progress heuristic

- `N of M` = current movement ordinal among session logs (completed count + 1 while live work remains).
- `~T left` = same work+rest assumptions as day cards (3s/rep, 60s between sets, 30s between blocks), applied to **remaining** prescribed sets on incomplete logs. Quiet estimate, not a clock.

## Controller / domain notes

- `ExerciseLog.isComplete` → `completedAt != null` (rated **or** skipped).
- After `logSet` / `logTime`, auto-`startRest()` instead of clearing to stopped.
- Last completion sets a `sessionDoneBeat` flag; UI acknowledges → `finish()`.
- Rest remains UI-only (not persisted).

## Copy map (companion)

| Old | New |
| --- | --- |
| Log what you did on this set. | Done with this set? Save it. |
| Log set | Save set |
| empty = bodyweight | Bodyweight is fine — leave weight blank. |
| How hard was that? 1 easy · 5 hard | How did that feel? + labeled digits |
| Start rest / Resting… / Reset rest | Rest takeover + Skip |
| (after log, nothing) | Next: {title} on rest; optional work-mode next line |
| Nice work. What you logged is saved. | Keep + `{n} sets of {title} saved` |


## Immersive shell (visual + flow)

- Deep-purple Material stays app-wide; live has no brand mark.
- Segmented progress, large exercise media, **This block** always visible, sticky save dock.
- Leave helper stays: “Leaving keeps this workout — continue on Plans.”
- Rate is a full takeover (Easy→Brutal / Skip for now / Log an extra set).
- Rest is a dark full-screen countdown with +15s / Skip and next-up preview.
