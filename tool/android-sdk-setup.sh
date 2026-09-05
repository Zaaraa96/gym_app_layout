#!/usr/bin/env bash
# Install Android SDK cmdline-tools, platforms, emulator, and the patrol_pixel
# AVD. Idempotent. Safe to run as root in the image; AVD lives under
# $ANDROID_SDK_ROOT/avd so it is not tied to the installing user's home.
set -euo pipefail

# shellcheck source=android-env.sh
if [[ -f /etc/profile.d/gym-dev.sh ]]; then
  # shellcheck disable=SC1091
  source /etc/profile.d/gym-dev.sh
else
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/android-env.sh"
fi

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/android-sdk}"
export ANDROID_SDK_ROOT
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$ANDROID_SDK_ROOT/avd}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export PATH="$JAVA_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"

CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
AVD_NAME="${AVD_NAME:-patrol_pixel}"
SYSIMAGE="system-images;android-34;google_apis;x86_64"

mkdir -p "$ANDROID_SDK_ROOT" "$ANDROID_AVD_HOME"

if [[ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]]; then
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/cmdline-tools.zip" "$CMDLINE_URL"
  unzip -q "$tmp/cmdline-tools.zip" -d "$tmp"
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  mv "$tmp/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  rm -rf "$tmp"
fi

yes | sdkmanager --licenses >/dev/null || true

# Flutter 3.44.x doctor wants platform 36 and still checks for Build-Tools 28.0.3.
sdkmanager --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-34" \
  "platforms;android-35" \
  "platforms;android-36" \
  "build-tools;28.0.3" \
  "build-tools;34.0.0" \
  "build-tools;35.0.0" \
  "build-tools;36.0.0" \
  "$SYSIMAGE"

if ! avdmanager list avd 2>/dev/null | grep -q "Name: ${AVD_NAME}"; then
  echo "no" | avdmanager create avd \
    --name "$AVD_NAME" \
    --package "$SYSIMAGE" \
    --device pixel_6 \
    --path "$ANDROID_AVD_HOME/${AVD_NAME}.avd" \
    --force
fi

avd_config="$ANDROID_AVD_HOME/${AVD_NAME}.avd/config.ini"
if [[ -f "$avd_config" ]]; then
  grep -q '^hw.keyboard=' "$avd_config" || echo 'hw.keyboard=yes' >> "$avd_config"
  if grep -q '^hw.ramSize=' "$avd_config"; then
    sed -i 's/^hw.ramSize=.*/hw.ramSize=2048/' "$avd_config"
  else
    echo 'hw.ramSize=2048' >> "$avd_config"
  fi
fi
