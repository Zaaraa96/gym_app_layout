# Review checklist vs main

Use after the merge-base diff is in hand. Skip items the patch does not touch.

## Product (`docs/product-plan.md`)

- JSON import **and** in-app create/edit still both work.
- Difficulty is **1–5 per exercise**, not once per day.
- Single local user; offline is the normal path.
- `common-plan` is extra named sections on the same program, not a second plan.
- Start enabled when the day has a block **or** the plan has common sections.
- Start sheet only when commons exist; switches default **off**.
- Live: persist each set; back leaves `inProgress`; Finish → `completed`; Discard → `abandoned`.
- Super-set prescribed phase alternates A1, B1, A2… Rating waits until every log in the block has its prescribed sets.
- Month ignores `abandoned`. Progress key is `exerciseTitleKey = title.trim().toLowerCase()`.
- Installing the same beginner-plan title twice reuses the stored plan.

## Data / identity

- Two collections: plan and session. Nested types stay embeds. `SetLog` is not its own collection.
- Session stores a snapshot so later plan edits do not rewrite history.
- Product identity for routes / `Get.arguments` should be plan/session **uuid** when the PR is on that path. `byId(int)` is a local adapter only.
- Keep Isar schema ids JS-safe if web compile still matters (`tool/patch_isar_js_ints.py`).

## Architecture arrows

On current `main`, interfaces live under `lib/data/` and stay Isar-free; only `isar_*_repository.dart` (and `main.dart`) import the concrete Isar classes.

If the PR introduces `lib/domain/` + `lib/app/`:

- `lib/domain/` must not import `isar`, `http`, `get`, or `lib/features/`.
- `lib/features/` must not import `isar_*.dart` or `http_remote_*.dart`.
- Pages take injected ports / constructors. Do not add `Get.find` inside widgets.
- HTTP remotes feed sync at the edge. They are not registered as `PlanRepository`.
- `kIsWeb` only at boot / adapters.

Confirm `test/data/architecture_imports_test.dart` still matches the tree the PR ships.

## UX / journeys (`docs/user-journey.md`)

- Welcome when plan count is 0; otherwise `/home`.
- Bottom nav on the **home shell only**.
- Continue-workout banner, Today card, Import / New on home.
- In-progress conflict: resume / abandon-and-start / cancel.

## Tests and test helpers

- New product rules have tests next to existing ones (`test/data/`, `test/features/`).
- Widget tests that change routes use `settleApp`, not `pumpAndSettle` on Welcome.
- Host tests that open Isar call `ensureIsarCore()` first.
- Run `flutter analyze` and `flutter test --concurrency=1` on the PR head when Dart changed.

## Out of scope unless the PR claims it

Photos as a v1 feature, accounts, auto-start rest, target-weight UI, Isar 4, HTTP as the live UI store.
