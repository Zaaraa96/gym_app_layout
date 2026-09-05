#!/usr/bin/env bash
# Start the patrol_pixel AVD if no Android device is connected. Idempotent.
set -euo pipefail

export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/android-sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$ANDROID_SDK_ROOT/avd}"
export PATH="/opt/flutter/bin:$HOME/.pub-cache/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

AVD_NAME="${AVD_NAME:-patrol_pixel}"
LOG="${EMULATOR_LOG:-/tmp/cursor-patrol-emulator.log}"

if [[ ! -x "$ANDROID_HOME/platform-tools/adb" ]]; then
  echo "Android SDK is not installed at $ANDROID_HOME" >&2
  exit 1
fi

if [[ -e /dev/kvm ]] && [[ ! -w /dev/kvm ]]; then
  sudo -n chmod 666 /dev/kvm 2>/dev/null || true
fi

adb start-server >/dev/null

if adb devices | awk 'NR>1 && $2=="device" { found=1 } END { exit found ? 0 : 1 }'; then
  echo "Android device already connected."
  adb devices
  exit 0
fi

if ! command -v emulator >/dev/null 2>&1; then
  echo "emulator binary not on PATH" >&2
  exit 1
fi

accel_args=(-accel on)
if [[ ! -e /dev/kvm ]] || [[ ! -w /dev/kvm ]]; then
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

adb wait-for-device

for _ in $(seq 1 90); do
  booted="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
  if [[ "$booted" == "1" ]]; then
    echo "Emulator booted."
    adb devices
    exit 0
  fi
  sleep 2
done

echo "Emulator did not boot in time. Last log lines:" >&2
tail -n 50 "$LOG" >&2 || true
exit 1
