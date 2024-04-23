// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_plan_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSinglePlanModelCollection on Isar {
  IsarCollection<SinglePlanModel> get singlePlanModels => this.collection();
}

const SinglePlanModelSchema = CollectionSchema(
  name: r'SinglePlanModel',
  id: -7542587888609286832,
  properties: {
    r'dayPlans': PropertySchema(
      id: 0,
      name: r'dayPlans',
      type: IsarType.objectList,
      target: r'SingleDayPlanModel',
    ),
    r'title': PropertySchema(
      id: 1,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _singlePlanModelEstimateSize,
  serialize: _singlePlanModelSerialize,
  deserialize: _singlePlanModelDeserialize,
  deserializeProp: _singlePlanModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {
    r'SingleDayPlanModel': SingleDayPlanModelSchema,
    r'SingleExerciseWithRound': SingleExerciseWithRoundSchema,
    r'ExerciseWithRepetitionModel': ExerciseWithRepetitionModelSchema
  },
  getId: _singlePlanModelGetId,
  getLinks: _singlePlanModelGetLinks,
  attach: _singlePlanModelAttach,
  version: '3.1.0+1',
);

int _singlePlanModelEstimateSize(
  SinglePlanModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dayPlans.length * 3;
  {
    final offsets = allOffsets[SingleDayPlanModel]!;
    for (var i = 0; i < object.dayPlans.length; i++) {
      final value = object.dayPlans[i];
      bytesCount +=
          SingleDayPlanModelSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _singlePlanModelSerialize(
  SinglePlanModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<SingleDayPlanModel>(
    offsets[0],
    allOffsets,
    SingleDayPlanModelSchema.serialize,
    object.dayPlans,
  );
  writer.writeString(offsets[1], object.title);
}

SinglePlanModel _singlePlanModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SinglePlanModel(
    dayPlans: reader.readObjectList<SingleDayPlanModel>(
          offsets[0],
          SingleDayPlanModelSchema.deserialize,
          allOffsets,
          SingleDayPlanModel(),
        ) ??
        [],
    title: reader.readString(offsets[1]),
  );
  object.id = id;
  return object;
}

P _singlePlanModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<SingleDayPlanModel>(
            offset,
            SingleDayPlanModelSchema.deserialize,
            allOffsets,
            SingleDayPlanModel(),
          ) ??
          []) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _singlePlanModelGetId(SinglePlanModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _singlePlanModelGetLinks(SinglePlanModel object) {
  return [];
}

void _singlePlanModelAttach(
    IsarCollection<dynamic> col, Id id, SinglePlanModel object) {
  object.id = id;
}

extension SinglePlanModelQueryWhereSort
    on QueryBuilder<SinglePlanModel, SinglePlanModel, QWhere> {
  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SinglePlanModelQueryWhere
    on QueryBuilder<SinglePlanModel, SinglePlanModel, QWhereClause> {
  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterWhereClause>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterWhereClause> idBetween(
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
}

extension SinglePlanModelQueryFilter
    on QueryBuilder<SinglePlanModel, SinglePlanModel, QFilterCondition> {
  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      dayPlansLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dayPlans',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      dayPlansIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dayPlans',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      dayPlansIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dayPlans',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      dayPlansLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dayPlans',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      dayPlansLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dayPlans',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      dayPlansLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dayPlans',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
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

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension SinglePlanModelQueryObject
    on QueryBuilder<SinglePlanModel, SinglePlanModel, QFilterCondition> {
  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterFilterCondition>
      dayPlansElement(FilterQuery<SingleDayPlanModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'dayPlans');
    });
  }
}

extension SinglePlanModelQueryLinks
    on QueryBuilder<SinglePlanModel, SinglePlanModel, QFilterCondition> {}

extension SinglePlanModelQuerySortBy
    on QueryBuilder<SinglePlanModel, SinglePlanModel, QSortBy> {
  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension SinglePlanModelQuerySortThenBy
    on QueryBuilder<SinglePlanModel, SinglePlanModel, QSortThenBy> {
  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<SinglePlanModel, SinglePlanModel, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension SinglePlanModelQueryWhereDistinct
    on QueryBuilder<SinglePlanModel, SinglePlanModel, QDistinct> {
  QueryBuilder<SinglePlanModel, SinglePlanModel, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension SinglePlanModelQueryProperty
    on QueryBuilder<SinglePlanModel, SinglePlanModel, QQueryProperty> {
  QueryBuilder<SinglePlanModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SinglePlanModel, List<SingleDayPlanModel>, QQueryOperations>
      dayPlansProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayPlans');
    });
  }

  QueryBuilder<SinglePlanModel, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SingleDayPlanModelSchema = Schema(
  name: r'SingleDayPlanModel',
  id: 4756645284885656512,
  properties: {
    r'exercises': PropertySchema(
      id: 0,
      name: r'exercises',
      type: IsarType.objectList,
      target: r'SingleExerciseWithRound',
    ),
    r'summary': PropertySchema(
      id: 1,
      name: r'summary',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 2,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _singleDayPlanModelEstimateSize,
  serialize: _singleDayPlanModelSerialize,
  deserialize: _singleDayPlanModelDeserialize,
  deserializeProp: _singleDayPlanModelDeserializeProp,
);

int _singleDayPlanModelEstimateSize(
  SingleDayPlanModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.exercises;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[SingleExerciseWithRound]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += SingleExerciseWithRoundSchema.estimateSize(
              value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.summary.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _singleDayPlanModelSerialize(
  SingleDayPlanModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<SingleExerciseWithRound>(
    offsets[0],
    allOffsets,
    SingleExerciseWithRoundSchema.serialize,
    object.exercises,
  );
  writer.writeString(offsets[1], object.summary);
  writer.writeString(offsets[2], object.title);
}

SingleDayPlanModel _singleDayPlanModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SingleDayPlanModel(
    exercises: reader.readObjectList<SingleExerciseWithRound>(
      offsets[0],
      SingleExerciseWithRoundSchema.deserialize,
      allOffsets,
      SingleExerciseWithRound(),
    ),
    summary: reader.readStringOrNull(offsets[1]) ?? '',
    title: reader.readStringOrNull(offsets[2]) ?? '',
  );
  return object;
}

P _singleDayPlanModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<SingleExerciseWithRound>(
        offset,
        SingleExerciseWithRoundSchema.deserialize,
        allOffsets,
        SingleExerciseWithRound(),
      )) as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 2:
      return (reader.readStringOrNull(offset) ?? '') as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SingleDayPlanModelQueryFilter
    on QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QFilterCondition> {
  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      exercisesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'exercises',
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      exercisesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'exercises',
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      exercisesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      exercisesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      exercisesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      exercisesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      exercisesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      exercisesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exercises',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'summary',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'summary',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'summary',
        value: '',
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      summaryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'summary',
        value: '',
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
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

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
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

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
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

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
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

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
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

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
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

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension SingleDayPlanModelQueryObject
    on QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QFilterCondition> {
  QueryBuilder<SingleDayPlanModel, SingleDayPlanModel, QAfterFilterCondition>
      exercisesElement(FilterQuery<SingleExerciseWithRound> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'exercises');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SingleExerciseWithRoundSchema = Schema(
  name: r'SingleExerciseWithRound',
  id: -1743916440714825489,
  properties: {
    r'exerciseWithRepetitionModels': PropertySchema(
      id: 0,
      name: r'exerciseWithRepetitionModels',
      type: IsarType.objectList,
      target: r'ExerciseWithRepetitionModel',
    ),
    r'roundNum': PropertySchema(
      id: 1,
      name: r'roundNum',
      type: IsarType.long,
    ),
    r'svgPath': PropertySchema(
      id: 2,
      name: r'svgPath',
      type: IsarType.string,
    )
  },
  estimateSize: _singleExerciseWithRoundEstimateSize,
  serialize: _singleExerciseWithRoundSerialize,
  deserialize: _singleExerciseWithRoundDeserialize,
  deserializeProp: _singleExerciseWithRoundDeserializeProp,
);

int _singleExerciseWithRoundEstimateSize(
  SingleExerciseWithRound object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.exerciseWithRepetitionModels;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[ExerciseWithRepetitionModel]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += ExerciseWithRepetitionModelSchema.estimateSize(
              value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.svgPath.length * 3;
  return bytesCount;
}

void _singleExerciseWithRoundSerialize(
  SingleExerciseWithRound object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<ExerciseWithRepetitionModel>(
    offsets[0],
    allOffsets,
    ExerciseWithRepetitionModelSchema.serialize,
    object.exerciseWithRepetitionModels,
  );
  writer.writeLong(offsets[1], object.roundNum);
  writer.writeString(offsets[2], object.svgPath);
}

SingleExerciseWithRound _singleExerciseWithRoundDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SingleExerciseWithRound(
    exerciseWithRepetitionModels:
        reader.readObjectList<ExerciseWithRepetitionModel>(
      offsets[0],
      ExerciseWithRepetitionModelSchema.deserialize,
      allOffsets,
      ExerciseWithRepetitionModel(),
    ),
    roundNum: reader.readLongOrNull(offsets[1]) ?? 1,
    svgPath: reader.readStringOrNull(offsets[2]) ?? '',
  );
  return object;
}

P _singleExerciseWithRoundDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<ExerciseWithRepetitionModel>(
        offset,
        ExerciseWithRepetitionModelSchema.deserialize,
        allOffsets,
        ExerciseWithRepetitionModel(),
      )) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 2:
      return (reader.readStringOrNull(offset) ?? '') as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SingleExerciseWithRoundQueryFilter on QueryBuilder<
    SingleExerciseWithRound, SingleExerciseWithRound, QFilterCondition> {
  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> exerciseWithRepetitionModelsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'exerciseWithRepetitionModels',
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> exerciseWithRepetitionModelsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'exerciseWithRepetitionModels',
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
          QAfterFilterCondition>
      exerciseWithRepetitionModelsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exerciseWithRepetitionModels',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> exerciseWithRepetitionModelsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exerciseWithRepetitionModels',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> exerciseWithRepetitionModelsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exerciseWithRepetitionModels',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> exerciseWithRepetitionModelsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exerciseWithRepetitionModels',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> exerciseWithRepetitionModelsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exerciseWithRepetitionModels',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> exerciseWithRepetitionModelsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'exerciseWithRepetitionModels',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> roundNumEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'roundNum',
        value: value,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> roundNumGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'roundNum',
        value: value,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> roundNumLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'roundNum',
        value: value,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> roundNumBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'roundNum',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> svgPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'svgPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> svgPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'svgPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> svgPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'svgPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> svgPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'svgPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> svgPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'svgPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> svgPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'svgPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
          QAfterFilterCondition>
      svgPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'svgPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
          QAfterFilterCondition>
      svgPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'svgPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> svgPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'svgPath',
        value: '',
      ));
    });
  }

  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
      QAfterFilterCondition> svgPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'svgPath',
        value: '',
      ));
    });
  }
}

