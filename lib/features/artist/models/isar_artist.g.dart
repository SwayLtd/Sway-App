// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_artist.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarArtistCollection on Isar {
  IsarCollection<IsarArtist> get isarArtists => this.collection();
}

const IsarArtistSchema = CollectionSchema(
  name: r'IsarArtist',
  id: -7076447970192203452,
  properties: {
    r'description': PropertySchema(
      id: 0,
      name: r'description',
      type: IsarType.string,
    ),
    r'followers': PropertySchema(
      id: 1,
      name: r'followers',
      type: IsarType.long,
    ),
    r'imageUrl': PropertySchema(
      id: 2,
      name: r'imageUrl',
      type: IsarType.string,
    ),
    r'isFollowing': PropertySchema(
      id: 3,
      name: r'isFollowing',
      type: IsarType.bool,
    ),
    r'isVerified': PropertySchema(
      id: 4,
      name: r'isVerified',
      type: IsarType.bool,
    ),
    r'linksJson': PropertySchema(
      id: 5,
      name: r'linksJson',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(
      id: 7,
      name: r'remoteId',
      type: IsarType.long,
    )
  },
  estimateSize: _isarArtistEstimateSize,
  serialize: _isarArtistSerialize,
  deserialize: _isarArtistDeserialize,
  deserializeProp: _isarArtistDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'genres': LinkSchema(
      id: -9025766775009033222,
      name: r'genres',
      target: r'IsarGenre',
      single: false,
    ),
    r'upcomingEvents': LinkSchema(
      id: 5417986563825797992,
      name: r'upcomingEvents',
      target: r'IsarEvent',
      single: false,
    ),
    r'similarArtists': LinkSchema(
      id: 15225984628958759,
      name: r'similarArtists',
      target: r'IsarArtist',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _isarArtistGetId,
  getLinks: _isarArtistGetLinks,
  attach: _isarArtistAttach,
  version: '3.1.0+1',
);

int _isarArtistEstimateSize(
  IsarArtist object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.imageUrl.length * 3;
  bytesCount += 3 + object.linksJson.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _isarArtistSerialize(
  IsarArtist object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.description);
  writer.writeLong(offsets[1], object.followers);
  writer.writeString(offsets[2], object.imageUrl);
  writer.writeBool(offsets[3], object.isFollowing);
  writer.writeBool(offsets[4], object.isVerified);
  writer.writeString(offsets[5], object.linksJson);
  writer.writeString(offsets[6], object.name);
  writer.writeLong(offsets[7], object.remoteId);
}

IsarArtist _isarArtistDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarArtist();
  object.description = reader.readString(offsets[0]);
  object.followers = reader.readLong(offsets[1]);
  object.id = id;
  object.imageUrl = reader.readString(offsets[2]);
  object.isFollowing = reader.readBool(offsets[3]);
  object.isVerified = reader.readBool(offsets[4]);
  object.linksJson = reader.readString(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.remoteId = reader.readLong(offsets[7]);
  return object;
}

P _isarArtistDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarArtistGetId(IsarArtist object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarArtistGetLinks(IsarArtist object) {
  return [object.genres, object.upcomingEvents, object.similarArtists];
}

void _isarArtistAttach(IsarCollection<dynamic> col, Id id, IsarArtist object) {
  object.id = id;
  object.genres.attach(col, col.isar.collection<IsarGenre>(), r'genres', id);
  object.upcomingEvents
      .attach(col, col.isar.collection<IsarEvent>(), r'upcomingEvents', id);
  object.similarArtists
      .attach(col, col.isar.collection<IsarArtist>(), r'similarArtists', id);
}

extension IsarArtistQueryWhereSort
    on QueryBuilder<IsarArtist, IsarArtist, QWhere> {
  QueryBuilder<IsarArtist, IsarArtist, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarArtistQueryWhere
    on QueryBuilder<IsarArtist, IsarArtist, QWhereClause> {
  QueryBuilder<IsarArtist, IsarArtist, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterWhereClause> idBetween(
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

extension IsarArtistQueryFilter
    on QueryBuilder<IsarArtist, IsarArtist, QFilterCondition> {
  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      descriptionEqualTo(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      descriptionLessThan(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      descriptionBetween(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      descriptionEndsWith(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> followersEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followers',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      followersGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followers',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> followersLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followers',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> followersBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> imageUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      imageUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> imageUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> imageUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      imageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> imageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> imageUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> imageUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      imageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      imageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      isFollowingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFollowing',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> isVerifiedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isVerified',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> linksJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      linksJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'linksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> linksJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'linksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> linksJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'linksJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      linksJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'linksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> linksJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'linksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> linksJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'linksJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> linksJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'linksJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      linksJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linksJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      linksJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'linksJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameContains(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> remoteIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      remoteIdGreaterThan(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> remoteIdLessThan(
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

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> remoteIdBetween(
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

extension IsarArtistQueryObject
    on QueryBuilder<IsarArtist, IsarArtist, QFilterCondition> {}

extension IsarArtistQueryLinks
    on QueryBuilder<IsarArtist, IsarArtist, QFilterCondition> {
  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> genres(
      FilterQuery<IsarGenre> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'genres');
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      genresLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'genres', length, true, length, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> genresIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'genres', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      genresIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'genres', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      genresLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'genres', 0, true, length, include);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      genresLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'genres', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      genresLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'genres', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> upcomingEvents(
      FilterQuery<IsarEvent> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'upcomingEvents');
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      upcomingEventsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'upcomingEvents', length, true, length, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      upcomingEventsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'upcomingEvents', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      upcomingEventsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'upcomingEvents', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      upcomingEventsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'upcomingEvents', 0, true, length, include);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      upcomingEventsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'upcomingEvents', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      upcomingEventsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'upcomingEvents', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition> similarArtists(
      FilterQuery<IsarArtist> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'similarArtists');
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      similarArtistsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'similarArtists', length, true, length, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      similarArtistsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'similarArtists', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      similarArtistsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'similarArtists', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      similarArtistsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'similarArtists', 0, true, length, include);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      similarArtistsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'similarArtists', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterFilterCondition>
      similarArtistsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'similarArtists', lower, includeLower, upper, includeUpper);
    });
  }
}

extension IsarArtistQuerySortBy
    on QueryBuilder<IsarArtist, IsarArtist, QSortBy> {
  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByFollowers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followers', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByFollowersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followers', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByIsFollowing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFollowing', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByIsFollowingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFollowing', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByIsVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVerified', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByIsVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVerified', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByLinksJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linksJson', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByLinksJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linksJson', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }
}

extension IsarArtistQuerySortThenBy
    on QueryBuilder<IsarArtist, IsarArtist, QSortThenBy> {
  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByFollowers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followers', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByFollowersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followers', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByIsFollowing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFollowing', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByIsFollowingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFollowing', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByIsVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVerified', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByIsVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVerified', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByLinksJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linksJson', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByLinksJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linksJson', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QAfterSortBy> thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }
}

extension IsarArtistQueryWhereDistinct
    on QueryBuilder<IsarArtist, IsarArtist, QDistinct> {
  QueryBuilder<IsarArtist, IsarArtist, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QDistinct> distinctByFollowers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followers');
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QDistinct> distinctByImageUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QDistinct> distinctByIsFollowing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFollowing');
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QDistinct> distinctByIsVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isVerified');
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QDistinct> distinctByLinksJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linksJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarArtist, IsarArtist, QDistinct> distinctByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId');
    });
  }
}

extension IsarArtistQueryProperty
    on QueryBuilder<IsarArtist, IsarArtist, QQueryProperty> {
  QueryBuilder<IsarArtist, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarArtist, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<IsarArtist, int, QQueryOperations> followersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followers');
    });
  }

  QueryBuilder<IsarArtist, String, QQueryOperations> imageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageUrl');
    });
  }

  QueryBuilder<IsarArtist, bool, QQueryOperations> isFollowingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFollowing');
    });
  }

  QueryBuilder<IsarArtist, bool, QQueryOperations> isVerifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isVerified');
    });
  }

  QueryBuilder<IsarArtist, String, QQueryOperations> linksJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linksJson');
    });
  }

  QueryBuilder<IsarArtist, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarArtist, int, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }
}
