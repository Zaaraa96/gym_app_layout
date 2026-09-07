import '../common/exercise_asset_catalog.dart';
import 'exercise_media_migration.dart';
import 'models/models.dart';
import 'plan_catalog.dart';

class ExerciseEditorIssue {
  const ExerciseEditorIssue({
    required this.message,
    this.movementIndex,
    this.field,
  });

  final String message;
  final int? movementIndex;
  final String? field;
}

class ExerciseMediaDraft {
  const ExerciseMediaDraft({
    required this.uri,
    required this.source,
    required this.kind,
    this.userEdited = false,
    this.catalogSuggested = false,
  });

  final String uri;
  final ExerciseMediaSource source;
  final ExerciseMediaKind kind;
  final bool userEdited;
  final bool catalogSuggested;

  bool get isEmpty => uri.trim().isEmpty || source == ExerciseMediaSource.none;
}

class ExerciseMovementDraft {
  ExerciseMovementDraft({
    this.prescriptionId,
    this.catalogExerciseId,
    this.title = '',
    this.type = PrescriptionType.reps,
    this.sets = 3,
    this.reps = 12,
    this.durationSeconds = 30,
    List<String>? targetAreaIds,
    this.media,
    this.manualTargets = false,
    this.manualMedia = false,
  }) : targetAreaIds = canonicalizeTargetAreaIds(targetAreaIds ?? const []);

  factory ExerciseMovementDraft.empty() => ExerciseMovementDraft();

  factory ExerciseMovementDraft.fromPrescription(ExercisePrescription exercise) {
    final type = exercise.prescribedDurationSeconds != null
        ? PrescriptionType.timed
        : PrescriptionType.reps;
    final storedTargets = exercise.targetAreaIds;
    final catalogTargets = catalogTargetAreaIdsForTitle(exercise.title);
    final hasStored = storedTargets.isNotEmpty;
    final media = _mediaFromPrescription(exercise);
    return ExerciseMovementDraft(
      prescriptionId: exercise.prescriptionId,
      catalogExerciseId: exercise.catalogExerciseId ??
          matchExerciseAsset(exercise.title)?.id,
      title: exercise.title,
      type: type,
      sets: exercise.prescribedSets,
      reps: exercise.prescribedReps ?? 12,
      durationSeconds: exercise.prescribedDurationSeconds ?? 30,
      targetAreaIds: hasStored ? storedTargets : catalogTargets,
      media: media,
      manualTargets: hasStored &&
          !targetAreasMatchCatalog(exercise.title, storedTargets),
      manualMedia: media != null && media.userEdited,
    );
  }

  String? prescriptionId;
  String? catalogExerciseId;
  String title;
  PrescriptionType type;
  int? sets;
  int? reps;
  int? durationSeconds;
  List<String> targetAreaIds;
  ExerciseMediaDraft? media;
  bool manualTargets;
  bool manualMedia;

  bool get isBlank {
    return title.trim().isEmpty &&
        targetAreaIds.isEmpty &&
        media == null &&
        catalogExerciseId == null;
  }

  bool get hasCatalogTargets {
    if (manualTargets || targetAreaIds.isEmpty) return false;
    return targetAreasMatchCatalog(title, targetAreaIds);
  }

  ExerciseMovementDraft copy() {
    return ExerciseMovementDraft(
      prescriptionId: prescriptionId,
      catalogExerciseId: catalogExerciseId,
      title: title,
      type: type,
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      targetAreaIds: List<String>.from(targetAreaIds),
      media: media,
      manualTargets: manualTargets,
      manualMedia: manualMedia,
    );
  }

  /// True when applying [entry] would replace user-edited targets or media.
  bool catalogWouldReplaceManual(ExerciseAssetEntry entry) {
    final nextTargets = canonicalizeTargetAreaIds(entry.targetAreaIds);
    final targetsClash = manualTargets &&
        nextTargets.isNotEmpty &&
        !sameIdList(nextTargets, targetAreaIds);
    final mediaClash = manualMedia && media != null && media!.uri != entry.assetPath;
    return targetsClash || mediaClash;
  }

  void applyCatalog(
    ExerciseAssetEntry entry, {
    bool replaceManual = false,
  }) {
    title = entry.label;
    catalogExerciseId = entry.id;
    final nextTargets = canonicalizeTargetAreaIds(entry.targetAreaIds);
    if (!manualTargets || replaceManual || targetAreaIds.isEmpty) {
      targetAreaIds = List<String>.from(nextTargets);
      if (replaceManual) manualTargets = false;
    }
    if (!manualMedia || replaceManual || media == null) {
      media = ExerciseMediaDraft(
        uri: entry.assetPath,
        source: ExerciseMediaSource.asset,
        kind: _kindForAssetPath(entry.assetPath),
        catalogSuggested: true,
        userEdited: false,
      );
      if (replaceManual) manualMedia = false;
    }
  }

