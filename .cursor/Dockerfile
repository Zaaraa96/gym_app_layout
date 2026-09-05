# Development image for the gym_app Flutter project.
#
# Flutter web is not a supported run target here: the app depends on Isar 3,
# which uses dart:ffi and 64-bit integer literals that dart2js cannot compile.
# The app therefore runs on the Linux desktop embedder, whose native toolchain
# and Isar native libraries are installed below.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# System packages:
# - build/toolchain for the Flutter Linux desktop embedder (clang, cmake, ninja,
#   pkg-config, GTK3, liblzma, matching libstdc++ dev for clang-18)
# - Mesa/GL so the GTK window can render (software rendering via llvmpipe)
# - xdg-user-dirs so path_provider can resolve the documents directory at runtime
# - git/curl/xz-utils to fetch and manage the Flutter SDK
# Extra packages:
# - OpenJDK 17 for Patrol / Android Gradle
# - zenity for the Linux file picker
# - sudo so start can chmod /dev/kvm when the device GID is not the image kvm group
# - X11/Pulse/NSS so the headless Android emulator can start
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        clang \
        cmake \
        curl \
        git \
        libasound2t64 \
        libgl1 \
        libgl1-mesa-dri \
        libgtk-3-dev \
        liblzma-dev \
        libnss3 \
        libpulse0 \
        libstdc++-14-dev \
        libx11-6 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxtst6 \
        libxcb1 \
        mesa-utils \
        ninja-build \
        openjdk-17-jdk-headless \
        pkg-config \
        sudo \
        unzip \
        xdg-user-dirs \
        xz-utils \
        zenity \
    && getent group kvm >/dev/null || groupadd -r kvm \
    && usermod -aG kvm ubuntu \
    && printf '%s\n' 'ubuntu ALL=(root) NOPASSWD: /usr/bin/chmod 666 /dev/kvm, /bin/chmod 666 /dev/kvm' \
        > /etc/sudoers.d/kvm \
    && chmod 440 /etc/sudoers.d/kvm \
    && rm -rf /var/lib/apt/lists/*

# Pin the Flutter SDK to the version the project was developed against
# (Flutter 3.44.9 / Dart 3.12.2, per the README).
ARG FLUTTER_VERSION=3.44.9
RUN curl -fsSL -o /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && tar -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && chown -R ubuntu:ubuntu /opt/flutter

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
ENV ANDROID_SDK_ROOT="/opt/android-sdk"
ENV ANDROID_HOME="/opt/android-sdk"
ENV ANDROID_AVD_HOME="/opt/android-sdk/avd"
ENV PATH="${JAVA_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}"
# Agent shells often replace PATH; BASH_ENV / ENV re-apply tool prefixes.
COPY tool/android-env.sh /etc/profile.d/gym-dev.sh
ENV BASH_ENV="/etc/profile.d/gym-dev.sh"
ENV ENV="/etc/profile.d/gym-dev.sh"

# Android SDK + AVD for Patrol. Context is the repository root.
COPY tool/android-sdk-setup.sh /tmp/android-sdk-setup.sh
RUN chmod +x /etc/profile.d/gym-dev.sh /tmp/android-sdk-setup.sh \
    && /tmp/android-sdk-setup.sh \
    && chown -R ubuntu:ubuntu /opt/android-sdk

# Configure and warm the SDK as the runtime user so the tool cache is writable
# and Linux desktop artifacts are pre-downloaded.
USER ubuntu
ENV PATH="/home/ubuntu/.pub-cache/bin:${PATH}"
RUN printf '%s\n' '[ -f /etc/profile.d/gym-dev.sh ] && . /etc/profile.d/gym-dev.sh' \
        >> /home/ubuntu/.bashrc \
    && printf '%s\n' '[ -f /etc/profile.d/gym-dev.sh ] && . /etc/profile.d/gym-dev.sh' \
        >> /home/ubuntu/.profile
RUN git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics \
    && flutter config --enable-linux-desktop \
    && flutter config --no-enable-web \
    && flutter config --android-sdk /opt/android-sdk \
    && flutter precache --linux \
    && flutter precache --android \
    && dart pub global activate patrol_cli 4.7.0 \
    && flutter doctor -v || true
