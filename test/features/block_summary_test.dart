import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/features/plans/block_summary.dart';

void main() {
  test('formatLoad prefers duration seconds over missing reps', () {
    final timed = ExercisePrescription.create(
      prescriptionId: 'p1',
      title: 'plank',
      prescribedSets: 1,
      prescribedDurationSeconds: 30,
    );
    final reps = ExercisePrescription.create(
      prescriptionId: 'p2',
      title: 'squat',
      prescribedSets: 3,
      prescribedReps: 12,
    );
    final missing = ExercisePrescription.create(
      prescriptionId: 'p3',
      title: 'unknown',
      prescribedSets: 2,
    );
    expect(formatLoad(timed), 'x30s');
    expect(formatLoad(reps), 'x12');
    expect(formatLoad(missing), 'x0');
    expect(formatPrescription(timed), '1 × 30s plank');
    expect(formatPrescription(reps), '3 × 12 squat');
  });

  test('formatBlock joins superset movements and reports shared sets', () {
    final block = ExerciseBlock.create(
      blockId: 'ss',
      kind: BlockKind.superset,
      exercises: [
        ExercisePrescription.create(
          prescriptionId: 'p1',
          title: 'kang squat',
          prescribedSets: 3,
          prescribedReps: 12,
        ),
        ExercisePrescription.create(
          prescriptionId: 'p2',
          title: 'leg extension',
          prescribedSets: 3,
          prescribedReps: 10,
        ),
      ],
    );
    expect(formatBlock(block), '3 × 12 kang squat + 3 × 10 leg extension');
    expect(blockSetCount(block), 3);
    expect(
      blockSetCount(
        ExerciseBlock.create(blockId: 'empty', kind: BlockKind.single),
      ),
      0,
    );
  });
}
