#!/usr/bin/env bash
# Idempotent Cloud Agent install: Dart deps + Patrol CLI.
set -euo pipefail

# shellcheck source=android-env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/android-env.sh"

# Persist PATH for later agent shells that do not inherit Docker ENV PATH.
profile_snippet='[ -f /workspace/tool/android-env.sh ] && . /workspace/tool/android-env.sh'
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  touch "$rc"
  grep -Fqx "$profile_snippet" "$rc" 2>/dev/null || echo "$profile_snippet" >> "$rc"
done

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
