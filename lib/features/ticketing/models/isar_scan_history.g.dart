// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_scan_history.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarScanHistoryCollection on Isar {
  IsarCollection<IsarScanHistory> get isarScanHistorys => this.collection();
}

const IsarScanHistorySchema = CollectionSchema(
  name: r'IsarScanHistory',
  id: -3434376923004274811,
  properties: {
    r'eventId': PropertySchema(
      id: 0,
      name: r'eventId',
      type: IsarType.long,
    ),
    r'scannedAt': PropertySchema(
      id: 1,
      name: r'scannedAt',
      type: IsarType.dateTime,
    ),
    r'ticketId': PropertySchema(
      id: 2,
      name: r'ticketId',
      type: IsarType.string,
    )
  },
  estimateSize: _isarScanHistoryEstimateSize,
  serialize: _isarScanHistorySerialize,
  deserialize: _isarScanHistoryDeserialize,
  deserializeProp: _isarScanHistoryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _isarScanHistoryGetId,
  getLinks: _isarScanHistoryGetLinks,
  attach: _isarScanHistoryAttach,
  version: '3.1.0+1',
);

int _isarScanHistoryEstimateSize(
  IsarScanHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.ticketId.length * 3;
  return bytesCount;
}

void _isarScanHistorySerialize(
  IsarScanHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.eventId);
  writer.writeDateTime(offsets[1], object.scannedAt);
  writer.writeString(offsets[2], object.ticketId);
}

IsarScanHistory _isarScanHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarScanHistory(
    eventId: reader.readLong(offsets[0]),
    scannedAt: reader.readDateTime(offsets[1]),
    ticketId: reader.readString(offsets[2]),
  );
  object.id = id;
  return object;
}

P _isarScanHistoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarScanHistoryGetId(IsarScanHistory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarScanHistoryGetLinks(IsarScanHistory object) {
  return [];
}

void _isarScanHistoryAttach(
    IsarCollection<dynamic> col, Id id, IsarScanHistory object) {
  object.id = id;
}

extension IsarScanHistoryQueryWhereSort
    on QueryBuilder<IsarScanHistory, IsarScanHistory, QWhere> {
  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarScanHistoryQueryWhere
    on QueryBuilder<IsarScanHistory, IsarScanHistory, QWhereClause> {
  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterWhereClause>
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

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterWhereClause> idBetween(
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

extension IsarScanHistoryQueryFilter
    on QueryBuilder<IsarScanHistory, IsarScanHistory, QFilterCondition> {
  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      eventIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
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

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
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

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
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

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
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

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
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

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
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

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      scannedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scannedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      scannedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scannedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      scannedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scannedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      scannedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scannedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticketId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ticketId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ticketId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ticketId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ticketId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ticketId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ticketId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ticketId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticketId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterFilterCondition>
      ticketIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ticketId',
        value: '',
      ));
    });
  }
}

extension IsarScanHistoryQueryObject
    on QueryBuilder<IsarScanHistory, IsarScanHistory, QFilterCondition> {}

extension IsarScanHistoryQueryLinks
    on QueryBuilder<IsarScanHistory, IsarScanHistory, QFilterCondition> {}

extension IsarScanHistoryQuerySortBy
    on QueryBuilder<IsarScanHistory, IsarScanHistory, QSortBy> {
  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy> sortByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      sortByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      sortByScannedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scannedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      sortByScannedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scannedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      sortByTicketId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketId', Sort.asc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      sortByTicketIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketId', Sort.desc);
    });
  }
}

extension IsarScanHistoryQuerySortThenBy
    on QueryBuilder<IsarScanHistory, IsarScanHistory, QSortThenBy> {
  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy> thenByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      thenByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      thenByScannedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scannedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      thenByScannedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scannedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      thenByTicketId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketId', Sort.asc);
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QAfterSortBy>
      thenByTicketIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketId', Sort.desc);
    });
  }
}

extension IsarScanHistoryQueryWhereDistinct
    on QueryBuilder<IsarScanHistory, IsarScanHistory, QDistinct> {
  QueryBuilder<IsarScanHistory, IsarScanHistory, QDistinct>
      distinctByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventId');
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QDistinct>
      distinctByScannedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scannedAt');
    });
  }

  QueryBuilder<IsarScanHistory, IsarScanHistory, QDistinct> distinctByTicketId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ticketId', caseSensitive: caseSensitive);
    });
  }
}

extension IsarScanHistoryQueryProperty
    on QueryBuilder<IsarScanHistory, IsarScanHistory, QQueryProperty> {
  QueryBuilder<IsarScanHistory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarScanHistory, int, QQueryOperations> eventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventId');
    });
  }

  QueryBuilder<IsarScanHistory, DateTime, QQueryOperations>
      scannedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scannedAt');
    });
  }

  QueryBuilder<IsarScanHistory, String, QQueryOperations> ticketIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ticketId');
    });
  }
}
