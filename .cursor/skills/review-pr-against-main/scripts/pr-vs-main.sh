#!/usr/bin/env bash
# Print the given PR (or branch) as a merge-base diff against origin/main.
# Usage: pr-vs-main.sh [PR_NUMBER|BRANCH]
# Execute this script; do not rewrite it per review.

set -euo pipefail

retry() {
  local attempt=1
  local delay=4
  while true; do
    if "$@"; then
      return 0
    fi
    if (( attempt >= 4 )); then
      echo "error: command failed after ${attempt} tries: $*" >&2
      return 1
    fi
    sleep "$delay"
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done
}

git rev-parse --is-inside-work-tree >/dev/null

retry git fetch origin main

TARGET="${1:-}"
PR_JSON=""
HEAD_REF=""

if [[ -z "$TARGET" ]]; then
  if PR_JSON="$(gh pr view --json number,title,url,baseRefName,headRefName,headRefOid,commits 2>/dev/null)"; then
    TARGET="$(printf '%s' "$PR_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["number"])')"
  else
    HEAD_REF="$(git rev-parse HEAD)"
  fi
fi

if [[ -z "$HEAD_REF" ]]; then
  if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
    PR_JSON="$(gh pr view "$TARGET" --json number,title,url,baseRefName,headRefName,headRefOid,commits)"
    HEAD_REF="$(printf '%s' "$PR_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["headRefOid"])')"
    retry git fetch origin "pull/${TARGET}/head"
  else
    retry git fetch origin "$TARGET"
    HEAD_REF="$(git rev-parse "origin/${TARGET}" 2>/dev/null || git rev-parse "$TARGET")"
    PR_JSON="$(gh pr view "$TARGET" --json number,title,url,baseRefName,headRefName,headRefOid,commits 2>/dev/null || true)"
  fi
fi

BASE="$(git rev-parse origin/main)"
MERGE_BASE="$(git merge-base "$BASE" "$HEAD_REF")"

echo "=== PR vs origin/main ==="
if [[ -n "$PR_JSON" ]]; then
  printf '%s' "$PR_JSON" | python3 -c "
import json, sys
pr = json.load(sys.stdin)
print('PR: #%s %s' % (pr['number'], pr['title']))
print('URL: %s' % pr['url'])
print('GitHub base: %s' % pr['baseRefName'])
print('Head ref: %s' % pr['headRefName'])
print('Commits: %s' % len(pr.get('commits') or []))
"
else
  echo "PR: (none — reviewing HEAD vs origin/main)"
fi
echo "origin/main: $BASE"
echo "head:        $HEAD_REF"
echo "merge-base:  $MERGE_BASE"
if [[ "$(git rev-parse --abbrev-ref HEAD)" != "HEAD" ]]; then
  echo "local branch: $(git rev-parse --abbrev-ref HEAD)  (review still uses the SHAs above, not this checkout)"
fi
echo

echo "=== files vs origin/main ==="
git diff --stat "${MERGE_BASE}...${HEAD_REF}"
echo
echo "=== name-status vs origin/main ==="
git diff --name-status "${MERGE_BASE}...${HEAD_REF}"
echo
echo "=== patch vs origin/main ==="
git diff "${MERGE_BASE}...${HEAD_REF}"
