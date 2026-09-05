# Shared PATH / SDK exports for Patrol and the Android emulator.
# Source this file; do not execute it. Cloud Agent shells often replace the
# image PATH with only the exec-daemon directory, so install/start and login
# profiles re-apply these prefixes on every command.
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/android-sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$ANDROID_SDK_ROOT/avd}"
_home="${HOME:-/home/ubuntu}"
_prefix="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${_home}/.pub-cache/bin:${JAVA_HOME}/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${ANDROID_HOME}/cmdline-tools/latest/bin"
case ":${PATH}:" in
  *:/opt/flutter/bin:*) ;;
  *) export PATH="${_prefix}:${PATH}" ;;
esac
unset _home _prefix
