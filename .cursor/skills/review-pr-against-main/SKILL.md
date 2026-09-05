---
name: review-pr-against-main
description: Reviews the PR given against the main branch. Fetches origin/main, diffs only that merge-base, and writes a structured review. Use when reviewing a pull request, when the user says review the PR given against the main branch, or when checking a branch versus main.
---

# Review the PR given against the main branch

Always review **the given PR vs `origin/main`**. Never treat the current checkout, uncommitted files, or the PR’s own parent commits as the review base unless the user names a different base.

## Identify the PR

Resolve the target in this order:

1. Explicit PR number or URL in the user message
2. `gh pr view` for the current branch
3. The only open PR targeting `main` (if there is exactly one)
4. `HEAD` vs `origin/main` when no PR exists — say so in the review

Do not switch the working tree onto the PR branch unless tests must run on that code.

## Collect the diff vs main

**Execute** (do not reimplement) the helper:

```bash
.cursor/skills/review-pr-against-main/scripts/pr-vs-main.sh [PR_NUMBER|BRANCH]
```

That script fetches `origin/main` and the PR head, then prints merge-base, files, and the patch.

Review **only** that patch. Ignore files that are identical to `origin/main`.

If the PR’s GitHub `baseRefName` is not `main`, still compare to `origin/main` and note the mismatch.

## Read before judging

- PR title, body, and commit list (`gh pr view <n>`)
- `docs/product-plan.md` (product / data / UX / architecture source of truth)
- `docs/user-journey.md` (what the screens must still do)
- Touched tests and `test/helpers/isar_core.dart` when widget tests change

`README.md` is a high-level map of the running app. Do not fail a PR for README drift unless the change made it newly wrong.

## Product and architecture

Check the given PR against [checklist.md](checklist.md). Locked product rules that still apply on `main`:

- Plan is prescription; session is what happened. Sessions snapshot titles and prescriptions.
- Common sections default **off** at start. Super-sets **alternate** sets.
- Offline is normal. Do not make HTTP the UI source of truth.
- Keep **Isar 3.1.x**. Do not bump to Isar 4.
- `kIsWeb` belongs at composition (`bootApp` / adapters), not in pages.
- Repository **interfaces** stay Isar-free. Pages do not import `isar_*_repository.dart`.

`docs/product-plan.md` Step 4 still describes `lib/data/models`. If the PR is a documented domain/data/features split with architecture tests, judge the new arrows, not the old tree.

## Tests to run

On the PR head (or after checking it out in a worktree), run what the patch can break:

```bash
flutter analyze
flutter test --concurrency=1
```

Use `--concurrency=1` for Isar host tests. If only docs/skills changed, skip Flutter tests and say so.

Widget-test traps:

- Do **not** `pumpAndSettle` on Welcome — Lottie never stops.
- Use `settleApp` from `test/helpers/isar_core.dart` after GetX route changes (~400ms + Isar yield).
- Default test surface is 800px; AppBar actions miss taps until the transition finishes.

## Write the review

Use this template. Be concrete: file, behavior, vs-main impact. No drive-by nits on untouched code.

```markdown
# PR review vs main

**PR:** #<n> — <title>
**Base:** origin/main (`<sha>`)  **Head:** `<sha>`
**Merge-base:** `<sha>`
**Scope:** <N files, +A/−D vs main>

## Verdict
Approve | Request changes | Comment only
One sentence: what this PR does relative to main, and whether it is safe to merge.

## Summary vs main
- What landed that main does not have
- What this does **not** do (call out PR “out of scope” claims if the diff contradicts them)

## Findings
### Critical (must fix before merge)
- …

### Suggestions
- …

### Notes
- …

## Checks
- [ ] Diff used is merge-base vs origin/main
- [ ] Product rules still hold (or an intentional, tested exception is named)
- [ ] Architecture arrows / import tests still hold
- [ ] Tests run (command + result) or skipped with reason
```

Empty sections: write `None.` Do not invent issues to fill the template.

## After the review

- Post on GitHub only if the user asked to comment or review on the PR.
- Do not merge, approve via the GitHub review API, or enable auto-merge unless asked.
- If the user asked for a skill plus a live review, write the review in the reply using the template above.
