// Shared Patrol robot for gym_app device flows.
// The Android runner already launched main(). Do not pump MyApp again.
// Welcome's Lottie never settles — avoid pumpAndSettle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

export 'package:patrol/patrol.dart';

const gymPatrolConfig = PatrolTesterConfig(
  printLogs: true,
  settlePolicy: SettlePolicy.trySettle,
  settleTimeout: Duration(seconds: 2),
  existsTimeout: Duration(seconds: 20),
  visibleTimeout: Duration(seconds: 20),
);

const gymPatrolTimeout = Timeout(Duration(minutes: 6));

void gymPatrolTest(
  String description,
  Future<void> Function(PatrolIntegrationTester $, GymApp gym) body,
) {
  patrolTest(
    description,
    config: gymPatrolConfig,
    timeout: gymPatrolTimeout,
    ($) async {
      final gym = GymApp($);
      await gym.waitUntilAppReady();
      await body($, gym);
    },
  );
}

class GymApp {
  GymApp(this.$);

  final PatrolIntegrationTester $;

  static const fullBodyTitle = 'Beginner full body';
  static const twoDayTitle = 'Beginner 2-day';
  static const day1Title = 'Day 1 — Squat and push';
  static const day2Title = 'Day 2 — Hinge and pull';
  static const dayATitle = 'Day A — Squat and push';