  /// Updates the typed title. Returns a catalog entry the caller must confirm
  /// before applying, or `null` when the change is complete.
  ExerciseAssetEntry? setTitle(String value) {
    title = value;
    final match = matchExerciseAsset(value);
    if (match != null && match.id == catalogExerciseId) return null;
    if (match == null) {
      catalogExerciseId = null;
      if (!manualTargets) targetAreaIds = [];
      if (!manualMedia) media = null;
      return null;
    }
    if (catalogWouldReplaceManual(match)) return match;
    applyCatalog(match);
    return null;
  }

  List<ExerciseEditorIssue> validate({
    required int index,
    required bool includeSets,
  }) {
    final issues = <ExerciseEditorIssue>[];
    if (title.trim().isEmpty) {
      issues.add(
        ExerciseEditorIssue(
          message: 'Add a name for ${movementLabel(index)}.',
          movementIndex: index,
          field: 'title',
        ),
      );
    }
    if (includeSets && (sets == null || sets! < 1)) {
      issues.add(
        ExerciseEditorIssue(
          message: 'Sets must be at least 1.',
          movementIndex: index,
          field: 'sets',
        ),
      );
    }
    if (type == PrescriptionType.reps) {
      if (reps == null || reps! < 1) {
        issues.add(
          ExerciseEditorIssue(
            message: 'Reps must be at least 1.',
            movementIndex: index,
            field: 'reps',
          ),
        );
      }
    } else if (durationSeconds == null || durationSeconds! < 1) {
      issues.add(
        ExerciseEditorIssue(
          message: 'Duration must be at least 1 second.',
          movementIndex: index,
          field: 'duration',
        ),
      );
    }
    return issues;
  }

  ExercisePrescription toPrescription({
    required String Function() newId,
    required int prescribedSets,
  }) {
    return ExercisePrescription.create(
      prescriptionId: prescriptionId ?? newId(),
      title: title.trim(),
      prescribedSets: prescribedSets,
      prescribedReps: type == PrescriptionType.reps ? reps : null,
      prescribedDurationSeconds:
          type == PrescriptionType.timed ? durationSeconds : null,
      targetAreaIds: canonicalizeTargetAreaIds(targetAreaIds),
      catalogExerciseId: catalogExerciseId,
      svgPath: media?.source == ExerciseMediaSource.asset ? media?.uri : null,
      mediaUri: media?.uri,
      mediaSource: media?.source ?? ExerciseMediaSource.none,
      mediaKind: media?.kind ?? ExerciseMediaKind.unknown,
    );
  }
}

class ExerciseBlockDraft {
  ExerciseBlockDraft({
    this.blockId,
    this.mode = ExerciseEditorMode.single,
    this.rounds = 3,
    List<ExerciseMovementDraft>? movements,
    this.unequalRounds = false,
    this.dirty = false,
  }) : movements = movements ?? [ExerciseMovementDraft.empty()];

  factory ExerciseBlockDraft.createNew() => ExerciseBlockDraft();

  factory ExerciseBlockDraft.fromBlock(ExerciseBlock block) {
    final migrated = migrateBlockMediaToExercises(block);
    final exercises = migrated.exercises;
    final mode = migrated.kind == BlockKind.superset
        ? ExerciseEditorMode.superset
        : ExerciseEditorMode.single;
    final movements = [
      if (exercises.isEmpty)
        ExerciseMovementDraft.empty()
      else
        for (final exercise in exercises)
          ExerciseMovementDraft.fromPrescription(exercise),
    ];
    if (mode == ExerciseEditorMode.superset && movements.length < 2) {
      movements.add(ExerciseMovementDraft.empty());
    }
    var unequal = false;
    int? rounds = 3;
    if (mode == ExerciseEditorMode.superset && exercises.length >= 2) {
      final counts = {for (final item in exercises) item.prescribedSets};
      if (counts.length > 1) {
        unequal = true;
        rounds = null;
      } else {
        rounds = exercises.first.prescribedSets;
      }
    } else if (exercises.isNotEmpty) {
      rounds = exercises.first.prescribedSets;
      movements.first.sets = exercises.first.prescribedSets;
    }
    return ExerciseBlockDraft(
      blockId: migrated.blockId,
      mode: mode,
      rounds: rounds,
      movements: movements,
      unequalRounds: unequal,
    );
  }

  String? blockId;
  ExerciseEditorMode mode;
  int? rounds;
  List<ExerciseMovementDraft> movements;
  bool unequalRounds;
  bool dirty;

  bool get isNew => blockId == null;
  bool get isSuperset => mode == ExerciseEditorMode.superset;

  String get appBarTitle {
    if (isNew) return 'Add exercise';
    return isSuperset ? 'Edit superset' : 'Edit exercise';
  }

  String get primaryActionLabel {
    if (!isNew) return 'SAVE CHANGES';
    return isSuperset ? 'ADD SUPERSET' : 'ADD EXERCISE';
  }

  String get deleteActionLabel =>
      isSuperset ? 'Delete superset' : 'Delete exercise';

  bool get extrasHaveData =>
      movements.skip(1).any((movement) => !movement.isBlank);

