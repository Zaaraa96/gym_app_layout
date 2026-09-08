import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/memory_catalog_repository.dart';
import 'package:gym_app/features/catalog/catalog_exercise_detail_page.dart';
import 'package:gym_app/features/catalog/catalog_exercise_editor_page.dart';
import 'package:gym_app/features/plans/exercise_media_picker.dart';
import 'package:gym_app/features/plans/exercise_media_picker_sheet.dart';
import 'package:gym_app/features/plans/plans_home_page.dart';

import '../helpers/fake_exercise_gallery_picker.dart';
import '../helpers/ports.dart';

Finder _exercisesTab() => find.byIcon(Icons.directions_run_outlined);

Future<void> _setTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _openExercises(WidgetTester tester) async {
  await tester.tap(_exercisesTab());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(Get.reset);

  testWidgets('Exercises tab lists bundled movements and filters by region',
      (tester) async {
    await _setTallSurface(tester);
    await tester.pumpWidget(
      GetMaterialApp(
        home: PlansHomePage(ports: testPorts()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await _openExercises(tester);

    expect(find.byKey(const Key('exercises-tab')), findsOneWidget);
    expect(find.byKey(const Key('add-catalog-exercise')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('catalog-search')), 'plank');
    await tester.pump();
    expect(find.byKey(const Key('catalog-tile-plank')), findsOneWidget);
    expect(find.byKey(const Key('catalog-tile-squat')), findsNothing);

    await tester.enterText(find.byKey(const Key('catalog-search')), '');
    await tester.pump();
    await tester.tap(find.byKey(const Key('region-abs')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('catalog-search')), 'squat');
    await tester.pump();
    expect(find.byKey(const Key('catalog-tile-squat')), findsNothing);
    await tester.enterText(find.byKey(const Key('catalog-search')), 'plank');
    await tester.pump();
    expect(find.byKey(const Key('catalog-tile-plank')), findsOneWidget);
  });

  testWidgets('add exercise with a picture lands in the list and promotion hook',
      (tester) async {
    await _setTallSurface(tester);
    final catalog = MemoryCatalogRepository();
    final ports = testPorts(catalog: catalog);
    final picker = FakeExerciseGalleryPicker()
      ..nextImage = PickedExerciseMedia.asset(
        'assets/image/exercises/crunches.png',
      );

    await tester.pumpWidget(
      ExerciseGalleryPickerScope(
        picker: picker,
        child: GetMaterialApp(
          home: CatalogExerciseEditorPage(ports: ports),
          getPages: [
            GetPage(
              name: AppRoutes.editCatalogExercise,
              page: () => CatalogExerciseEditorPage(ports: ports),
            ),
            GetPage(
              name: AppRoutes.catalogExercise,
              page: () => CatalogExerciseDetailPage(
                exerciseId: Get.arguments as String,
                ports: ports,
              ),
            ),
            GetPage(
              name: AppRoutes.home,
              page: () => PlansHomePage(ports: ports),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('catalog-exercise-name')),
      'Cable crunch',
    );
    await tester.tap(find.byKey(const Key('catalog-exercise-picture')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Gallery photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('add-target-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-target-chest')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('save-catalog-exercise')));
    await tester.tap(find.byKey(const Key('save-catalog-exercise')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(catalog.promotionEvents, hasLength(1));
    expect(catalog.promotionEvents.single.title, 'Cable crunch');
    expect(await catalog.userCreatedNotInBundled(), hasLength(1));
  });

  testWidgets('duplicate bundled names stay rejected in the editor',
      (tester) async {
    await _setTallSurface(tester);
    final ports = testPorts();
    final picker = FakeExerciseGalleryPicker()
      ..nextImage = PickedExerciseMedia.asset(
        'assets/image/exercises/plank.png',
      );

    await tester.pumpWidget(
      ExerciseGalleryPickerScope(
        picker: picker,
        child: GetMaterialApp(
          home: CatalogExerciseEditorPage(ports: ports),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('catalog-exercise-name')),
      'Plank',
    );
    await tester.tap(find.byKey(const Key('catalog-exercise-picture')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Gallery photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('add-target-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-target-chest')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('save-catalog-exercise')));
    await tester.tap(find.byKey(const Key('save-catalog-exercise')));
    await tester.pump();

    expect(find.text('An exercise named Plank already exists.'), findsOneWidget);
  });
}