  Future<void> waitUntilAppReady() async {
    final deadline = DateTime.now().add(const Duration(seconds: 40));
    while (DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 200));
      if (_welcomeVisible || _onPlansHome) return;
    }
    fail('App did not reach Welcome or Plans home');
  }

  bool get _welcomeVisible =>
      $('Start with a beginner plan').exists && $('Import a plan').exists;

  bool get _onPlansHome =>
      $(const Key('today-card')).exists ||
      $('No plans yet. Start with a beginner template, import one, or create your first.')
          .exists;

  Future<void> tapText(
    String text, {
    SettlePolicy settle = SettlePolicy.trySettle,
  }) async {
    await _tap($(text), settle: settle);
  }

  Future<void> tapKey(
    String key, {
    SettlePolicy settle = SettlePolicy.trySettle,
  }) async {
    await _tap($(Key(key)), settle: settle);
  }

  Future<void> _tap(
    dynamic matching, {
    required SettlePolicy settle,
  }) async {
    final finder = matching is PatrolFinder ? matching : $(matching);
    if (!finder.visible) {
      try {
        await finder.scrollTo(settlePolicy: SettlePolicy.noSettle);
      } catch (_) {
        await $.tester.ensureVisible(finder);
        await $.pump(const Duration(milliseconds: 200));
      }
    }
    await finder.tap(settlePolicy: settle);
    await $.pump(const Duration(milliseconds: 250));
  }

  Future<void> expectVisible(dynamic matching) async {
    await $(matching).waitUntilVisible();
  }

  Future<void> pumpQuiet([Duration d = const Duration(milliseconds: 400)]) =>
      $.pump(d);

  Future<void> back() async {
    await $.tester.pageBack();
    await $.pump(const Duration(milliseconds: 400));
  }

  Future<void> waitForWelcome() async {
    await $('Start with a beginner plan').waitUntilVisible(
      timeout: const Duration(seconds: 30),
    );
    expect($('Import a plan'), findsOneWidget);
    expect($('Create a plan'), findsOneWidget);
  }

  Future<void> openBeginnerFromWelcome() async {
    await tapText(
      'Start with a beginner plan',
      settle: SettlePolicy.noSettle,
    );
    await pumpQuiet(const Duration(milliseconds: 600));
    await expectVisible('Beginner plans');
  }

  Future<void> useStarterFullBody() async {
    await tapKey('use-starter-beginner-full-body');
    await $(const Key('today-card')).waitUntilVisible();
  }

  Future<void> useStarterTwoDay() async {
    await tapKey('use-starter-beginner-two-day');
    await $(const Key('today-card')).waitUntilVisible();
  }

  Future<void> installFullBodyFromWelcome() async {
    await waitForWelcome();
    await openBeginnerFromWelcome();
    await expectVisible(fullBodyTitle);
    await expectVisible(twoDayTitle);
    await useStarterFullBody();
    await expectPlansHomeWith(fullBodyTitle);
  }

  Future<void> expectPlansHomeWith(String planTitle) async {
    await $(const Key('today-card')).waitUntilVisible();
    expect($('Your plans'), findsOneWidget);
    expect($(planTitle), findsWidgets);
    expect($('Import'), findsOneWidget);
    expect($('New'), findsOneWidget);
  }

  Future<void> openStartersFromHome() async {
    await tapKey('open-starters');
    await expectVisible('Beginner plans');
  }

  Future<void> openPlan(String title) async {
    await tapText(title);
    await expectVisible('Common sections');
  }

  Future<void> openDayByTitle(String title) async {
    await tapText(title);
    await expectVisible('Edit day');
  }

  Future<void> startTodaysWorkout() async {
    await tapText("Start today's workout");
  }

  Future<void> confirmCommonsOff() async {
    await $('Include today').waitUntilVisible();
    expect($('These extras are off unless you turn them on.'), findsOneWidget);
    await tapKey('confirm-include');
    await $('Log what you did on this set.').waitUntilVisible();
  }

  Future<void> startTodayLeavingCommonsOff() async {
    await startTodaysWorkout();
    await confirmCommonsOff();
  }

  Future<void> tapLogSet() async {
    await _tap($('Log set'), settle: SettlePolicy.trySettle);
  }

  Future<void> tapLogTime() async {
    await _tap($('Log time'), settle: SettlePolicy.trySettle);
  }

  Future<void> tapStartRest() async => tapText('Start rest');

  Future<void> tapResetRest() async => tapText('Reset rest');

  Future<void> rate(int n) async {
    await tapKey('rate-$n');
  }

  /// Prefer rating when the 1–5 row is on screen so extras are not logged.
  Future<void> finishLiveWorkout({int difficulty = 3}) async {
    final deadline = DateTime.now().add(const Duration(minutes: 4));
    while (DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 250));
      if ($('Workout complete').exists) return;
      if ($(Key('rate-$difficulty')).exists) {
        await _tap($(Key('rate-$difficulty')), settle: SettlePolicy.trySettle);
        continue;
      }
      if ($('Log time').exists) {
        await tapLogTime();
        continue;
      }
      if ($('Log set').exists) {
        await tapLogSet();
        continue;
      }
    }
    fail('Live workout did not reach Workout complete');
  }

  Future<void> tapDone() async => tapText('Done');

  Future<void> openMonthTab() async {
    await _tap(find.byIcon(Icons.calendar_month_outlined), settle: SettlePolicy.trySettle);
    await $(const Key('month-calendar')).waitUntilVisible();
  }

  Future<void> openPlansTab() async {
    await _tap(find.byIcon(Icons.fitness_center_outlined), settle: SettlePolicy.trySettle);
  }

  int get utcDayNumber => DateTime.now().toUtc().day;

  Future<void> expectMonthDotForToday() async {
    await $(Key('month-dot-$utcDayNumber')).waitUntilVisible();
  }

  Future<void> openTodayOnMonth() async {
    await tapKey('month-day-$utcDayNumber');
  }

  Future<void> deleteOpenPlan() async {
    await _tap(find.byTooltip('More'), settle: SettlePolicy.trySettle);
    await tapKey('delete-plan');
    await tapKey('confirm-delete-plan');
    await pumpQuiet(const Duration(milliseconds: 800));
  }

  Future<void> createPlan({required String title, String summary = ''}) async {
    await tapText(
      'Create a plan',
      settle: SettlePolicy.noSettle,
    );
    await pumpQuiet(const Duration(milliseconds: 600));
    await expectVisible('New Plan');
    if (title.isNotEmpty) {
      await $(TextFormField).at(0).enterText(title);
    }
    if (summary.isNotEmpty) {
      await $(TextFormField).at(1).enterText(summary);
    }
    await tapText('save');
  }

  Future<void> addNamedExercise(String name) async {
    await tapText('Edit day');
    await expectVisible('No exercises yet. Add the first movement.');
    await tapText('Add exercise');
    await $('Add exercise').waitUntilVisible();
    await $(TextFormField).first.enterText(name);
    await tapText('Save exercise');
    await tapText('Save');
    await expectVisible('Start workout');
  }

  Future<void> addEmptyCommonSection(String title) async {
    await tapText('Add section');
    await $(TextFormField).enterText(title);
    await tapText('Save section');
    await pumpQuiet();
    if ($('No exercises yet. Add the first movement.').exists) {
      await back();
    }
  }

  Future<void> endAndDiscard() async {
    await tapKey('end-workout');
    await tapKey('discard-workout');
    await pumpQuiet(const Duration(milliseconds: 600));
  }

  Future<void> endAndFinish() async {
    await tapKey('end-workout');
    await tapKey('finish-workout');
    await $('Workout complete').waitUntilVisible();
  }

  Future<void> backgroundAndReopen() async {
    await $.platform.mobile.pressHome();
    await Future<void>.delayed(const Duration(seconds: 1));
    await $.platform.mobile.openApp();
    await pumpQuiet(const Duration(seconds: 1));
  }

  Future<void> dismissPermissionIfAny() async {
    if (await $.platform.mobile.isPermissionDialogVisible(
      timeout: const Duration(seconds: 2),
    )) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }
  }

  Future<bool> nativeTapText(
    String text, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      await $.platform.android.tap(
        AndroidSelector(text: text),
        timeout: timeout,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// DocumentsUI on the API 34 emulator: Downloads → filename.
  Future<void> pickJsonFromDownloads(String fileName) async {
    await dismissPermissionIfAny();
    await nativeTapText('Allow');
    if (!await nativeTapText(fileName, timeout: const Duration(seconds: 4))) {
      await nativeTapText('Show roots');
      final inDownloads = await nativeTapText('Downloads') ||
          await nativeTapText('Download');
      if (!inDownloads) {
        fail('Native picker had no Downloads folder');
      }
      final picked = await nativeTapText(fileName);
      if (!picked) {
        fail('Native picker did not show $fileName in Downloads');
      }
    }
    await nativeTapText('SELECT');
    await nativeTapText('Select');
    await nativeTapText('Open');
    await pumpQuiet(const Duration(milliseconds: 800));
  }
}
