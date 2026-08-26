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
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        clang \
        cmake \
        curl \
        git \
        libgl1-mesa-dri \
        libgtk-3-dev \
        liblzma-dev \
        libstdc++-14-dev \
        mesa-utils \
        ninja-build \
        pkg-config \
        unzip \
        xdg-user-dirs \
        xz-utils \
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

# Configure and warm the SDK as the runtime user so the tool cache is writable
# and Linux desktop artifacts are pre-downloaded.
USER ubuntu
RUN git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics \
    && flutter config --enable-linux-desktop \
    && flutter precache --linux \
    && flutter doctor -v || true
