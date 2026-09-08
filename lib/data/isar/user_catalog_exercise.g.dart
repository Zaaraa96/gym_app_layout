// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_catalog_exercise.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserCatalogExerciseCollection on Isar {
  IsarCollection<UserCatalogExercise> get userCatalogExercises =>
      this.collection();
}

final UserCatalogExerciseSchema = CollectionSchema(
  name: r'UserCatalogExercise',
  id: int.parse('2308038730620676887'),
  properties: {
    r'aliases': PropertySchema(
      id: 0,
      name: r'aliases',
      type: IsarType.stringList,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'defaultDurationSeconds': PropertySchema(
      id: 2,
      name: r'defaultDurationSeconds',
      type: IsarType.long,
    ),
    r'defaultReps': PropertySchema(
      id: 3,
      name: r'defaultReps',
      type: IsarType.long,
    ),
    r'defaultSets': PropertySchema(
      id: 4,
      name: r'defaultSets',
      type: IsarType.long,
    ),
    r'mediaKind': PropertySchema(
      id: 5,
      name: r'mediaKind',
      type: IsarType.byte,
      enumMap: _UserCatalogExercisemediaKindEnumValueMap,
    ),
    r'mediaSource': PropertySchema(
      id: 6,
      name: r'mediaSource',
      type: IsarType.byte,
      enumMap: _UserCatalogExercisemediaSourceEnumValueMap,
    ),
    r'mediaUri': PropertySchema(
      id: 7,
      name: r'mediaUri',
      type: IsarType.string,
    ),
    r'prescriptionType': PropertySchema(
      id: 8,
      name: r'prescriptionType',
      type: IsarType.byte,
      enumMap: _UserCatalogExerciseprescriptionTypeEnumValueMap,
    ),
    r'regionIds': PropertySchema(
      id: 9,
      name: r'regionIds',
      type: IsarType.stringList,
    ),
    r'targetAreaIds': PropertySchema(
      id: 10,
      name: r'targetAreaIds',
      type: IsarType.stringList,
    ),
    r'title': PropertySchema(
      id: 11,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 13,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _userCatalogExerciseEstimateSize,
  serialize: _userCatalogExerciseSerialize,
  deserialize: _userCatalogExerciseDeserialize,
  deserializeProp: _userCatalogExerciseDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: int.parse('2134397340427724972'),
      name: r'uuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _userCatalogExerciseGetId,
  getLinks: _userCatalogExerciseGetLinks,
  attach: _userCatalogExerciseAttach,
  version: '3.1.0+1',
);

int _userCatalogExerciseEstimateSize(
  UserCatalogExercise object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.aliases.length * 3;
  {
    for (var i = 0; i < object.aliases.length; i++) {
      final value = object.aliases[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.mediaUri.length * 3;
  bytesCount += 3 + object.regionIds.length * 3;
  {
    for (var i = 0; i < object.regionIds.length; i++) {
      final value = object.regionIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.targetAreaIds.length * 3;
  {
    for (var i = 0; i < object.targetAreaIds.length; i++) {
      final value = object.targetAreaIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _userCatalogExerciseSerialize(
  UserCatalogExercise object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.aliases);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeLong(offsets[2], object.defaultDurationSeconds);
  writer.writeLong(offsets[3], object.defaultReps);
  writer.writeLong(offsets[4], object.defaultSets);
  writer.writeByte(offsets[5], object.mediaKind.index);
  writer.writeByte(offsets[6], object.mediaSource.index);
  writer.writeString(offsets[7], object.mediaUri);
  writer.writeByte(offsets[8], object.prescriptionType.index);
  writer.writeStringList(offsets[9], object.regionIds);
  writer.writeStringList(offsets[10], object.targetAreaIds);
  writer.writeString(offsets[11], object.title);
  writer.writeDateTime(offsets[12], object.updatedAt);
  writer.writeString(offsets[13], object.uuid);
}

UserCatalogExercise _userCatalogExerciseDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserCatalogExercise();
  object.aliases = reader.readStringList(offsets[0]) ?? [];
  object.createdAt = reader.readDateTime(offsets[1]);
  object.defaultDurationSeconds = reader.readLongOrNull(offsets[2]);
  object.defaultReps = reader.readLongOrNull(offsets[3]);
  object.defaultSets = reader.readLong(offsets[4]);
  object.id = id;
  object.mediaKind = _UserCatalogExercisemediaKindValueEnumMap[
          reader.readByteOrNull(offsets[5])] ??
      ExerciseMediaKind.unknown;
  object.mediaSource = _UserCatalogExercisemediaSourceValueEnumMap[
          reader.readByteOrNull(offsets[6])] ??
      ExerciseMediaSource.none;
  object.mediaUri = reader.readString(offsets[7]);
  object.prescriptionType = _UserCatalogExerciseprescriptionTypeValueEnumMap[
          reader.readByteOrNull(offsets[8])] ??
      PrescriptionType.reps;
  object.regionIds = reader.readStringList(offsets[9]) ?? [];
  object.targetAreaIds = reader.readStringList(offsets[10]) ?? [];
  object.title = reader.readString(offsets[11]);
  object.updatedAt = reader.readDateTime(offsets[12]);
  object.uuid = reader.readString(offsets[13]);
  return object;
}

P _userCatalogExerciseDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (_UserCatalogExercisemediaKindValueEnumMap[
              reader.readByteOrNull(offset)] ??
          ExerciseMediaKind.unknown) as P;
    case 6:
      return (_UserCatalogExercisemediaSourceValueEnumMap[
              reader.readByteOrNull(offset)] ??
          ExerciseMediaSource.none) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (_UserCatalogExerciseprescriptionTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          PrescriptionType.reps) as P;
    case 9:
      return (reader.readStringList(offset) ?? []) as P;
    case 10:
      return (reader.readStringList(offset) ?? []) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _UserCatalogExercisemediaKindEnumValueMap = {
  'unknown': 0,
  'svg': 1,
  'image': 2,
  'gif': 3,
  'video': 4,
};
const _UserCatalogExercisemediaKindValueEnumMap = {
  0: ExerciseMediaKind.unknown,
  1: ExerciseMediaKind.svg,
  2: ExerciseMediaKind.image,
  3: ExerciseMediaKind.gif,
  4: ExerciseMediaKind.video,
};
const _UserCatalogExercisemediaSourceEnumValueMap = {
  'none': 0,
  'asset': 1,
  'gallery': 2,
  'network': 3,
};
const _UserCatalogExercisemediaSourceValueEnumMap = {
  0: ExerciseMediaSource.none,
  1: ExerciseMediaSource.asset,
  2: ExerciseMediaSource.gallery,
  3: ExerciseMediaSource.network,
};
const _UserCatalogExerciseprescriptionTypeEnumValueMap = {
  'reps': 0,
  'timed': 1,
};
const _UserCatalogExerciseprescriptionTypeValueEnumMap = {
  0: PrescriptionType.reps,
  1: PrescriptionType.timed,
};

Id _userCatalogExerciseGetId(UserCatalogExercise object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userCatalogExerciseGetLinks(
    UserCatalogExercise object) {
  return [];
}

void _userCatalogExerciseAttach(
    IsarCollection<dynamic> col, Id id, UserCatalogExercise object) {
  object.id = id;
}

extension UserCatalogExerciseQueryWhereSort
    on QueryBuilder<UserCatalogExercise, UserCatalogExercise, QWhere> {
  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserCatalogExerciseQueryWhere
    on QueryBuilder<UserCatalogExercise, UserCatalogExercise, QWhereClause> {
  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterWhereClause>
      uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterWhereClause>
      uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension UserCatalogExerciseQueryFilter on QueryBuilder<UserCatalogExercise,
    UserCatalogExercise, QFilterCondition> {
  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aliases',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aliases',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aliases',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aliases',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aliases',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      aliasesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultDurationSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'defaultDurationSeconds',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultDurationSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'defaultDurationSeconds',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultDurationSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultDurationSecondsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultDurationSecondsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultDurationSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultDurationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultRepsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'defaultReps',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultRepsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'defaultReps',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultRepsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultReps',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultRepsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultReps',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultRepsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultReps',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultRepsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultReps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultSetsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultSets',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultSetsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultSets',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultSetsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultSets',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      defaultSetsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultSets',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaKindEqualTo(ExerciseMediaKind value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaKind',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaKindGreaterThan(
    ExerciseMediaKind value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaKind',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaKindLessThan(
    ExerciseMediaKind value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaKind',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaKindBetween(
    ExerciseMediaKind lower,
    ExerciseMediaKind upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaKind',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaSourceEqualTo(ExerciseMediaSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaSource',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaSourceGreaterThan(
    ExerciseMediaSource value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaSource',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaSourceLessThan(
    ExerciseMediaSource value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaSource',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaSourceBetween(
    ExerciseMediaSource lower,
    ExerciseMediaSource upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaSource',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaUri',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaUri',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaUri',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaUri',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaUri',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaUri',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaUri',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaUri',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaUri',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      mediaUriIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaUri',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      prescriptionTypeEqualTo(PrescriptionType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prescriptionType',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      prescriptionTypeGreaterThan(
    PrescriptionType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'prescriptionType',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      prescriptionTypeLessThan(
    PrescriptionType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'prescriptionType',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      prescriptionTypeBetween(
    PrescriptionType lower,
    PrescriptionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'prescriptionType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'regionIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'regionIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'regionIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'regionIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'regionIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'regionIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'regionIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'regionIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'regionIds',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'regionIds',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'regionIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'regionIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'regionIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'regionIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'regionIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      regionIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'regionIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetAreaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetAreaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetAreaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetAreaIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'targetAreaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'targetAreaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'targetAreaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'targetAreaIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetAreaIds',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'targetAreaIds',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetAreaIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetAreaIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetAreaIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetAreaIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetAreaIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      targetAreaIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetAreaIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension UserCatalogExerciseQueryObject on QueryBuilder<UserCatalogExercise,
    UserCatalogExercise, QFilterCondition> {}

extension UserCatalogExerciseQueryLinks on QueryBuilder<UserCatalogExercise,
    UserCatalogExercise, QFilterCondition> {}

extension UserCatalogExerciseQuerySortBy
    on QueryBuilder<UserCatalogExercise, UserCatalogExercise, QSortBy> {
  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByDefaultDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByDefaultDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByDefaultReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultReps', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByDefaultRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultReps', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByDefaultSets() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSets', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByDefaultSetsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSets', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByMediaKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaKind', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByMediaKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaKind', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByMediaSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSource', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByMediaSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSource', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByMediaUri() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaUri', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByMediaUriDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaUri', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByPrescriptionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prescriptionType', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByPrescriptionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prescriptionType', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension UserCatalogExerciseQuerySortThenBy
    on QueryBuilder<UserCatalogExercise, UserCatalogExercise, QSortThenBy> {
  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByDefaultDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByDefaultDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByDefaultReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultReps', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByDefaultRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultReps', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByDefaultSets() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSets', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByDefaultSetsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSets', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByMediaKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaKind', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByMediaKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaKind', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByMediaSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSource', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByMediaSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSource', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByMediaUri() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaUri', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByMediaUriDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaUri', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByPrescriptionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prescriptionType', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByPrescriptionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prescriptionType', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QAfterSortBy>
      thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension UserCatalogExerciseQueryWhereDistinct
    on QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct> {
  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByAliases() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aliases');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByDefaultDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultDurationSeconds');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByDefaultReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultReps');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByDefaultSets() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultSets');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByMediaKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaKind');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByMediaSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaSource');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByMediaUri({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaUri', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByPrescriptionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'prescriptionType');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByRegionIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'regionIds');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByTargetAreaIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetAreaIds');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<UserCatalogExercise, UserCatalogExercise, QDistinct>
      distinctByUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension UserCatalogExerciseQueryProperty
    on QueryBuilder<UserCatalogExercise, UserCatalogExercise, QQueryProperty> {
  QueryBuilder<UserCatalogExercise, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserCatalogExercise, List<String>, QQueryOperations>
      aliasesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aliases');
    });
  }

  QueryBuilder<UserCatalogExercise, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<UserCatalogExercise, int?, QQueryOperations>
      defaultDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultDurationSeconds');
    });
  }

  QueryBuilder<UserCatalogExercise, int?, QQueryOperations>
      defaultRepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultReps');
    });
  }

  QueryBuilder<UserCatalogExercise, int, QQueryOperations>
      defaultSetsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultSets');
    });
  }

  QueryBuilder<UserCatalogExercise, ExerciseMediaKind, QQueryOperations>
      mediaKindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaKind');
    });
  }

  QueryBuilder<UserCatalogExercise, ExerciseMediaSource, QQueryOperations>
      mediaSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaSource');
    });
  }

  QueryBuilder<UserCatalogExercise, String, QQueryOperations>
      mediaUriProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaUri');
    });
  }

  QueryBuilder<UserCatalogExercise, PrescriptionType, QQueryOperations>
      prescriptionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'prescriptionType');
    });
  }

  QueryBuilder<UserCatalogExercise, List<String>, QQueryOperations>
      regionIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'regionIds');
    });
  }

  QueryBuilder<UserCatalogExercise, List<String>, QQueryOperations>
      targetAreaIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetAreaIds');
    });
  }

  QueryBuilder<UserCatalogExercise, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<UserCatalogExercise, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<UserCatalogExercise, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
