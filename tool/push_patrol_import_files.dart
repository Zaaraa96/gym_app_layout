#!/usr/bin/env dart
// Copy import fixtures onto the connected Android device for flow 2c.
//
// From the repo root (PowerShell, CMD, Git Bash, macOS, Linux):
//   dart run tool/push_patrol_import_files.dart
//
// Do not run tool/push-patrol-import-files.sh from Windows PowerShell — Windows
// treats .sh as a document and asks which app should open it.

import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    stdout.writeln(
      'Push valid-plan.json and broken.json to the device Downloads folder.\n'
      '\n'
      'Usage (repo root):\n'
      '  dart run tool/push_patrol_import_files.dart\n'
      '\n'
      'Needs a running emulator or phone (`adb devices`).',
    );
    return;
  }

  final root = findRepoRoot();
  final adbPath = findAdb();
  if (adbPath == null) {
    stderr.writeln(
      'adb not found.\n'
      'Install Android platform-tools and add them to PATH, or set '
      'ANDROID_HOME / ANDROID_SDK_ROOT.',
    );
    exit(1);
  }

  await adb(adbPath, ['start-server'], silent: true);

  final listing = await adbCapture(adbPath, ['devices']);
  final attached = listing
      .split(RegExp(r'\r?\n'))
      .skip(1)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('*'))
      .toList();
  final ready = attached.where((line) => line.split(RegExp(r'\s+')).last == 'device');
  if (ready.isEmpty) {
    stderr.writeln(
      'No Android device or emulator is attached.\n'
      'Start the AVD first, then run this again.\n'
      'Check with: adb devices -l',
    );
    if (attached.isNotEmpty) {
      stderr.writeln('adb devices:\n$listing');
    }
    exit(1);
  }

  await adb(adbPath, ['wait-for-device'], silent: true);
  await adb(adbPath, ['root'], ignoreFailure: true, silent: true);
  await adb(adbPath, ['wait-for-device'], silent: true);

  await adb(adbPath, [
    'shell',
    'mkdir',
    '-p',
    '/sdcard/Download',
    '/storage/emulated/0/Download',
    '/data/local/tmp',
  ], silent: true);

  // Drop the old overlapping names (`plan.json` is a suffix of
  // `invalid-plan.json`, which DocumentsUI can wrap onto its own line).
  for (final stale in ['plan.json', 'invalid-plan.json']) {
    await adb(
      adbPath,
      ['shell', 'rm', '-f', '/sdcard/Download/$stale', '/storage/emulated/0/Download/$stale', '/data/local/tmp/$stale'],
      ignoreFailure: true,
      silent: true,
    );
  }

  await copyFixture(
    adbPath,
    File('${root.path}/assets/json/plan.json'),
    'valid-plan.json',
  );
  await copyFixture(
    adbPath,
    File('${root.path}/tool/fixtures/invalid-plan.json'),
    'broken.json',
  );

  // API 29+ ignores MEDIA_SCANNER_SCAN_FILE for many providers. Mount scan
  // makes Downloads list the files in DocumentsUI on the AVD.
  await adb(
    adbPath,
    [
      'shell',
      'am',
      'broadcast',
      '-a',
      'android.intent.action.MEDIA_MOUNTED',
      '-d',
      'file:///sdcard',
    ],
    ignoreFailure: true,
    silent: true,
  );

  stdout.writeln('Pushed valid-plan.json and broken.json to device Downloads');
  await adb(adbPath, [
    'shell',
    'ls',
    '-l',
    '/sdcard/Download',
    '/storage/emulated/0/Download',
    '/data/local/tmp/valid-plan.json',
    '/data/local/tmp/broken.json',
  ], ignoreFailure: true);
}

