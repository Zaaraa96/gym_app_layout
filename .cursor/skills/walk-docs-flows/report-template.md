# Docs flow walkthrough

**App:** gym_app (`flutter run -d linux`)
**Docs:** `docs/user-journey.md` + `docs/product-plan.md`
**Build:** `<command + result>`

## Videos

Give videos as output of each step. One row per journey section.

| Step | Result | Video |
| --- | --- | --- |
| 1 Welcome | Pass / Fail / Blocked | `<video src="/opt/cursor/artifacts/01-welcome.mp4" controls></video>` |
| 2a Beginner template | | |
| 2b Create from scratch | | |
| 2c Import JSON | | |
| 3 Plans tab | | |
| 4 Open a plan and a day | | |
| 5 Start a workout | | |
| 6 Live workout | | |
| 7 Month tab | | |
| 8 Full first-week loop | | |

Replace the example `src` with the real artifact path for that step. If a step has no video, write why in **Result**.

## Step notes

For each step: one or two sentences of what you did and what the app did. Call out copy, empty states, and any mismatch with the docs.

## Bugs

None.

Or one block per bug:

```markdown
### <short title>
**Where:** step <n> / <screen>
**What happened:**
**Expected (from docs):**

**Step to step guideline of how to resolve it**
1. …
2. …
3. Re-verify: repeat the recorded step and confirm <observable>.
```

## Journey improvements

If there are places that the journey can improve, suggest them so a new design can come from it. None.

Or:

```markdown
### <short title>
**Where:** step <n> / <screen>
**Friction:** what the person hits today
**Suggestion:** what a new design could do instead
**Why a new design:** what that change would unlock (fewer taps, clearer next action, less dead-end, better empty state)
```

Do not mix bugs (broken vs docs) with improvements (docs-correct but painful).
