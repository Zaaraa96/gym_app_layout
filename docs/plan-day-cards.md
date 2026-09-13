# Plan day cards

Status: A/B hybrid shipped. Body-map fills are deferred.

Plan preview (`plan_page.dart`) shows one card per training day. The old cycling photos (`assets/image/0–2.png`) are gone. The card answers: what is this day, which muscles, how long, and (when we have art) what the movements look like.

## Now — flat info, plus rotating stills

Default is the quiet info card (idea A):

- Day title
- Optional focus line: `PlanDay.summary` if set, otherwise a cluster from target areas (`Push`, `Pull`, `Legs`, `Core`, `Shoulders`, `Full body`, or `Mixed`). A title that already names the session (`Day 1 — Squat and push`) does not get a second derived line.
- Target-area chips from stored `targetAreaIds`, with catalog auto-fill when a title matches a bundled exercise and nothing is stored. More than three chips collapse to `+N`.
- Estimated duration (`~N min`) and volume (`1 exercise · 3 sets` or `4 exercises`)
- **Delete day** and tap-to-open day preview

Logic lives in `lib/features/plans/day_card_summary.dart`. Duration is an estimate, not a clock: work from sets × reps/duration, plus assumed 60s rest between sets and 30s between blocks. Live rest is a UI-only countdown (auto-starts after save; +15s / Skip) and is not stored.

### Thumbnails (idea B) only when assets exist

If any movement on the day has catalog or stored media (not the generic `upper-body.svg` fallback), the card shows those stills on the right.

- One asset: static thumbnail
- Several distinct assets: fade through them every 3 seconds
- Custom / unmatched names with no gallery media: no thumbnail — the card stays A

Rotation pauses while another route covers Plan preview so widget tests that `pumpAndSettle` an editor above it can finish.

## Later — body-map fills (idea C)

Do not implement this in the current slice. Come back when we want the muscle picture, not before.

### Why it waits

`targetAreaIds` is already a body-map taxonomy (`chest`, `quads`, `abs`, …) and Review already shows those labels as chips. There is no region-fill artwork yet. `assets/image/upper-body.svg` is a single silhouette, not per-muscle paths.

### What to build

1. Front and back SVGs whose path/group ids match the catalog in `lib/domain/plan_catalog.dart` (`chest`, `triceps`, `biceps`, `front-shoulders`, `side-shoulders`, `rear-shoulders`, `upper-traps`, `forearms`, `lats`, `upper-back`, `quads`, `glutes`, `hamstrings`, `calves`, `abs`, `core`, `hips`, `full-body`).
2. A small widget that takes `dayCardTargetAreaIds(day)` and fills those regions with the theme primary; unselected regions stay muted.
3. Place it on the **right side of the existing A card**, next to or instead of the rotating stills — do not replace chips or the estimate. Chips stay for names, overflow, and `full-body`.
4. Keep A as the fallback when a day has no target areas.

Reuse the same ids the exercise editor already stores. Do not add a second muscle vocabulary.