Future<void> copyFixture(String adbPath, File src, String name) async {
  if (!src.existsSync()) {
    stderr.writeln('Missing fixture: ${src.path}');
    exit(1);
  }
  await adb(adbPath, ['push', src.path, '/data/local/tmp/$name'], silent: true);
  final copied = await adb(
    adbPath,
    ['shell', 'cp', '/data/local/tmp/$name', '/sdcard/Download/$name'],
    ignoreFailure: true,
    silent: true,
  );
  if (copied != 0) {
    await adb(
      adbPath,
      [
        'shell',
        'cp',
        '/data/local/tmp/$name',
        '/storage/emulated/0/Download/$name',
      ],
      silent: true,
    );
  }
  await adb(
    adbPath,
    ['shell', 'chmod', '666', '/sdcard/Download/$name'],
    ignoreFailure: true,
    silent: true,
  );
  await adb(
    adbPath,
    ['shell', 'chmod', '666', '/storage/emulated/0/Download/$name'],
    ignoreFailure: true,
    silent: true,
  );
  await adb(
    adbPath,
    [
      'shell',
      'am',
      'broadcast',
      '-a',
      'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
      '-d',
      'file:///sdcard/Download/$name',
    ],
    ignoreFailure: true,
    silent: true,
  );
}

Directory findRepoRoot() {
  final starts = <Directory>[];
  if (Platform.script.isScheme('file')) {
    starts.add(File.fromUri(Platform.script).parent);
  }
  starts.add(Directory.current);

  for (final start in starts) {
    var dir = start;
    for (var i = 0; i < 8; i++) {
      final pubspec = File('${dir.path}/pubspec.yaml');
      final plan = File('${dir.path}/assets/json/plan.json');
      if (pubspec.existsSync() && plan.existsSync()) {
        return dir;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        break;
      }
      dir = parent;
    }
  }

  stderr.writeln(
    'Run this from the gym_app repo root (the folder with pubspec.yaml).',
  );
  exit(1);
}

String? findAdb() {
  final onPath = lookupOnPath(Platform.isWindows ? 'adb.exe' : 'adb');
  if (onPath != null) {
    return onPath;
  }

  final homes = <String?>[
    Platform.environment['ANDROID_HOME'],
    Platform.environment['ANDROID_SDK_ROOT'],
    if (Platform.isWindows) ...[
      '${Platform.environment['LOCALAPPDATA']}\\Android\\Sdk',
      '${Platform.environment['USERPROFILE']}\\AppData\\Local\\Android\\Sdk',
    ],
    if (Platform.isMacOS) '${Platform.environment['HOME']}/Library/Android/sdk',
    if (Platform.isLinux) ...[
      '${Platform.environment['HOME']}/Android/Sdk',
      '/opt/android-sdk',
    ],
  ];

  for (final home in homes) {
    if (home == null || home.isEmpty) {
      continue;
    }
    final adbFile = File(
      Platform.isWindows
          ? '$home\\platform-tools\\adb.exe'
          : '$home/platform-tools/adb',
    );
    if (adbFile.existsSync()) {
      return adbFile.path;
    }
  }
  return null;
}

String? lookupOnPath(String executable) {
  final path = Platform.environment['PATH'] ?? '';
  final sep = Platform.isWindows ? ';' : ':';
  for (final dir in path.split(sep)) {
    if (dir.isEmpty) {
      continue;
    }
    final candidate = File('$dir${Platform.pathSeparator}$executable');
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }
  return null;
}

Future<int> adb(
  String adbPath,
  List<String> args, {
  bool ignoreFailure = false,
  bool silent = false,
}) async {
  final result = await Process.run(adbPath, args);
  final out = result.stdout.toString();
  final err = result.stderr.toString();
  if (!silent && out.isNotEmpty) {
    stdout.write(out.endsWith('\n') ? out : '$out\n');
  }
  if (result.exitCode != 0 && err.isNotEmpty) {
    stderr.write(err.endsWith('\n') ? err : '$err\n');
  }
  if (!ignoreFailure && result.exitCode != 0) {
    stderr.writeln('adb ${args.join(' ')} failed (${result.exitCode})');
    exit(result.exitCode);
  }
  return result.exitCode;
}

Future<String> adbCapture(String adbPath, List<String> args) async {
  final result = await Process.run(adbPath, args);
  if (result.exitCode != 0) {
    stderr.write(result.stderr.toString());
    stderr.writeln('adb ${args.join(' ')} failed (${result.exitCode})');
    exit(result.exitCode);
  }
  return result.stdout.toString();
}