extension SingleExerciseWithRoundQueryObject on QueryBuilder<
    SingleExerciseWithRound, SingleExerciseWithRound, QFilterCondition> {
  QueryBuilder<SingleExerciseWithRound, SingleExerciseWithRound,
          QAfterFilterCondition>
      exerciseWithRepetitionModelsElement(
          FilterQuery<ExerciseWithRepetitionModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'exerciseWithRepetitionModels');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ExerciseWithRepetitionModelSchema = Schema(
  name: r'ExerciseWithRepetitionModel',
  id: -3258930914677425157,
  properties: {
    r'repetition': PropertySchema(
      id: 0,
      name: r'repetition',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 1,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _exerciseWithRepetitionModelEstimateSize,
  serialize: _exerciseWithRepetitionModelSerialize,
  deserialize: _exerciseWithRepetitionModelDeserialize,
  deserializeProp: _exerciseWithRepetitionModelDeserializeProp,
);

int _exerciseWithRepetitionModelEstimateSize(
  ExerciseWithRepetitionModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _exerciseWithRepetitionModelSerialize(
  ExerciseWithRepetitionModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.repetition);
  writer.writeString(offsets[1], object.title);
}

ExerciseWithRepetitionModel _exerciseWithRepetitionModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExerciseWithRepetitionModel(
    repetition: reader.readLongOrNull(offsets[0]) ?? 1,
    title: reader.readStringOrNull(offsets[1]) ?? '',
  );
  return object;
}

P _exerciseWithRepetitionModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? '') as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ExerciseWithRepetitionModelQueryFilter on QueryBuilder<
    ExerciseWithRepetitionModel,
    ExerciseWithRepetitionModel,
    QFilterCondition> {
  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> repetitionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repetition',
        value: value,
      ));
    });
  }

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> repetitionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repetition',
        value: value,
      ));
    });
  }

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> repetitionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repetition',
        value: value,
      ));
    });
  }

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> repetitionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repetition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> titleEqualTo(
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

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> titleGreaterThan(
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

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> titleLessThan(
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

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> titleBetween(
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

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> titleStartsWith(
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

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> titleEndsWith(
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

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
          QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
          QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseWithRepetitionModel, ExerciseWithRepetitionModel,
      QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension ExerciseWithRepetitionModelQueryObject on QueryBuilder<
    ExerciseWithRepetitionModel,
    ExerciseWithRepetitionModel,
    QFilterCondition> {}
