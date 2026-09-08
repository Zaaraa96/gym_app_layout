// Shared Patrol robot for gym_app device flows.
// The Android runner already launched main(). Do not pump MyApp again.
// Welcome's Lottie never settles — avoid pumpAndSettle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/app/app_bootstrap.dart';
import 'package:gym_app/features/plans/native_file_label.dart';
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

  /// Import preview used to show the file name. Native lookups stay
  /// package-scoped so picker rows do not collide with in-app copy.
  static const _appPackage = 'com.zahra.gym_app';

  static const fullBodyTitle = 'Beginner full body';
  static const twoDayTitle = 'Beginner 2-day';
  static const day1Title = 'Day 1 — Squat and push';
  static const day2Title = 'Day 2 — Hinge and pull';
  static const dayATitle = 'Day A — Squat and push';

  Future<void> waitUntilAppReady() async {
    // Patrol's tester tree is empty until the test pumps the app. Do not
    // pumpAndSettle: Welcome's Lottie never stops.
    await $.pumpWidget(const AppBootstrap());
    await $.pump(const Duration(milliseconds: 100));
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
    final arrow = find.byIcon(Icons.arrow_back);
    if ($(arrow).visible) {
      await _tap(arrow, settle: SettlePolicy.trySettle);
      return;
    }
    try {
      await $.platform.android.pressBack();
    } catch (_) {
      await $.tester.pageBack();
    }
    await $.pump(const Duration(milliseconds: 400));
  }

  Future<void> returnToPlansHome() async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 200));
      if ($(const Key('today-card')).exists || $('Your plans').exists) {
        return;
      }
      if ($('No plans yet. Start with a beginner template, import one, or create your first.')
          .exists) {
        return;
      }
      await back();
    }
    fail('Did not return to Plans home');
  }

  Future<void> enterAddExerciseTitle(String name) async {
    final field = find.byKey(const Key('exercise-name-0'));
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline) && field.evaluate().isEmpty) {
      await $.pump(const Duration(milliseconds: 200));
    }
    await $.tester.enterText(field, name);
    await $.pump(const Duration(milliseconds: 200));
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
    await expectVisible('Add day');
  }

  Future<void> openDayByTitle(String title) async {
    await tapText(title);
    await expectVisible('Edit day');
  }

  Future<void> startTodaysWorkout() async {
    await tapText("Start today's workout");
  }

  /// Live logger is a snapshot; there is no Include-today sheet.
  Future<void> awaitLiveLogger() async {
    await $('Log what you did on this set.').waitUntilVisible();
    expect($('Include today'), findsNothing);
  }

  Future<void> startTodaysWorkoutFromHome() async {
    await startTodaysWorkout();
    await awaitLiveLogger();
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
  ///
  /// [expectSupersetAlternate] / [expectTimedWork] cover Day 1 of Beginner
  /// full body (Glute bridge + Bird dog, then timed Plank).
  Future<void> finishLiveWorkout({
    int difficulty = 3,
    bool expectSupersetAlternate = false,
    bool expectTimedWork = false,
  }) async {
    var sawAlternate = false;
    var sawTimed = false;
    final deadline = DateTime.now().add(const Duration(minutes: 4));
    while (DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 250));
      if ($('Workout complete').exists) {
        if (expectSupersetAlternate) {
          expect(
            sawAlternate,
            isTrue,
            reason: 'Did not see Glute bridge set 1 alternate to Bird dog',
          );
        }
        if (expectTimedWork) {
          expect(sawTimed, isTrue, reason: 'Did not see timed Plank / Log time');
        }
        return;
      }
      if ($(Key('rate-$difficulty')).exists) {
        await _tap($(Key('rate-$difficulty')), settle: SettlePolicy.trySettle);
        continue;
      }
      if (expectSupersetAlternate &&
          !sawAlternate &&
          $('Glute bridge  ·  set 1 of 3').exists &&
          $('Log set').exists) {
        await tapLogSet();
        await expectVisible('Bird dog  ·  set 1 of 3');
        sawAlternate = true;
        continue;
      }
      if ($('Log time').exists) {
        if (expectTimedWork && !sawTimed) {
          expect($('Start timer'), findsOneWidget);
          expect($('Plank'), findsWidgets);
        }
        sawTimed = true;
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

  Future<void> tapDone() async {
    await tapText('Done');
    await returnToPlansHome();
  }

  Future<void> openMonthTab() async {
    await _tap(find.byIcon(Icons.calendar_month_outlined), settle: SettlePolicy.trySettle);
    await $(const Key('month-calendar')).waitUntilVisible();
  }

  Future<void> openExercisesTab() async {
    await _tap(find.byIcon(Icons.directions_run_outlined), settle: SettlePolicy.trySettle);
    await $(const Key('exercises-tab')).waitUntilVisible();
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
    await expectVisible('Create plan');
    await expectVisible('Plan details');
    if (title.isNotEmpty) {
      await $(const Key('plan-name-field')).enterText(title);
    }
    if (summary.isNotEmpty) {
      await $(const Key('plan-description-field')).enterText(summary);
    }
    await tapKey('continue-plan-details');
  }

  Future<void> commitExerciseEditor() async {
    await tapKey('exercise-editor-commit');
  }

  Future<void> addExerciseInBuilder(String name) async {
    await tapText('Add exercise');
    await enterAddExerciseTitle(name);
    await commitExerciseEditor();
  }

  Future<void> openReviewStep() async {
    await tapKey('step-review');
    await expectVisible('CREATE PLAN');
  }

  Future<void> expectCreatePlanDisabled() async {
    await expectVisible('CREATE PLAN');
    final create = $.tester.widget<FilledButton>(
      find.byKey(const Key('create-plan')),
    );
    expect(create.onPressed, isNull);
  }

  Future<void> expectStartWorkoutDisabled() async {
    await expectVisible('Start workout');
    final start = $.tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Start workout'),
    );
    expect(start.onPressed, isNull);
  }

  Future<void> expectPlanPreview(String title) async {
    await expectVisible('Add day');
    expect($(title), findsWidgets);
  }

  Future<void> addNamedExercise(String name) async {
    await tapText('Edit day');
    await expectVisible('No exercises yet. Add the first movement.');
    await tapText('Add exercise');
    await enterAddExerciseTitle(name);
    await commitExerciseEditor();
    await tapText('Save');
    await expectVisible('Start workout');
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

  /// DocumentsUI / SAF: the filename TextView is visible and "tappable" but
  /// not the click target. ACTION_OPEN_DOCUMENT only finishes when the list
  /// row (or the icon to the left of the title) is clicked. Success is the
  /// picker closing, not UiAutomator reporting a tap.
  Future<void> pickJsonFromDownloads(String fileName) async {
    await dismissPermissionIfAny();
    await nativeTapText('Allow', timeout: const Duration(milliseconds: 800));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    var found = await _waitForNativeFile(fileName);
    if (!found) {
      await nativeTapText(
        'Show roots',
        timeout: const Duration(milliseconds: 800),
      );
      if (!await nativeTapText(
        'Downloads',
        timeout: const Duration(milliseconds: 800),
      )) {
        await nativeTapText(
          'Download',
          timeout: const Duration(milliseconds: 800),
        );
      }
      found = await _waitForNativeFile(fileName);
    }
    if (!found) {
      fail(
        'Native picker did not show $fileName in Downloads.\n'
        '${await _dumpNativeUi()}',
      );
    }
    if (!await _selectDocumentsUiFile(fileName)) {
      fail(
        'Native picker stayed open after tapping $fileName. SAF did not '
        'return a file.\n${await _dumpNativeUi()}',
      );
    }
    await pumpQuiet(const Duration(milliseconds: 800));
  }

  Future<bool> _waitForNativeFile(String fileName) async {
    try {
      await $.platform.android.waitUntilVisible(
        AndroidSelector(text: fileName),
        timeout: const Duration(seconds: 8),
      );
      return true;
    } catch (_) {}
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      if (await _treeHasFile(fileName)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return await _treeHasFile(fileName);
  }

  Future<bool> _selectDocumentsUiFile(String fileName) async {
    Future<AndroidGetNativeViewsResponse> snapshot() =>
        $.platform.android.getNativeViews(null);

    Future<void> tapCellFor(AndroidNativeView label) async {
      final next = await snapshot();
      final cell = _cellContainingLabel(next, label) ?? label;
      await _tapAtScreen(cell, next);
    }

    Future<void> tapLabelCenter(AndroidNativeView label) async {
      final next = await snapshot();
      await _tapAtScreen(label, next);
    }

    Future<void> tapIcon(AndroidNativeView label) async {
      final next = await snapshot();
      final size = _screenSize(next);
      await _tapAtScreenPoint(
        x: (label.visibleBounds.minX - 48) / size.width,
        y: label.visibleCenter.y / size.height,
      );
    }

    var labels = _exactLabels(await snapshot(), fileName);
    for (final label in labels) {
      try {
        await tapCellFor(label);
      } catch (_) {}
      await pumpQuiet(const Duration(milliseconds: 500));
      if (!await _pickerShows(fileName)) return true;
      try {
        await tapLabelCenter(label);
      } catch (_) {}
      await pumpQuiet(const Duration(milliseconds: 500));
      if (!await _pickerShows(fileName)) return true;
      try {
        await tapIcon(label);
      } catch (_) {}
      await pumpQuiet(const Duration(milliseconds: 500));
      if (!await _pickerShows(fileName)) return true;
    }

    labels = _exactLabels(await snapshot(), fileName);
    if (labels.isNotEmpty) {
      try {
        await tapCellFor(labels.last);
      } catch (_) {}
      await pumpQuiet(const Duration(milliseconds: 500));
      if (!await _pickerShows(fileName)) return true;
    }

    for (final desc in ['Open', 'Select', 'Done', 'OK']) {
      await _nativeTapDescription(desc);
    }
    for (final text in ['SELECT', 'Select', 'Open']) {
      await nativeTapText(text, timeout: const Duration(milliseconds: 500));
    }
    await pumpQuiet(const Duration(milliseconds: 500));
    return !await _pickerShows(fileName);
  }

  Future<bool> _nativeTapDescription(String description) async {
    try {
      await $.platform.android.tap(
        AndroidSelector(contentDescription: description),
        timeout: const Duration(milliseconds: 500),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _pickerShows(String fileName) => _treeHasFile(fileName);

  Future<bool> _treeHasFile(String fileName) async {
    try {
      final snapshot = await $.platform.android.getNativeViews(null);
      return _treeHasFileIn(snapshot.roots, fileName);
    } catch (_) {
      return false;
    }
  }

  bool _treeHasFileIn(List<AndroidNativeView> roots, String fileName) {
    bool walk(AndroidNativeView view, String? owner) {
      final package = view.applicationPackage ?? owner;
      if (package == _appPackage) return false;
      if (nativeFileLabelMatches(view.text, fileName) ||
          nativeFileLabelMatches(view.contentDescription, fileName)) {
        return true;
      }
      return view.children.any((child) => walk(child, package));
    }

    return roots.any((root) => walk(root, null));
  }

  List<AndroidNativeView> _exactLabels(
    AndroidGetNativeViewsResponse tree,
    String fileName,
  ) {
    final labels = <AndroidNativeView>[];
    void collect(AndroidNativeView view, String? owner) {
      final package = view.applicationPackage ?? owner;
      if (package == _appPackage) return;
      if (nativeFileLabelIsExact(view.text, fileName) ||
          nativeFileLabelIsExact(view.contentDescription, fileName)) {
        labels.add(view);
      }
      for (final child in view.children) {
        collect(child, package);
      }
    }

    for (final root in tree.roots) {
      collect(root, null);
    }
    labels.sort((a, b) => a.visibleCenter.y.compareTo(b.visibleCenter.y));
    return labels;
  }

  AndroidNativeView? _cellContainingLabel(
    AndroidGetNativeViewsResponse tree,
    AndroidNativeView label,
  ) {
    final cells = <AndroidNativeView>[];
    final screen = _screenSize(tree);
    final screenArea = screen.width * screen.height;
    void collect(AndroidNativeView view) {
      if (_boundsContain(view.visibleBounds, label.visibleBounds) &&
          _isCellSize(view) &&
          _area(view) > _area(label) + 1 &&
          _area(view) < screenArea * 0.35) {
        cells.add(view);
      }
      for (final child in view.children) {
        collect(child);
      }
    }

    for (final root in tree.roots) {
      collect(root);
    }
    if (cells.isEmpty) return null;
    cells.sort(_byArea);
    return cells.first;
  }

  bool _boundsContain(Rectangle outer, Rectangle inner) {
    return outer.minX <= inner.minX &&
        outer.maxX >= inner.maxX &&
        outer.minY <= inner.minY &&
        outer.maxY >= inner.maxY;
  }

  bool _isCellSize(AndroidNativeView view) {
    final width = view.visibleBounds.maxX - view.visibleBounds.minX;
    final height = view.visibleBounds.maxY - view.visibleBounds.minY;
    return width >= 80 && height >= 36 && height <= 480;
  }

  double _area(AndroidNativeView view) {
    final bounds = view.visibleBounds;
    return (bounds.maxX - bounds.minX) * (bounds.maxY - bounds.minY);
  }

  int _byArea(AndroidNativeView a, AndroidNativeView b) =>
      _area(a).compareTo(_area(b));

  ({double width, double height}) _screenSize(
    AndroidGetNativeViewsResponse tree,
  ) {
    var maxX = 0.0;
    var maxY = 0.0;
    void walk(AndroidNativeView view) {
      if (view.visibleBounds.maxX > maxX) maxX = view.visibleBounds.maxX;
      if (view.visibleBounds.maxY > maxY) maxY = view.visibleBounds.maxY;
      for (final child in view.children) {
        walk(child);
      }
    }

    for (final root in tree.roots) {
      walk(root);
    }
    return (width: maxX <= 0 ? 1 : maxX, height: maxY <= 0 ? 1 : maxY);
  }

  Future<void> _tapAtScreen(
    AndroidNativeView target,
    AndroidGetNativeViewsResponse tree,
  ) {
    final size = _screenSize(tree);
    return _tapAtScreenPoint(
      x: target.visibleCenter.x / size.width,
      y: target.visibleCenter.y / size.height,
    );
  }

  Future<void> _tapAtScreenPoint({required double x, required double y}) {
    return $.platform.android.tapAt(
      Offset(x.clamp(0.01, 0.99), y.clamp(0.01, 0.99)),
    );
  }

  Future<String> _dumpNativeUi() async {
    try {
      final tree = await $.platform.android.getNativeViews(null);
      final buf = StringBuffer();
      void walk(AndroidNativeView view, int depth) {
        buf.writeln(
          '${'  ' * depth}${view.className ?? '?'} '
          'text=${view.text} desc=${view.contentDescription} '
          'res=${view.resourceName} click=${view.isClickable} '
          'center=${view.visibleCenter.x},${view.visibleCenter.y} '
          'bounds=${view.visibleBounds.minX},${view.visibleBounds.minY}-'
          '${view.visibleBounds.maxX},${view.visibleBounds.maxY}',
        );
        for (final child in view.children) {
          walk(child, depth + 1);
        }
      }

      for (final root in tree.roots) {
        walk(root, 0);
      }
      return buf.toString();
    } catch (error) {
      return 'native dump failed: $error';
    }
  }
}
