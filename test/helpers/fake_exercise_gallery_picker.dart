import 'package:gym_app/features/plans/exercise_media_picker.dart';

/// Test double that never opens the device gallery.
class FakeExerciseGalleryPicker implements ExerciseGalleryPicker {
  PickedExerciseMedia? nextImage;
  PickedExerciseMedia? nextVideo;

  @override
  Future<PickedExerciseMedia?> pickImage() async => nextImage;

  @override
  Future<PickedExerciseMedia?> pickVideo() async => nextVideo;
}
