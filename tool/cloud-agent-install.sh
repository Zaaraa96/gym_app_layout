#!/usr/bin/env bash
# Idempotent Cloud Agent install: Dart deps + Patrol CLI.
set -euo pipefail

export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/android-sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$ANDROID_SDK_ROOT/avd}"
export PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$HOME/.pub-cache/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

flutter config --no-analytics
flutter config --enable-linux-desktop
if [[ -d "$ANDROID_HOME" ]]; then
  flutter config --android-sdk "$ANDROID_HOME"
fi

flutter pub get --enforce-lockfile
xdg-user-dirs-update

dart pub global activate patrol_cli 4.7.0
patrol --version
patrol doctor || true