  void markDirty() => dirty = true;

  void switchToSuperset() {
    if (mode == ExerciseEditorMode.superset) return;
    final singleSets = movements.first.sets ?? 3;
    rounds = singleSets;
    unequalRounds = false;
    if (movements.length < 2) {
      movements.add(ExerciseMovementDraft.empty());
    }
    mode = ExerciseEditorMode.superset;
    markDirty();
  }

  /// Returns false when the caller must confirm before dropping extra movements.
  bool switchToSingle({bool confirmed = false}) {
    if (mode == ExerciseEditorMode.single) return true;
    if (extrasHaveData && !confirmed) return false;
    final a = movements.first;
    a.sets = rounds ?? a.sets ?? 3;
    movements = [a];
    unequalRounds = false;
    mode = ExerciseEditorMode.single;
    markDirty();
    return true;
  }

  void addMovement() {
    movements.add(ExerciseMovementDraft.empty());
    markDirty();
  }

  /// Returns false when removal would drop below two movements.
  bool removeMovement(int index) {
    if (!isSuperset) return false;
    if (movements.length <= 2) return false;
    if (index < 0 || index >= movements.length) return false;
    movements.removeAt(index);
    markDirty();
    return true;
  }

  void reorderMovements(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= movements.length) return;
    if (newIndex < 0 || newIndex >= movements.length) return;
    final item = movements.removeAt(oldIndex);
    movements.insert(newIndex, item);
    markDirty();
  }

  void setRounds(int? value) {
    rounds = value;
    if (value != null && value >= 1) unequalRounds = false;
    markDirty();
  }

  List<ExerciseEditorIssue> validate() {
    final issues = <ExerciseEditorIssue>[];
    if (isSuperset) {
      if (unequalRounds || rounds == null || rounds! < 1) {
        issues.add(
          const ExerciseEditorIssue(
            message: 'This superset has different set counts. Choose rounds '
                'to apply to every movement.',
            field: 'rounds',
          ),
        );
      }
      if (movements.length < 2) {
        issues.add(
          const ExerciseEditorIssue(
            message: 'A superset needs at least 2 exercises.',
          ),
        );
      }
      for (var i = 0; i < movements.length; i++) {
        issues.addAll(movements[i].validate(index: i, includeSets: false));
      }
    } else {
      issues.addAll(movements.first.validate(index: 0, includeSets: true));
    }
    return issues;
  }

  bool get canCommit => validate().isEmpty;

  ExerciseBlock toBlock({required String Function() newId}) {
    final issues = validate();
    if (issues.isNotEmpty) {
      throw StateError(issues.first.message);
    }
    if (isSuperset) {
      final shared = rounds!;
      return ExerciseBlock.create(
        blockId: blockId ?? newId(),
        kind: BlockKind.superset,
        exercises: [
          for (final movement in movements)
            movement.toPrescription(newId: newId, prescribedSets: shared),
        ],
      );
    }
    final movement = movements.first;
    return ExerciseBlock.create(
      blockId: blockId ?? newId(),
      kind: BlockKind.single,
      exercises: [
        movement.toPrescription(
          newId: newId,
          prescribedSets: movement.sets ?? 3,
        ),
      ],
    );
  }
}

String movementLabel(int index) {
  if (index < 0) return 'movement';
  if (index < 26) return 'Movement ${String.fromCharCode(65 + index)}';
  return 'Movement ${index + 1}';
}

ExerciseMediaDraft? _mediaFromPrescription(ExercisePrescription exercise) {
  final match = matchExerciseAsset(exercise.title);
  final catalogPath = match?.assetPath;
  if (exercise.hasStoredMedia) {
    final uri = exercise.mediaUri!.trim();
    final fromCatalog = catalogPath != null && uri == catalogPath;
    return ExerciseMediaDraft(
      uri: uri,
      source: exercise.mediaSource,
      kind: exercise.mediaKind,
      userEdited: !fromCatalog,
      catalogSuggested: fromCatalog,
    );
  }
  final legacy = exercise.svgPath?.trim();
  if (legacy != null && legacy.isNotEmpty) {
    final fromCatalog = catalogPath != null && legacy == catalogPath;
    return ExerciseMediaDraft(
      uri: legacy,
      source: ExerciseMediaSource.asset,
      kind: _kindForAssetPath(legacy),
      userEdited: !fromCatalog,
      catalogSuggested: fromCatalog || catalogPath == null,
    );
  }
  if (match != null) {
    return ExerciseMediaDraft(
      uri: match.assetPath,
      source: ExerciseMediaSource.asset,
      kind: _kindForAssetPath(match.assetPath),
      catalogSuggested: true,
    );
  }
  return null;
}

ExerciseMediaKind _kindForAssetPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.svg')) return ExerciseMediaKind.svg;
  if (lower.endsWith('.gif')) return ExerciseMediaKind.gif;
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.webm')) {
    return ExerciseMediaKind.video;
  }
  return ExerciseMediaKind.image;
}
