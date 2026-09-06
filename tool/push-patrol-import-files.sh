#!/usr/bin/env bash
# Copy import fixtures onto the connected Android device for flow 2c.
#
# Windows PowerShell/CMD cannot run this file — Windows treats .sh as a
# document and asks which app should open it. From the repo root use:
#   dart run tool/push_patrol_import_files.dart
#   .\tool\push-patrol-import-files.ps1
set -euo pipefail

# shellcheck source=android-env.sh
if [[ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/android-env.sh" ]]; then
  # shellcheck disable=SC1091
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/android-env.sh"
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if command -v dart >/dev/null 2>&1; then
  exec dart run tool/push_patrol_import_files.dart "$@"
fi

echo "dart not found; using adb directly. Prefer: dart run tool/push_patrol_import_files.dart" >&2

adb start-server >/dev/null
if ! adb devices | awk 'NR>1 && $2=="device" {found=1} END {exit !found}'; then
  echo "No Android device or emulator is attached." >&2
  echo "Start the AVD first, then run this again." >&2
  echo "Check with: adb devices -l" >&2
  exit 1
fi
adb wait-for-device

adb root >/dev/null 2>&1 || true
adb wait-for-device

# API 34 scoped storage often rejects a direct push to /sdcard/Download.
# Stage in /data/local/tmp, then copy as root/shell into Downloads.
adb shell mkdir -p /sdcard/Download /storage/emulated/0/Download /data/local/tmp

copy_fixture() {
  local src="$1"
  local name="$2"
  adb push "$src" "/data/local/tmp/$name" >/dev/null
  if ! adb shell cp "/data/local/tmp/$name" "/sdcard/Download/$name" 2>/dev/null; then
    adb shell cp "/data/local/tmp/$name" "/storage/emulated/0/Download/$name"
  fi
  adb shell chmod 666 "/sdcard/Download/$name" 2>/dev/null || true
  adb shell chmod 666 "/storage/emulated/0/Download/$name" 2>/dev/null || true
  adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
    -d "file:///sdcard/Download/$name" >/dev/null || true
}

copy_fixture "$ROOT/assets/json/plan.json" valid-plan.json
copy_fixture "$ROOT/tool/fixtures/invalid-plan.json" broken.json

echo "Pushed valid-plan.json and broken.json to device Downloads"
adb shell ls -l /sdcard/Download /storage/emulated/0/Download /data/local/tmp/*.json 2>/dev/null || true
