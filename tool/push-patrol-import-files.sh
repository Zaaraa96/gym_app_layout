#!/usr/bin/env bash
# Copy import fixtures onto the connected Android device for flow 2c.
set -euo pipefail

# shellcheck source=android-env.sh
if [[ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/android-env.sh" ]]; then
  # shellcheck disable=SC1091
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/android-env.sh"
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
adb start-server >/dev/null
adb wait-for-device

adb shell mkdir -p /sdcard/Download
adb push "$ROOT/assets/json/plan.json" /sdcard/Download/plan.json
adb push "$ROOT/tool/fixtures/invalid-plan.json" /sdcard/Download/invalid-plan.json

adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
  -d file:///sdcard/Download/plan.json >/dev/null || true
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
  -d file:///sdcard/Download/invalid-plan.json >/dev/null || true

echo "Pushed plan.json and invalid-plan.json to /sdcard/Download"
