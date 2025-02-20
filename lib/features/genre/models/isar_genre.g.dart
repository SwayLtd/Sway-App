// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_genre.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarGenreCollection on Isar {
  IsarCollection<IsarGenre> get isarGenres => this.collection();
}

const IsarGenreSchema = CollectionSchema(
  name: r'IsarGenre',
  id: 972541083253672909,
  properties: {
    r'description': PropertySchema(
      id: 0,
      name: r'description',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(
      id: 2,
      name: r'remoteId',
      type: IsarType.long,
    )
  },
  estimateSize: _isarGenreEstimateSize,
  serialize: _isarGenreSerialize,
  deserialize: _isarGenreDeserialize,
  deserializeProp: _isarGenreDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'artists': LinkSchema(
      id: -667153466293447109,
      name: r'artists',
      target: r'IsarArtist',
      single: false,
      linkName: r'genres',
    ),
    r'events': LinkSchema(
      id: -2758948365318094373,
      name: r'events',
      target: r'IsarEvent',
      single: false,
      linkName: r'genres',
    ),
    r'promoters': LinkSchema(
      id: 7792008148579055671,
      name: r'promoters',
      target: r'IsarPromoter',
      single: false,
      linkName: r'genres',
    ),
    r'venues': LinkSchema(
      id: -3776952056420382954,
      name: r'venues',
      target: r'IsarVenue',
      single: false,
      linkName: r'genres',
    )
  },
  embeddedSchemas: {},
  getId: _isarGenreGetId,
  getLinks: _isarGenreGetLinks,
  attach: _isarGenreAttach,
  version: '3.1.0+1',
);

int _isarGenreEstimateSize(
  IsarGenre object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _isarGenreSerialize(
  IsarGenre object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.description);
  writer.writeString(offsets[1], object.name);
  writer.writeLong(offsets[2], object.remoteId);
}

IsarGenre _isarGenreDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarGenre();
  object.description = reader.readString(offsets[0]);
  object.id = id;
  object.name = reader.readString(offsets[1]);
  object.remoteId = reader.readLong(offsets[2]);
  return object;
}

P _isarGenreDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarGenreGetId(IsarGenre object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarGenreGetLinks(IsarGenre object) {
  return [object.artists, object.events, object.promoters, object.venues];
}

void _isarGenreAttach(IsarCollection<dynamic> col, Id id, IsarGenre object) {
  object.id = id;
  object.artists.attach(col, col.isar.collection<IsarArtist>(), r'artists', id);
  object.events.attach(col, col.isar.collection<IsarEvent>(), r'events', id);
  object.promoters
      .attach(col, col.isar.collection<IsarPromoter>(), r'promoters', id);
  object.venues.attach(col, col.isar.collection<IsarVenue>(), r'venues', id);
}

extension IsarGenreQueryWhereSort
    on QueryBuilder<IsarGenre, IsarGenre, QWhere> {
  QueryBuilder<IsarGenre, IsarGenre, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarGenreQueryWhere
    on QueryBuilder<IsarGenre, IsarGenre, QWhereClause> {
  QueryBuilder<IsarGenre, IsarGenre, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<IsarGenre, IsarGenre, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterWhereClause> idBetween(
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

extension IsarGenreQueryFilter
    on QueryBuilder<IsarGenre, IsarGenre, QFilterCondition> {
  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> remoteIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> remoteIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> remoteIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> remoteIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarGenreQueryObject
    on QueryBuilder<IsarGenre, IsarGenre, QFilterCondition> {}

extension IsarGenreQueryLinks
    on QueryBuilder<IsarGenre, IsarGenre, QFilterCondition> {
  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> artists(
      FilterQuery<IsarArtist> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'artists');
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      artistsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'artists', length, true, length, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> artistsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'artists', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      artistsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'artists', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      artistsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'artists', 0, true, length, include);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      artistsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'artists', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      artistsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'artists', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> events(
      FilterQuery<IsarEvent> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'events');
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> eventsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'events', length, true, length, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> eventsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'events', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> eventsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'events', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      eventsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'events', 0, true, length, include);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      eventsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'events', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> eventsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'events', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> promoters(
      FilterQuery<IsarPromoter> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'promoters');
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      promotersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'promoters', length, true, length, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> promotersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'promoters', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      promotersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'promoters', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      promotersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'promoters', 0, true, length, include);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      promotersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'promoters', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      promotersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'promoters', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> venues(
      FilterQuery<IsarVenue> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'venues');
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> venuesLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'venues', length, true, length, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> venuesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'venues', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> venuesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'venues', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      venuesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'venues', 0, true, length, include);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition>
      venuesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'venues', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterFilterCondition> venuesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'venues', lower, includeLower, upper, includeUpper);
    });
  }
}

extension IsarGenreQuerySortBy on QueryBuilder<IsarGenre, IsarGenre, QSortBy> {
  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }
}

extension IsarGenreQuerySortThenBy
    on QueryBuilder<IsarGenre, IsarGenre, QSortThenBy> {
  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QAfterSortBy> thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }
}

extension IsarGenreQueryWhereDistinct
    on QueryBuilder<IsarGenre, IsarGenre, QDistinct> {
  QueryBuilder<IsarGenre, IsarGenre, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGenre, IsarGenre, QDistinct> distinctByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId');
    });
  }
}

extension IsarGenreQueryProperty
    on QueryBuilder<IsarGenre, IsarGenre, QQueryProperty> {
  QueryBuilder<IsarGenre, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarGenre, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<IsarGenre, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarGenre, int, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }
}
