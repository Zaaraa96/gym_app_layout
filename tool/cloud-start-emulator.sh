#!/usr/bin/env bash
# Start the patrol_pixel AVD if no Android device is connected. Idempotent.
# Software emulation (no /dev/kvm) can take ~10 minutes to reach boot_completed.
set -euo pipefail

# shellcheck source=android-env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/android-env.sh"

# Install is not rerun on pods that boot from an environment snapshot.
if command -v flutter >/dev/null 2>&1; then
  flutter config --no-enable-web >/dev/null || true
fi

AVD_NAME="${AVD_NAME:-patrol_pixel}"
LOG="${EMULATOR_LOG:-/tmp/cursor-patrol-emulator.log}"
BOOT_TIMEOUT_SEC="${EMULATOR_BOOT_TIMEOUT_SEC:-900}"

if [[ ! -x "$ANDROID_HOME/platform-tools/adb" ]]; then
  echo "Android SDK is not installed at $ANDROID_HOME" >&2
  exit 1
fi

if [[ -e /dev/kvm ]] && [[ ! -w /dev/kvm ]]; then
  sudo -n chmod 666 /dev/kvm 2>/dev/null || true
fi

adb start-server >/dev/null

wait_for_boot() {
  local deadline=$((SECONDS + BOOT_TIMEOUT_SEC))
  adb wait-for-device
  while (( SECONDS < deadline )); do
    booted="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    if [[ "$booted" == "1" ]]; then
      echo "Emulator booted."
      adb devices
      return 0
    fi
    sleep 2
  done
  echo "Emulator did not reach boot_completed in ${BOOT_TIMEOUT_SEC}s. Last log lines:" >&2
  tail -n 50 "$LOG" >&2 || true
  return 1
}

if adb devices | awk 'NR>1 && $2=="device" { found=1 } END { exit found ? 0 : 1 }'; then
  echo "Android device already listed; waiting for boot_completed if needed."
  wait_for_boot
  exit $?
fi

if ! command -v emulator >/dev/null 2>&1; then
  echo "emulator binary not on PATH" >&2
  exit 1
fi

accel_args=(-accel on)
if [[ ! -e /dev/kvm ]] || [[ ! -w /dev/kvm ]]; then
  echo "KVM is not usable; starting emulator with software acceleration (slow boot)."
  accel_args=(-accel off)
fi

echo "Starting AVD $AVD_NAME..."
nohup emulator -avd "$AVD_NAME" \
  -no-window \
  -no-audio \
  -no-boot-anim \
  -gpu swiftshader_indirect \
  "${accel_args[@]}" \
  -netdelay none \
  -netspeed full \
  >"$LOG" 2>&1 &
echo $! > /tmp/cursor-patrol-emulator.pid

wait_for_boot
