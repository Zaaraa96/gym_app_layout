#!/usr/bin/env bash
# Validate a Git tag against pubspec.yaml for CD.
#
# A release tag must contain the word "version" and equal
# version-<pubspec version>, e.g. pubspec `1.0.0+1` → tag `version-1.0.0+1`.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  tool/check_release_tag.sh <git-tag> [pubspec-path]
  tool/check_release_tag.sh --print-version [pubspec-path]
  tool/check_release_tag.sh --self-test
EOF
  exit 2
}

pubspec_version() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Missing pubspec file: $file" >&2
    return 1
  fi
  local line version
  line="$(grep -E '^version:' "$file" | head -n1 || true)"
  version="$(awk '{print $2}' <<<"$line" | tr -d "\"'")"
  if [[ -z "$version" ]]; then
    echo "Could not read a version: line from $file" >&2
    return 1
  fi
  printf '%s\n' "$version"
}

expected_tag() {
  printf 'version-%s\n' "$1"
}

check_tag() {
  local tag="$1"
  local file="$2"
  if [[ "$tag" != *version* ]]; then
    echo "Tag '$tag' does not contain 'version'." >&2
    echo "Name the tag version-<pubspec version>." >&2
    return 1
  fi
  local version expected
  version="$(pubspec_version "$file")"
  expected="$(expected_tag "$version")"
  if [[ "$tag" != "$expected" ]]; then
    echo "Tag '$tag' does not match $file version '$version'." >&2
    echo "Create a tag named '$expected'." >&2
    return 1
  fi
  echo "Tag '$tag' matches $file version '$version'."
}

fail_check() {
  local tag="$1"
  local file="$2"
  if check_tag "$tag" "$file" >/dev/null 2>&1; then
    echo "Expected tag '$tag' to be rejected for $file" >&2
    return 1
  fi
  return 0
}

self_test() {
  local tmp
  tmp="$(mktemp -d)"
  # Expand now: tmp is local and would be unbound when EXIT runs.
  trap "rm -rf '$tmp'" EXIT

  cat >"$tmp/pubspec.yaml" <<'EOF'
name: fixture
isar_version: &isar_version ^3.1.0+1
version: 1.2.3+4
EOF

  check_tag "version-1.2.3+4" "$tmp/pubspec.yaml" >/dev/null
  fail_check "version-1.2.3" "$tmp/pubspec.yaml"
  fail_check "version-9.9.9+4" "$tmp/pubspec.yaml"
  fail_check "v1.2.3+4" "$tmp/pubspec.yaml"
  fail_check "1.2.3+4" "$tmp/pubspec.yaml"
  fail_check "release-version-1.2.3+4" "$tmp/pubspec.yaml"
  fail_check "version/1.2.3+4" "$tmp/pubspec.yaml"

  local repo_pubspec repo_version
  repo_pubspec="$(cd "$(dirname "$0")/.." && pwd)/pubspec.yaml"
  repo_version="$(pubspec_version "$repo_pubspec")"
  check_tag "$(expected_tag "$repo_version")" "$repo_pubspec" >/dev/null

  echo "check_release_tag self-test passed (pubspec version $repo_version)."
}

case "${1:-}" in
  ""|-h|--help) usage ;;
  --self-test)
    self_test
    ;;
  --print-version)
    pubspec_version "${2:-pubspec.yaml}"
    ;;
  *)
    check_tag "$1" "${2:-pubspec.yaml}"
    ;;
esac
