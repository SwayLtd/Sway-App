// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_online_ticket.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOnlineTicketIsarCollection on Isar {
  IsarCollection<OnlineTicketIsar> get onlineTicketIsars => this.collection();
}

const OnlineTicketIsarSchema = CollectionSchema(
  name: r'OnlineTicketIsar',
  id: -7156774248571878618,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'eventId': PropertySchema(
      id: 1,
      name: r'eventId',
      type: IsarType.long,
    ),
    r'groupId': PropertySchema(
      id: 2,
      name: r'groupId',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'qrCodePath': PropertySchema(
      id: 4,
      name: r'qrCodePath',
      type: IsarType.string,
    ),
    r'ticketType': PropertySchema(
      id: 5,
      name: r'ticketType',
      type: IsarType.string,
    ),
    r'used': PropertySchema(
      id: 6,
      name: r'used',
      type: IsarType.bool,
    ),
    r'usedAt': PropertySchema(
      id: 7,
      name: r'usedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _onlineTicketIsarEstimateSize,
  serialize: _onlineTicketIsarSerialize,
  deserialize: _onlineTicketIsarDeserialize,
  deserializeProp: _onlineTicketIsarDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _onlineTicketIsarGetId,
  getLinks: _onlineTicketIsarGetLinks,
  attach: _onlineTicketIsarAttach,
  version: '3.1.0+1',
);

int _onlineTicketIsarEstimateSize(
  OnlineTicketIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.groupId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.qrCodePath.length * 3;
  {
    final value = object.ticketType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _onlineTicketIsarSerialize(
  OnlineTicketIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.eventId);
  writer.writeString(offsets[2], object.groupId);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.qrCodePath);
  writer.writeString(offsets[5], object.ticketType);
  writer.writeBool(offsets[6], object.used);
  writer.writeDateTime(offsets[7], object.usedAt);
}

OnlineTicketIsar _onlineTicketIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OnlineTicketIsar(
    createdAt: reader.readDateTime(offsets[0]),
    eventId: reader.readLong(offsets[1]),
    groupId: reader.readStringOrNull(offsets[2]),
    id: reader.readString(offsets[3]),
    qrCodePath: reader.readString(offsets[4]),
    ticketType: reader.readStringOrNull(offsets[5]),
    used: reader.readBool(offsets[6]),
    usedAt: reader.readDateTimeOrNull(offsets[7]),
  );
  object.isarId = id;
  return object;
}

P _onlineTicketIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _onlineTicketIsarGetId(OnlineTicketIsar object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _onlineTicketIsarGetLinks(OnlineTicketIsar object) {
  return [];
}

void _onlineTicketIsarAttach(
    IsarCollection<dynamic> col, Id id, OnlineTicketIsar object) {
  object.isarId = id;
}

extension OnlineTicketIsarByIndex on IsarCollection<OnlineTicketIsar> {
  Future<OnlineTicketIsar?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  OnlineTicketIsar? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<OnlineTicketIsar?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<OnlineTicketIsar?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(OnlineTicketIsar object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(OnlineTicketIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<OnlineTicketIsar> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<OnlineTicketIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension OnlineTicketIsarQueryWhereSort
    on QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QWhere> {
  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OnlineTicketIsarQueryWhere
    on QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QWhereClause> {
  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterWhereClause>
      idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OnlineTicketIsarQueryFilter
    on QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QFilterCondition> {
  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
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

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
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

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
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

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      eventIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventId',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      eventIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventId',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      eventIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventId',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      eventIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupId',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupId',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupId',
        value: '',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      groupIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupId',
        value: '',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'qrCodePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'qrCodePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'qrCodePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'qrCodePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'qrCodePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'qrCodePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'qrCodePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'qrCodePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'qrCodePath',
        value: '',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      qrCodePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'qrCodePath',
        value: '',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ticketType',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ticketType',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ticketType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ticketType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticketType',
        value: '',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      ticketTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ticketType',
        value: '',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      usedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'used',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      usedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'usedAt',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      usedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'usedAt',
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      usedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      usedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      usedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterFilterCondition>
      usedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OnlineTicketIsarQueryObject
    on QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QFilterCondition> {}

extension OnlineTicketIsarQueryLinks
    on QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QFilterCondition> {}

extension OnlineTicketIsarQuerySortBy
    on QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QSortBy> {
  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByQrCodePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrCodePath', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByQrCodePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrCodePath', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByTicketType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketType', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByTicketTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketType', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy> sortByUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'used', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'used', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedAt', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      sortByUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedAt', Sort.desc);
    });
  }
}

extension OnlineTicketIsarQuerySortThenBy
    on QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QSortThenBy> {
  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByQrCodePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrCodePath', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByQrCodePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qrCodePath', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByTicketType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketType', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByTicketTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketType', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy> thenByUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'used', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'used', Sort.desc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedAt', Sort.asc);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QAfterSortBy>
      thenByUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedAt', Sort.desc);
    });
  }
}

extension OnlineTicketIsarQueryWhereDistinct
    on QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QDistinct> {
  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QDistinct>
      distinctByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventId');
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QDistinct> distinctByGroupId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QDistinct>
      distinctByQrCodePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'qrCodePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QDistinct>
      distinctByTicketType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ticketType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QDistinct> distinctByUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'used');
    });
  }

  QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QDistinct>
      distinctByUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usedAt');
    });
  }
}

extension OnlineTicketIsarQueryProperty
    on QueryBuilder<OnlineTicketIsar, OnlineTicketIsar, QQueryProperty> {
  QueryBuilder<OnlineTicketIsar, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<OnlineTicketIsar, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OnlineTicketIsar, int, QQueryOperations> eventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventId');
    });
  }

  QueryBuilder<OnlineTicketIsar, String?, QQueryOperations> groupIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupId');
    });
  }

  QueryBuilder<OnlineTicketIsar, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OnlineTicketIsar, String, QQueryOperations>
      qrCodePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'qrCodePath');
    });
  }

  QueryBuilder<OnlineTicketIsar, String?, QQueryOperations>
      ticketTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ticketType');
    });
  }

  QueryBuilder<OnlineTicketIsar, bool, QQueryOperations> usedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'used');
    });
  }

  QueryBuilder<OnlineTicketIsar, DateTime?, QQueryOperations> usedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usedAt');
    });
  }
}
