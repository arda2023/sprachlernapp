// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_database.dart';

// ignore_for_file: type=lint
class $UserCardsTable extends UserCards
    with TableInfo<$UserCardsTable, UserCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _inPlaylistMeta = const VerificationMeta(
    'inPlaylist',
  );
  @override
  late final GeneratedColumn<bool> inPlaylist = GeneratedColumn<bool>(
    'in_playlist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_playlist" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localOnlyMeta = const VerificationMeta(
    'localOnly',
  );
  @override
  late final GeneratedColumn<bool> localOnly = GeneratedColumn<bool>(
    'local_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _boxMeta = const VerificationMeta('box');
  @override
  late final GeneratedColumn<int> box = GeneratedColumn<int>(
    'box',
    aliasedName,
    false,
    check: () => const CustomExpression('box BETWEEN 0 AND 5'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    check: () => const CustomExpression("origin IN ('deck', 'story')"),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disabledMeta = const VerificationMeta(
    'disabled',
  );
  @override
  late final GeneratedColumn<bool> disabled = GeneratedColumn<bool>(
    'disabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("disabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _retiredMeta = const VerificationMeta(
    'retired',
  );
  @override
  late final GeneratedColumn<bool> retired = GeneratedColumn<bool>(
    'retired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    note,
    inPlaylist,
    cardId,
    lang,
    localOnly,
    box,
    dueAt,
    createdAt,
    origin,
    disabled,
    favorite,
    retired,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('in_playlist')) {
      context.handle(
        _inPlaylistMeta,
        inPlaylist.isAcceptableOrUnknown(data['in_playlist']!, _inPlaylistMeta),
      );
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('local_only')) {
      context.handle(
        _localOnlyMeta,
        localOnly.isAcceptableOrUnknown(data['local_only']!, _localOnlyMeta),
      );
    }
    if (data.containsKey('box')) {
      context.handle(
        _boxMeta,
        box.isAcceptableOrUnknown(data['box']!, _boxMeta),
      );
    } else if (isInserting) {
      context.missing(_boxMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('disabled')) {
      context.handle(
        _disabledMeta,
        disabled.isAcceptableOrUnknown(data['disabled']!, _disabledMeta),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('retired')) {
      context.handle(
        _retiredMeta,
        retired.isAcceptableOrUnknown(data['retired']!, _retiredMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  UserCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserCardRow(
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      inPlaylist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_playlist'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      localOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_only'],
      )!,
      box: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      disabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}disabled'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      retired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retired'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserCardsTable createAlias(String alias) {
    return $UserCardsTable(attachedDatabase, alias);
  }
}

class UserCardRow extends DataClass implements Insertable<UserCardRow> {
  final String note;
  final bool inPlaylist;
  final String cardId;
  final String lang;
  final bool localOnly;
  final int box;

  /// Start of a local day; null only in box 0.
  final DateTime? dueAt;
  final DateTime createdAt;
  final String origin;
  final bool disabled;
  final bool favorite;
  final bool retired;
  final DateTime updatedAt;
  const UserCardRow({
    required this.note,
    required this.inPlaylist,
    required this.cardId,
    required this.lang,
    required this.localOnly,
    required this.box,
    this.dueAt,
    required this.createdAt,
    required this.origin,
    required this.disabled,
    required this.favorite,
    required this.retired,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note'] = Variable<String>(note);
    map['in_playlist'] = Variable<bool>(inPlaylist);
    map['card_id'] = Variable<String>(cardId);
    map['lang'] = Variable<String>(lang);
    map['local_only'] = Variable<bool>(localOnly);
    map['box'] = Variable<int>(box);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['origin'] = Variable<String>(origin);
    map['disabled'] = Variable<bool>(disabled);
    map['favorite'] = Variable<bool>(favorite);
    map['retired'] = Variable<bool>(retired);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserCardsCompanion toCompanion(bool nullToAbsent) {
    return UserCardsCompanion(
      note: Value(note),
      inPlaylist: Value(inPlaylist),
      cardId: Value(cardId),
      lang: Value(lang),
      localOnly: Value(localOnly),
      box: Value(box),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      createdAt: Value(createdAt),
      origin: Value(origin),
      disabled: Value(disabled),
      favorite: Value(favorite),
      retired: Value(retired),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserCardRow(
      note: serializer.fromJson<String>(json['note']),
      inPlaylist: serializer.fromJson<bool>(json['inPlaylist']),
      cardId: serializer.fromJson<String>(json['cardId']),
      lang: serializer.fromJson<String>(json['lang']),
      localOnly: serializer.fromJson<bool>(json['localOnly']),
      box: serializer.fromJson<int>(json['box']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      origin: serializer.fromJson<String>(json['origin']),
      disabled: serializer.fromJson<bool>(json['disabled']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      retired: serializer.fromJson<bool>(json['retired']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'note': serializer.toJson<String>(note),
      'inPlaylist': serializer.toJson<bool>(inPlaylist),
      'cardId': serializer.toJson<String>(cardId),
      'lang': serializer.toJson<String>(lang),
      'localOnly': serializer.toJson<bool>(localOnly),
      'box': serializer.toJson<int>(box),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'origin': serializer.toJson<String>(origin),
      'disabled': serializer.toJson<bool>(disabled),
      'favorite': serializer.toJson<bool>(favorite),
      'retired': serializer.toJson<bool>(retired),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserCardRow copyWith({
    String? note,
    bool? inPlaylist,
    String? cardId,
    String? lang,
    bool? localOnly,
    int? box,
    Value<DateTime?> dueAt = const Value.absent(),
    DateTime? createdAt,
    String? origin,
    bool? disabled,
    bool? favorite,
    bool? retired,
    DateTime? updatedAt,
  }) => UserCardRow(
    note: note ?? this.note,
    inPlaylist: inPlaylist ?? this.inPlaylist,
    cardId: cardId ?? this.cardId,
    lang: lang ?? this.lang,
    localOnly: localOnly ?? this.localOnly,
    box: box ?? this.box,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    createdAt: createdAt ?? this.createdAt,
    origin: origin ?? this.origin,
    disabled: disabled ?? this.disabled,
    favorite: favorite ?? this.favorite,
    retired: retired ?? this.retired,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserCardRow copyWithCompanion(UserCardsCompanion data) {
    return UserCardRow(
      note: data.note.present ? data.note.value : this.note,
      inPlaylist: data.inPlaylist.present
          ? data.inPlaylist.value
          : this.inPlaylist,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      lang: data.lang.present ? data.lang.value : this.lang,
      localOnly: data.localOnly.present ? data.localOnly.value : this.localOnly,
      box: data.box.present ? data.box.value : this.box,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      origin: data.origin.present ? data.origin.value : this.origin,
      disabled: data.disabled.present ? data.disabled.value : this.disabled,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      retired: data.retired.present ? data.retired.value : this.retired,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserCardRow(')
          ..write('note: $note, ')
          ..write('inPlaylist: $inPlaylist, ')
          ..write('cardId: $cardId, ')
          ..write('lang: $lang, ')
          ..write('localOnly: $localOnly, ')
          ..write('box: $box, ')
          ..write('dueAt: $dueAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('origin: $origin, ')
          ..write('disabled: $disabled, ')
          ..write('favorite: $favorite, ')
          ..write('retired: $retired, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    note,
    inPlaylist,
    cardId,
    lang,
    localOnly,
    box,
    dueAt,
    createdAt,
    origin,
    disabled,
    favorite,
    retired,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserCardRow &&
          other.note == this.note &&
          other.inPlaylist == this.inPlaylist &&
          other.cardId == this.cardId &&
          other.lang == this.lang &&
          other.localOnly == this.localOnly &&
          other.box == this.box &&
          other.dueAt == this.dueAt &&
          other.createdAt == this.createdAt &&
          other.origin == this.origin &&
          other.disabled == this.disabled &&
          other.favorite == this.favorite &&
          other.retired == this.retired &&
          other.updatedAt == this.updatedAt);
}

class UserCardsCompanion extends UpdateCompanion<UserCardRow> {
  final Value<String> note;
  final Value<bool> inPlaylist;
  final Value<String> cardId;
  final Value<String> lang;
  final Value<bool> localOnly;
  final Value<int> box;
  final Value<DateTime?> dueAt;
  final Value<DateTime> createdAt;
  final Value<String> origin;
  final Value<bool> disabled;
  final Value<bool> favorite;
  final Value<bool> retired;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserCardsCompanion({
    this.note = const Value.absent(),
    this.inPlaylist = const Value.absent(),
    this.cardId = const Value.absent(),
    this.lang = const Value.absent(),
    this.localOnly = const Value.absent(),
    this.box = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.origin = const Value.absent(),
    this.disabled = const Value.absent(),
    this.favorite = const Value.absent(),
    this.retired = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCardsCompanion.insert({
    this.note = const Value.absent(),
    this.inPlaylist = const Value.absent(),
    required String cardId,
    required String lang,
    this.localOnly = const Value.absent(),
    required int box,
    this.dueAt = const Value.absent(),
    required DateTime createdAt,
    required String origin,
    this.disabled = const Value.absent(),
    this.favorite = const Value.absent(),
    this.retired = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId),
       lang = Value(lang),
       box = Value(box),
       createdAt = Value(createdAt),
       origin = Value(origin),
       updatedAt = Value(updatedAt);
  static Insertable<UserCardRow> custom({
    Expression<String>? note,
    Expression<bool>? inPlaylist,
    Expression<String>? cardId,
    Expression<String>? lang,
    Expression<bool>? localOnly,
    Expression<int>? box,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? createdAt,
    Expression<String>? origin,
    Expression<bool>? disabled,
    Expression<bool>? favorite,
    Expression<bool>? retired,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (note != null) 'note': note,
      if (inPlaylist != null) 'in_playlist': inPlaylist,
      if (cardId != null) 'card_id': cardId,
      if (lang != null) 'lang': lang,
      if (localOnly != null) 'local_only': localOnly,
      if (box != null) 'box': box,
      if (dueAt != null) 'due_at': dueAt,
      if (createdAt != null) 'created_at': createdAt,
      if (origin != null) 'origin': origin,
      if (disabled != null) 'disabled': disabled,
      if (favorite != null) 'favorite': favorite,
      if (retired != null) 'retired': retired,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCardsCompanion copyWith({
    Value<String>? note,
    Value<bool>? inPlaylist,
    Value<String>? cardId,
    Value<String>? lang,
    Value<bool>? localOnly,
    Value<int>? box,
    Value<DateTime?>? dueAt,
    Value<DateTime>? createdAt,
    Value<String>? origin,
    Value<bool>? disabled,
    Value<bool>? favorite,
    Value<bool>? retired,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserCardsCompanion(
      note: note ?? this.note,
      inPlaylist: inPlaylist ?? this.inPlaylist,
      cardId: cardId ?? this.cardId,
      lang: lang ?? this.lang,
      localOnly: localOnly ?? this.localOnly,
      box: box ?? this.box,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt ?? this.createdAt,
      origin: origin ?? this.origin,
      disabled: disabled ?? this.disabled,
      favorite: favorite ?? this.favorite,
      retired: retired ?? this.retired,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (inPlaylist.present) {
      map['in_playlist'] = Variable<bool>(inPlaylist.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (localOnly.present) {
      map['local_only'] = Variable<bool>(localOnly.value);
    }
    if (box.present) {
      map['box'] = Variable<int>(box.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (disabled.present) {
      map['disabled'] = Variable<bool>(disabled.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (retired.present) {
      map['retired'] = Variable<bool>(retired.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCardsCompanion(')
          ..write('note: $note, ')
          ..write('inPlaylist: $inPlaylist, ')
          ..write('cardId: $cardId, ')
          ..write('lang: $lang, ')
          ..write('localOnly: $localOnly, ')
          ..write('box: $box, ')
          ..write('dueAt: $dueAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('origin: $origin, ')
          ..write('disabled: $disabled, ')
          ..write('favorite: $favorite, ')
          ..write('retired: $retired, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogTable extends ReviewLog
    with TableInfo<$ReviewLogTable, ReviewLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    check: () =>
        const CustomExpression("mode IN ('mixed', 'deck', 'revue', 'early')"),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentenceIdMeta = const VerificationMeta(
    'sentenceId',
  );
  @override
  late final GeneratedColumn<String> sentenceId = GeneratedColumn<String>(
    'sentence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstAttemptCorrectMeta =
      const VerificationMeta('firstAttemptCorrect');
  @override
  late final GeneratedColumn<bool> firstAttemptCorrect = GeneratedColumn<bool>(
    'first_attempt_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("first_attempt_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _errorCountMeta = const VerificationMeta(
    'errorCount',
  );
  @override
  late final GeneratedColumn<int> errorCount = GeneratedColumn<int>(
    'error_count',
    aliasedName,
    false,
    check: () => const CustomExpression('error_count >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revealedMeta = const VerificationMeta(
    'revealed',
  );
  @override
  late final GeneratedColumn<bool> revealed = GeneratedColumn<bool>(
    'revealed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("revealed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hintUsedMeta = const VerificationMeta(
    'hintUsed',
  );
  @override
  late final GeneratedColumn<bool> hintUsed = GeneratedColumn<bool>(
    'hint_used',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hint_used" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _boxBeforeMeta = const VerificationMeta(
    'boxBefore',
  );
  @override
  late final GeneratedColumn<int> boxBefore = GeneratedColumn<int>(
    'box_before',
    aliasedName,
    false,
    check: () => const CustomExpression('box_before BETWEEN 0 AND 5'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxAfterMeta = const VerificationMeta(
    'boxAfter',
  );
  @override
  late final GeneratedColumn<int> boxAfter = GeneratedColumn<int>(
    'box_after',
    aliasedName,
    false,
    check: () => const CustomExpression('box_after BETWEEN 1 AND 5'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtAfterMeta = const VerificationMeta(
    'dueAtAfter',
  );
  @override
  late final GeneratedColumn<DateTime> dueAtAfter = GeneratedColumn<DateTime>(
    'due_at_after',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseMsMeta = const VerificationMeta(
    'responseMs',
  );
  @override
  late final GeneratedColumn<int> responseMs = GeneratedColumn<int>(
    'response_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    createdAt,
    mode,
    sentenceId,
    firstAttemptCorrect,
    errorCount,
    revealed,
    hintUsed,
    boxBefore,
    boxAfter,
    dueAtAfter,
    responseMs,
    appVersion,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('sentence_id')) {
      context.handle(
        _sentenceIdMeta,
        sentenceId.isAcceptableOrUnknown(data['sentence_id']!, _sentenceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sentenceIdMeta);
    }
    if (data.containsKey('first_attempt_correct')) {
      context.handle(
        _firstAttemptCorrectMeta,
        firstAttemptCorrect.isAcceptableOrUnknown(
          data['first_attempt_correct']!,
          _firstAttemptCorrectMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstAttemptCorrectMeta);
    }
    if (data.containsKey('error_count')) {
      context.handle(
        _errorCountMeta,
        errorCount.isAcceptableOrUnknown(data['error_count']!, _errorCountMeta),
      );
    } else if (isInserting) {
      context.missing(_errorCountMeta);
    }
    if (data.containsKey('revealed')) {
      context.handle(
        _revealedMeta,
        revealed.isAcceptableOrUnknown(data['revealed']!, _revealedMeta),
      );
    } else if (isInserting) {
      context.missing(_revealedMeta);
    }
    if (data.containsKey('hint_used')) {
      context.handle(
        _hintUsedMeta,
        hintUsed.isAcceptableOrUnknown(data['hint_used']!, _hintUsedMeta),
      );
    }
    if (data.containsKey('box_before')) {
      context.handle(
        _boxBeforeMeta,
        boxBefore.isAcceptableOrUnknown(data['box_before']!, _boxBeforeMeta),
      );
    } else if (isInserting) {
      context.missing(_boxBeforeMeta);
    }
    if (data.containsKey('box_after')) {
      context.handle(
        _boxAfterMeta,
        boxAfter.isAcceptableOrUnknown(data['box_after']!, _boxAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_boxAfterMeta);
    }
    if (data.containsKey('due_at_after')) {
      context.handle(
        _dueAtAfterMeta,
        dueAtAfter.isAcceptableOrUnknown(
          data['due_at_after']!,
          _dueAtAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dueAtAfterMeta);
    }
    if (data.containsKey('response_ms')) {
      context.handle(
        _responseMsMeta,
        responseMs.isAcceptableOrUnknown(data['response_ms']!, _responseMsMeta),
      );
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_appVersionMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      sentenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence_id'],
      )!,
      firstAttemptCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}first_attempt_correct'],
      )!,
      errorCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}error_count'],
      )!,
      revealed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}revealed'],
      )!,
      hintUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hint_used'],
      )!,
      boxBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box_before'],
      )!,
      boxAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box_after'],
      )!,
      dueAtAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at_after'],
      )!,
      responseMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_ms'],
      ),
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $ReviewLogTable createAlias(String alias) {
    return $ReviewLogTable(attachedDatabase, alias);
  }
}

class ReviewLogRow extends DataClass implements Insertable<ReviewLogRow> {
  final String id;
  final String cardId;
  final DateTime createdAt;
  final String mode;
  final String sentenceId;
  final bool firstAttemptCorrect;
  final int errorCount;
  final bool revealed;
  final bool hintUsed;
  final int boxBefore;
  final int boxAfter;
  final DateTime dueAtAfter;
  final int? responseMs;
  final String appVersion;
  final String deviceId;
  const ReviewLogRow({
    required this.id,
    required this.cardId,
    required this.createdAt,
    required this.mode,
    required this.sentenceId,
    required this.firstAttemptCorrect,
    required this.errorCount,
    required this.revealed,
    required this.hintUsed,
    required this.boxBefore,
    required this.boxAfter,
    required this.dueAtAfter,
    this.responseMs,
    required this.appVersion,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_id'] = Variable<String>(cardId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['mode'] = Variable<String>(mode);
    map['sentence_id'] = Variable<String>(sentenceId);
    map['first_attempt_correct'] = Variable<bool>(firstAttemptCorrect);
    map['error_count'] = Variable<int>(errorCount);
    map['revealed'] = Variable<bool>(revealed);
    map['hint_used'] = Variable<bool>(hintUsed);
    map['box_before'] = Variable<int>(boxBefore);
    map['box_after'] = Variable<int>(boxAfter);
    map['due_at_after'] = Variable<DateTime>(dueAtAfter);
    if (!nullToAbsent || responseMs != null) {
      map['response_ms'] = Variable<int>(responseMs);
    }
    map['app_version'] = Variable<String>(appVersion);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  ReviewLogCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogCompanion(
      id: Value(id),
      cardId: Value(cardId),
      createdAt: Value(createdAt),
      mode: Value(mode),
      sentenceId: Value(sentenceId),
      firstAttemptCorrect: Value(firstAttemptCorrect),
      errorCount: Value(errorCount),
      revealed: Value(revealed),
      hintUsed: Value(hintUsed),
      boxBefore: Value(boxBefore),
      boxAfter: Value(boxAfter),
      dueAtAfter: Value(dueAtAfter),
      responseMs: responseMs == null && nullToAbsent
          ? const Value.absent()
          : Value(responseMs),
      appVersion: Value(appVersion),
      deviceId: Value(deviceId),
    );
  }

  factory ReviewLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLogRow(
      id: serializer.fromJson<String>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      mode: serializer.fromJson<String>(json['mode']),
      sentenceId: serializer.fromJson<String>(json['sentenceId']),
      firstAttemptCorrect: serializer.fromJson<bool>(
        json['firstAttemptCorrect'],
      ),
      errorCount: serializer.fromJson<int>(json['errorCount']),
      revealed: serializer.fromJson<bool>(json['revealed']),
      hintUsed: serializer.fromJson<bool>(json['hintUsed']),
      boxBefore: serializer.fromJson<int>(json['boxBefore']),
      boxAfter: serializer.fromJson<int>(json['boxAfter']),
      dueAtAfter: serializer.fromJson<DateTime>(json['dueAtAfter']),
      responseMs: serializer.fromJson<int?>(json['responseMs']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardId': serializer.toJson<String>(cardId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'mode': serializer.toJson<String>(mode),
      'sentenceId': serializer.toJson<String>(sentenceId),
      'firstAttemptCorrect': serializer.toJson<bool>(firstAttemptCorrect),
      'errorCount': serializer.toJson<int>(errorCount),
      'revealed': serializer.toJson<bool>(revealed),
      'hintUsed': serializer.toJson<bool>(hintUsed),
      'boxBefore': serializer.toJson<int>(boxBefore),
      'boxAfter': serializer.toJson<int>(boxAfter),
      'dueAtAfter': serializer.toJson<DateTime>(dueAtAfter),
      'responseMs': serializer.toJson<int?>(responseMs),
      'appVersion': serializer.toJson<String>(appVersion),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  ReviewLogRow copyWith({
    String? id,
    String? cardId,
    DateTime? createdAt,
    String? mode,
    String? sentenceId,
    bool? firstAttemptCorrect,
    int? errorCount,
    bool? revealed,
    bool? hintUsed,
    int? boxBefore,
    int? boxAfter,
    DateTime? dueAtAfter,
    Value<int?> responseMs = const Value.absent(),
    String? appVersion,
    String? deviceId,
  }) => ReviewLogRow(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    createdAt: createdAt ?? this.createdAt,
    mode: mode ?? this.mode,
    sentenceId: sentenceId ?? this.sentenceId,
    firstAttemptCorrect: firstAttemptCorrect ?? this.firstAttemptCorrect,
    errorCount: errorCount ?? this.errorCount,
    revealed: revealed ?? this.revealed,
    hintUsed: hintUsed ?? this.hintUsed,
    boxBefore: boxBefore ?? this.boxBefore,
    boxAfter: boxAfter ?? this.boxAfter,
    dueAtAfter: dueAtAfter ?? this.dueAtAfter,
    responseMs: responseMs.present ? responseMs.value : this.responseMs,
    appVersion: appVersion ?? this.appVersion,
    deviceId: deviceId ?? this.deviceId,
  );
  ReviewLogRow copyWithCompanion(ReviewLogCompanion data) {
    return ReviewLogRow(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      mode: data.mode.present ? data.mode.value : this.mode,
      sentenceId: data.sentenceId.present
          ? data.sentenceId.value
          : this.sentenceId,
      firstAttemptCorrect: data.firstAttemptCorrect.present
          ? data.firstAttemptCorrect.value
          : this.firstAttemptCorrect,
      errorCount: data.errorCount.present
          ? data.errorCount.value
          : this.errorCount,
      revealed: data.revealed.present ? data.revealed.value : this.revealed,
      hintUsed: data.hintUsed.present ? data.hintUsed.value : this.hintUsed,
      boxBefore: data.boxBefore.present ? data.boxBefore.value : this.boxBefore,
      boxAfter: data.boxAfter.present ? data.boxAfter.value : this.boxAfter,
      dueAtAfter: data.dueAtAfter.present
          ? data.dueAtAfter.value
          : this.dueAtAfter,
      responseMs: data.responseMs.present
          ? data.responseMs.value
          : this.responseMs,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogRow(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('createdAt: $createdAt, ')
          ..write('mode: $mode, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('firstAttemptCorrect: $firstAttemptCorrect, ')
          ..write('errorCount: $errorCount, ')
          ..write('revealed: $revealed, ')
          ..write('hintUsed: $hintUsed, ')
          ..write('boxBefore: $boxBefore, ')
          ..write('boxAfter: $boxAfter, ')
          ..write('dueAtAfter: $dueAtAfter, ')
          ..write('responseMs: $responseMs, ')
          ..write('appVersion: $appVersion, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    createdAt,
    mode,
    sentenceId,
    firstAttemptCorrect,
    errorCount,
    revealed,
    hintUsed,
    boxBefore,
    boxAfter,
    dueAtAfter,
    responseMs,
    appVersion,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLogRow &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.createdAt == this.createdAt &&
          other.mode == this.mode &&
          other.sentenceId == this.sentenceId &&
          other.firstAttemptCorrect == this.firstAttemptCorrect &&
          other.errorCount == this.errorCount &&
          other.revealed == this.revealed &&
          other.hintUsed == this.hintUsed &&
          other.boxBefore == this.boxBefore &&
          other.boxAfter == this.boxAfter &&
          other.dueAtAfter == this.dueAtAfter &&
          other.responseMs == this.responseMs &&
          other.appVersion == this.appVersion &&
          other.deviceId == this.deviceId);
}

class ReviewLogCompanion extends UpdateCompanion<ReviewLogRow> {
  final Value<String> id;
  final Value<String> cardId;
  final Value<DateTime> createdAt;
  final Value<String> mode;
  final Value<String> sentenceId;
  final Value<bool> firstAttemptCorrect;
  final Value<int> errorCount;
  final Value<bool> revealed;
  final Value<bool> hintUsed;
  final Value<int> boxBefore;
  final Value<int> boxAfter;
  final Value<DateTime> dueAtAfter;
  final Value<int?> responseMs;
  final Value<String> appVersion;
  final Value<String> deviceId;
  final Value<int> rowid;
  const ReviewLogCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.mode = const Value.absent(),
    this.sentenceId = const Value.absent(),
    this.firstAttemptCorrect = const Value.absent(),
    this.errorCount = const Value.absent(),
    this.revealed = const Value.absent(),
    this.hintUsed = const Value.absent(),
    this.boxBefore = const Value.absent(),
    this.boxAfter = const Value.absent(),
    this.dueAtAfter = const Value.absent(),
    this.responseMs = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewLogCompanion.insert({
    required String id,
    required String cardId,
    required DateTime createdAt,
    required String mode,
    required String sentenceId,
    required bool firstAttemptCorrect,
    required int errorCount,
    required bool revealed,
    this.hintUsed = const Value.absent(),
    required int boxBefore,
    required int boxAfter,
    required DateTime dueAtAfter,
    this.responseMs = const Value.absent(),
    required String appVersion,
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cardId = Value(cardId),
       createdAt = Value(createdAt),
       mode = Value(mode),
       sentenceId = Value(sentenceId),
       firstAttemptCorrect = Value(firstAttemptCorrect),
       errorCount = Value(errorCount),
       revealed = Value(revealed),
       boxBefore = Value(boxBefore),
       boxAfter = Value(boxAfter),
       dueAtAfter = Value(dueAtAfter),
       appVersion = Value(appVersion),
       deviceId = Value(deviceId);
  static Insertable<ReviewLogRow> custom({
    Expression<String>? id,
    Expression<String>? cardId,
    Expression<DateTime>? createdAt,
    Expression<String>? mode,
    Expression<String>? sentenceId,
    Expression<bool>? firstAttemptCorrect,
    Expression<int>? errorCount,
    Expression<bool>? revealed,
    Expression<bool>? hintUsed,
    Expression<int>? boxBefore,
    Expression<int>? boxAfter,
    Expression<DateTime>? dueAtAfter,
    Expression<int>? responseMs,
    Expression<String>? appVersion,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (createdAt != null) 'created_at': createdAt,
      if (mode != null) 'mode': mode,
      if (sentenceId != null) 'sentence_id': sentenceId,
      if (firstAttemptCorrect != null)
        'first_attempt_correct': firstAttemptCorrect,
      if (errorCount != null) 'error_count': errorCount,
      if (revealed != null) 'revealed': revealed,
      if (hintUsed != null) 'hint_used': hintUsed,
      if (boxBefore != null) 'box_before': boxBefore,
      if (boxAfter != null) 'box_after': boxAfter,
      if (dueAtAfter != null) 'due_at_after': dueAtAfter,
      if (responseMs != null) 'response_ms': responseMs,
      if (appVersion != null) 'app_version': appVersion,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewLogCompanion copyWith({
    Value<String>? id,
    Value<String>? cardId,
    Value<DateTime>? createdAt,
    Value<String>? mode,
    Value<String>? sentenceId,
    Value<bool>? firstAttemptCorrect,
    Value<int>? errorCount,
    Value<bool>? revealed,
    Value<bool>? hintUsed,
    Value<int>? boxBefore,
    Value<int>? boxAfter,
    Value<DateTime>? dueAtAfter,
    Value<int?>? responseMs,
    Value<String>? appVersion,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return ReviewLogCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      createdAt: createdAt ?? this.createdAt,
      mode: mode ?? this.mode,
      sentenceId: sentenceId ?? this.sentenceId,
      firstAttemptCorrect: firstAttemptCorrect ?? this.firstAttemptCorrect,
      errorCount: errorCount ?? this.errorCount,
      revealed: revealed ?? this.revealed,
      hintUsed: hintUsed ?? this.hintUsed,
      boxBefore: boxBefore ?? this.boxBefore,
      boxAfter: boxAfter ?? this.boxAfter,
      dueAtAfter: dueAtAfter ?? this.dueAtAfter,
      responseMs: responseMs ?? this.responseMs,
      appVersion: appVersion ?? this.appVersion,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (sentenceId.present) {
      map['sentence_id'] = Variable<String>(sentenceId.value);
    }
    if (firstAttemptCorrect.present) {
      map['first_attempt_correct'] = Variable<bool>(firstAttemptCorrect.value);
    }
    if (errorCount.present) {
      map['error_count'] = Variable<int>(errorCount.value);
    }
    if (revealed.present) {
      map['revealed'] = Variable<bool>(revealed.value);
    }
    if (hintUsed.present) {
      map['hint_used'] = Variable<bool>(hintUsed.value);
    }
    if (boxBefore.present) {
      map['box_before'] = Variable<int>(boxBefore.value);
    }
    if (boxAfter.present) {
      map['box_after'] = Variable<int>(boxAfter.value);
    }
    if (dueAtAfter.present) {
      map['due_at_after'] = Variable<DateTime>(dueAtAfter.value);
    }
    if (responseMs.present) {
      map['response_ms'] = Variable<int>(responseMs.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('createdAt: $createdAt, ')
          ..write('mode: $mode, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('firstAttemptCorrect: $firstAttemptCorrect, ')
          ..write('errorCount: $errorCount, ')
          ..write('revealed: $revealed, ')
          ..write('hintUsed: $hintUsed, ')
          ..write('boxBefore: $boxBefore, ')
          ..write('boxAfter: $boxAfter, ')
          ..write('dueAtAfter: $dueAtAfter, ')
          ..write('responseMs: $responseMs, ')
          ..write('appVersion: $appVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeckSettingsTable extends DeckSettings
    with TableInfo<$DeckSettingsTable, DeckSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeckSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [deckId, active, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deck_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeckSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deckId};
  @override
  DeckSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeckSettingRow(
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DeckSettingsTable createAlias(String alias) {
    return $DeckSettingsTable(attachedDatabase, alias);
  }
}

class DeckSettingRow extends DataClass implements Insertable<DeckSettingRow> {
  final String deckId;
  final bool active;
  final DateTime updatedAt;
  const DeckSettingRow({
    required this.deckId,
    required this.active,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['deck_id'] = Variable<String>(deckId);
    map['active'] = Variable<bool>(active);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeckSettingsCompanion toCompanion(bool nullToAbsent) {
    return DeckSettingsCompanion(
      deckId: Value(deckId),
      active: Value(active),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeckSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeckSettingRow(
      deckId: serializer.fromJson<String>(json['deckId']),
      active: serializer.fromJson<bool>(json['active']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deckId': serializer.toJson<String>(deckId),
      'active': serializer.toJson<bool>(active),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeckSettingRow copyWith({
    String? deckId,
    bool? active,
    DateTime? updatedAt,
  }) => DeckSettingRow(
    deckId: deckId ?? this.deckId,
    active: active ?? this.active,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DeckSettingRow copyWithCompanion(DeckSettingsCompanion data) {
    return DeckSettingRow(
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      active: data.active.present ? data.active.value : this.active,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeckSettingRow(')
          ..write('deckId: $deckId, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deckId, active, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckSettingRow &&
          other.deckId == this.deckId &&
          other.active == this.active &&
          other.updatedAt == this.updatedAt);
}

class DeckSettingsCompanion extends UpdateCompanion<DeckSettingRow> {
  final Value<String> deckId;
  final Value<bool> active;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DeckSettingsCompanion({
    this.deckId = const Value.absent(),
    this.active = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeckSettingsCompanion.insert({
    required String deckId,
    required bool active,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : deckId = Value(deckId),
       active = Value(active),
       updatedAt = Value(updatedAt);
  static Insertable<DeckSettingRow> custom({
    Expression<String>? deckId,
    Expression<bool>? active,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deckId != null) 'deck_id': deckId,
      if (active != null) 'active': active,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeckSettingsCompanion copyWith({
    Value<String>? deckId,
    Value<bool>? active,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DeckSettingsCompanion(
      deckId: deckId ?? this.deckId,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeckSettingsCompanion(')
          ..write('deckId: $deckId, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dailyGoalMeta = const VerificationMeta(
    'dailyGoal',
  );
  @override
  late final GeneratedColumn<int> dailyGoal = GeneratedColumn<int>(
    'daily_goal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _motifMeta = const VerificationMeta('motif');
  @override
  late final GeneratedColumn<String> motif = GeneratedColumn<String>(
    'motif',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('automatic'),
  );
  static const VerificationMeta _includeDiacriticsMeta = const VerificationMeta(
    'includeDiacritics',
  );
  @override
  late final GeneratedColumn<bool> includeDiacritics = GeneratedColumn<bool>(
    'include_diacritics',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_diacritics" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoNextMeta = const VerificationMeta(
    'autoNext',
  );
  @override
  late final GeneratedColumn<bool> autoNext = GeneratedColumn<bool>(
    'auto_next',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_next" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showGrammarMeta = const VerificationMeta(
    'showGrammar',
  );
  @override
  late final GeneratedColumn<bool> showGrammar = GeneratedColumn<bool>(
    'show_grammar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_grammar" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => const CustomExpression('id = 1'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetLangMeta = const VerificationMeta(
    'targetLang',
  );
  @override
  late final GeneratedColumn<String> targetLang = GeneratedColumn<String>(
    'target_lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dailyGoal,
    motif,
    includeDiacritics,
    autoNext,
    showGrammar,
    id,
    deviceId,
    targetLang,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('daily_goal')) {
      context.handle(
        _dailyGoalMeta,
        dailyGoal.isAcceptableOrUnknown(data['daily_goal']!, _dailyGoalMeta),
      );
    }
    if (data.containsKey('motif')) {
      context.handle(
        _motifMeta,
        motif.isAcceptableOrUnknown(data['motif']!, _motifMeta),
      );
    }
    if (data.containsKey('include_diacritics')) {
      context.handle(
        _includeDiacriticsMeta,
        includeDiacritics.isAcceptableOrUnknown(
          data['include_diacritics']!,
          _includeDiacriticsMeta,
        ),
      );
    }
    if (data.containsKey('auto_next')) {
      context.handle(
        _autoNextMeta,
        autoNext.isAcceptableOrUnknown(data['auto_next']!, _autoNextMeta),
      );
    }
    if (data.containsKey('show_grammar')) {
      context.handle(
        _showGrammarMeta,
        showGrammar.isAcceptableOrUnknown(
          data['show_grammar']!,
          _showGrammarMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('target_lang')) {
      context.handle(
        _targetLangMeta,
        targetLang.isAcceptableOrUnknown(data['target_lang']!, _targetLangMeta),
      );
    } else if (isInserting) {
      context.missing(_targetLangMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      dailyGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_goal'],
      )!,
      motif: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motif'],
      )!,
      includeDiacritics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_diacritics'],
      )!,
      autoNext: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_next'],
      )!,
      showGrammar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_grammar'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      targetLang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_lang'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int dailyGoal;
  final String motif;
  final bool includeDiacritics;
  final bool autoNext;
  final bool showGrammar;
  final int id;
  final String deviceId;
  final String targetLang;
  final DateTime updatedAt;
  const SettingsRow({
    required this.dailyGoal,
    required this.motif,
    required this.includeDiacritics,
    required this.autoNext,
    required this.showGrammar,
    required this.id,
    required this.deviceId,
    required this.targetLang,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['daily_goal'] = Variable<int>(dailyGoal);
    map['motif'] = Variable<String>(motif);
    map['include_diacritics'] = Variable<bool>(includeDiacritics);
    map['auto_next'] = Variable<bool>(autoNext);
    map['show_grammar'] = Variable<bool>(showGrammar);
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['target_lang'] = Variable<String>(targetLang);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      dailyGoal: Value(dailyGoal),
      motif: Value(motif),
      includeDiacritics: Value(includeDiacritics),
      autoNext: Value(autoNext),
      showGrammar: Value(showGrammar),
      id: Value(id),
      deviceId: Value(deviceId),
      targetLang: Value(targetLang),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      dailyGoal: serializer.fromJson<int>(json['dailyGoal']),
      motif: serializer.fromJson<String>(json['motif']),
      includeDiacritics: serializer.fromJson<bool>(json['includeDiacritics']),
      autoNext: serializer.fromJson<bool>(json['autoNext']),
      showGrammar: serializer.fromJson<bool>(json['showGrammar']),
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      targetLang: serializer.fromJson<String>(json['targetLang']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dailyGoal': serializer.toJson<int>(dailyGoal),
      'motif': serializer.toJson<String>(motif),
      'includeDiacritics': serializer.toJson<bool>(includeDiacritics),
      'autoNext': serializer.toJson<bool>(autoNext),
      'showGrammar': serializer.toJson<bool>(showGrammar),
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'targetLang': serializer.toJson<String>(targetLang),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SettingsRow copyWith({
    int? dailyGoal,
    String? motif,
    bool? includeDiacritics,
    bool? autoNext,
    bool? showGrammar,
    int? id,
    String? deviceId,
    String? targetLang,
    DateTime? updatedAt,
  }) => SettingsRow(
    dailyGoal: dailyGoal ?? this.dailyGoal,
    motif: motif ?? this.motif,
    includeDiacritics: includeDiacritics ?? this.includeDiacritics,
    autoNext: autoNext ?? this.autoNext,
    showGrammar: showGrammar ?? this.showGrammar,
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    targetLang: targetLang ?? this.targetLang,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SettingsRow copyWithCompanion(SettingsCompanion data) {
    return SettingsRow(
      dailyGoal: data.dailyGoal.present ? data.dailyGoal.value : this.dailyGoal,
      motif: data.motif.present ? data.motif.value : this.motif,
      includeDiacritics: data.includeDiacritics.present
          ? data.includeDiacritics.value
          : this.includeDiacritics,
      autoNext: data.autoNext.present ? data.autoNext.value : this.autoNext,
      showGrammar: data.showGrammar.present
          ? data.showGrammar.value
          : this.showGrammar,
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      targetLang: data.targetLang.present
          ? data.targetLang.value
          : this.targetLang,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('motif: $motif, ')
          ..write('includeDiacritics: $includeDiacritics, ')
          ..write('autoNext: $autoNext, ')
          ..write('showGrammar: $showGrammar, ')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('targetLang: $targetLang, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dailyGoal,
    motif,
    includeDiacritics,
    autoNext,
    showGrammar,
    id,
    deviceId,
    targetLang,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.dailyGoal == this.dailyGoal &&
          other.motif == this.motif &&
          other.includeDiacritics == this.includeDiacritics &&
          other.autoNext == this.autoNext &&
          other.showGrammar == this.showGrammar &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.targetLang == this.targetLang &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> dailyGoal;
  final Value<String> motif;
  final Value<bool> includeDiacritics;
  final Value<bool> autoNext;
  final Value<bool> showGrammar;
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> targetLang;
  final Value<DateTime> updatedAt;
  const SettingsCompanion({
    this.dailyGoal = const Value.absent(),
    this.motif = const Value.absent(),
    this.includeDiacritics = const Value.absent(),
    this.autoNext = const Value.absent(),
    this.showGrammar = const Value.absent(),
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.targetLang = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.dailyGoal = const Value.absent(),
    this.motif = const Value.absent(),
    this.includeDiacritics = const Value.absent(),
    this.autoNext = const Value.absent(),
    this.showGrammar = const Value.absent(),
    this.id = const Value.absent(),
    required String deviceId,
    required String targetLang,
    required DateTime updatedAt,
  }) : deviceId = Value(deviceId),
       targetLang = Value(targetLang),
       updatedAt = Value(updatedAt);
  static Insertable<SettingsRow> custom({
    Expression<int>? dailyGoal,
    Expression<String>? motif,
    Expression<bool>? includeDiacritics,
    Expression<bool>? autoNext,
    Expression<bool>? showGrammar,
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? targetLang,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (dailyGoal != null) 'daily_goal': dailyGoal,
      if (motif != null) 'motif': motif,
      if (includeDiacritics != null) 'include_diacritics': includeDiacritics,
      if (autoNext != null) 'auto_next': autoNext,
      if (showGrammar != null) 'show_grammar': showGrammar,
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (targetLang != null) 'target_lang': targetLang,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? dailyGoal,
    Value<String>? motif,
    Value<bool>? includeDiacritics,
    Value<bool>? autoNext,
    Value<bool>? showGrammar,
    Value<int>? id,
    Value<String>? deviceId,
    Value<String>? targetLang,
    Value<DateTime>? updatedAt,
  }) {
    return SettingsCompanion(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      motif: motif ?? this.motif,
      includeDiacritics: includeDiacritics ?? this.includeDiacritics,
      autoNext: autoNext ?? this.autoNext,
      showGrammar: showGrammar ?? this.showGrammar,
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      targetLang: targetLang ?? this.targetLang,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dailyGoal.present) {
      map['daily_goal'] = Variable<int>(dailyGoal.value);
    }
    if (motif.present) {
      map['motif'] = Variable<String>(motif.value);
    }
    if (includeDiacritics.present) {
      map['include_diacritics'] = Variable<bool>(includeDiacritics.value);
    }
    if (autoNext.present) {
      map['auto_next'] = Variable<bool>(autoNext.value);
    }
    if (showGrammar.present) {
      map['show_grammar'] = Variable<bool>(showGrammar.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (targetLang.present) {
      map['target_lang'] = Variable<String>(targetLang.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('motif: $motif, ')
          ..write('includeDiacritics: $includeDiacritics, ')
          ..write('autoNext: $autoNext, ')
          ..write('showGrammar: $showGrammar, ')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('targetLang: $targetLang, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalSubmissionsTable extends LocalSubmissions
    with TableInfo<$LocalSubmissionsTable, SubmissionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSubmissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentenceIdMeta = const VerificationMeta(
    'sentenceId',
  );
  @override
  late final GeneratedColumn<String> sentenceId = GeneratedColumn<String>(
    'sentence_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packVersionMeta = const VerificationMeta(
    'packVersion',
  );
  @override
  late final GeneratedColumn<String> packVersion = GeneratedColumn<String>(
    'pack_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    body,
    category,
    rating,
    cardId,
    sentenceId,
    packVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_submissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubmissionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    }
    if (data.containsKey('sentence_id')) {
      context.handle(
        _sentenceIdMeta,
        sentenceId.isAcceptableOrUnknown(data['sentence_id']!, _sentenceIdMeta),
      );
    }
    if (data.containsKey('pack_version')) {
      context.handle(
        _packVersionMeta,
        packVersion.isAcceptableOrUnknown(
          data['pack_version']!,
          _packVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubmissionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubmissionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      ),
      sentenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence_id'],
      ),
      packVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_version'],
      ),
    );
  }

  @override
  $LocalSubmissionsTable createAlias(String alias) {
    return $LocalSubmissionsTable(attachedDatabase, alias);
  }
}

class SubmissionRow extends DataClass implements Insertable<SubmissionRow> {
  final String id;
  final DateTime createdAt;
  final String body;
  final String? category;
  final int? rating;
  final String? cardId;
  final String? sentenceId;
  final String? packVersion;
  const SubmissionRow({
    required this.id,
    required this.createdAt,
    required this.body,
    this.category,
    this.rating,
    this.cardId,
    this.sentenceId,
    this.packVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<String>(cardId);
    }
    if (!nullToAbsent || sentenceId != null) {
      map['sentence_id'] = Variable<String>(sentenceId);
    }
    if (!nullToAbsent || packVersion != null) {
      map['pack_version'] = Variable<String>(packVersion);
    }
    return map;
  }

  LocalSubmissionsCompanion toCompanion(bool nullToAbsent) {
    return LocalSubmissionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      body: Value(body),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      cardId: cardId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardId),
      sentenceId: sentenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sentenceId),
      packVersion: packVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(packVersion),
    );
  }

  factory SubmissionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubmissionRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      body: serializer.fromJson<String>(json['body']),
      category: serializer.fromJson<String?>(json['category']),
      rating: serializer.fromJson<int?>(json['rating']),
      cardId: serializer.fromJson<String?>(json['cardId']),
      sentenceId: serializer.fromJson<String?>(json['sentenceId']),
      packVersion: serializer.fromJson<String?>(json['packVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'body': serializer.toJson<String>(body),
      'category': serializer.toJson<String?>(category),
      'rating': serializer.toJson<int?>(rating),
      'cardId': serializer.toJson<String?>(cardId),
      'sentenceId': serializer.toJson<String?>(sentenceId),
      'packVersion': serializer.toJson<String?>(packVersion),
    };
  }

  SubmissionRow copyWith({
    String? id,
    DateTime? createdAt,
    String? body,
    Value<String?> category = const Value.absent(),
    Value<int?> rating = const Value.absent(),
    Value<String?> cardId = const Value.absent(),
    Value<String?> sentenceId = const Value.absent(),
    Value<String?> packVersion = const Value.absent(),
  }) => SubmissionRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    body: body ?? this.body,
    category: category.present ? category.value : this.category,
    rating: rating.present ? rating.value : this.rating,
    cardId: cardId.present ? cardId.value : this.cardId,
    sentenceId: sentenceId.present ? sentenceId.value : this.sentenceId,
    packVersion: packVersion.present ? packVersion.value : this.packVersion,
  );
  SubmissionRow copyWithCompanion(LocalSubmissionsCompanion data) {
    return SubmissionRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      body: data.body.present ? data.body.value : this.body,
      category: data.category.present ? data.category.value : this.category,
      rating: data.rating.present ? data.rating.value : this.rating,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      sentenceId: data.sentenceId.present
          ? data.sentenceId.value
          : this.sentenceId,
      packVersion: data.packVersion.present
          ? data.packVersion.value
          : this.packVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubmissionRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('body: $body, ')
          ..write('category: $category, ')
          ..write('rating: $rating, ')
          ..write('cardId: $cardId, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('packVersion: $packVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    body,
    category,
    rating,
    cardId,
    sentenceId,
    packVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubmissionRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.body == this.body &&
          other.category == this.category &&
          other.rating == this.rating &&
          other.cardId == this.cardId &&
          other.sentenceId == this.sentenceId &&
          other.packVersion == this.packVersion);
}

class LocalSubmissionsCompanion extends UpdateCompanion<SubmissionRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<String> body;
  final Value<String?> category;
  final Value<int?> rating;
  final Value<String?> cardId;
  final Value<String?> sentenceId;
  final Value<String?> packVersion;
  final Value<int> rowid;
  const LocalSubmissionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.body = const Value.absent(),
    this.category = const Value.absent(),
    this.rating = const Value.absent(),
    this.cardId = const Value.absent(),
    this.sentenceId = const Value.absent(),
    this.packVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSubmissionsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required String body,
    this.category = const Value.absent(),
    this.rating = const Value.absent(),
    this.cardId = const Value.absent(),
    this.sentenceId = const Value.absent(),
    this.packVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       body = Value(body);
  static Insertable<SubmissionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? body,
    Expression<String>? category,
    Expression<int>? rating,
    Expression<String>? cardId,
    Expression<String>? sentenceId,
    Expression<String>? packVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (body != null) 'body': body,
      if (category != null) 'category': category,
      if (rating != null) 'rating': rating,
      if (cardId != null) 'card_id': cardId,
      if (sentenceId != null) 'sentence_id': sentenceId,
      if (packVersion != null) 'pack_version': packVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSubmissionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<String>? body,
    Value<String?>? category,
    Value<int?>? rating,
    Value<String?>? cardId,
    Value<String?>? sentenceId,
    Value<String?>? packVersion,
    Value<int>? rowid,
  }) {
    return LocalSubmissionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      body: body ?? this.body,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      cardId: cardId ?? this.cardId,
      sentenceId: sentenceId ?? this.sentenceId,
      packVersion: packVersion ?? this.packVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (sentenceId.present) {
      map['sentence_id'] = Variable<String>(sentenceId.value);
    }
    if (packVersion.present) {
      map['pack_version'] = Variable<String>(packVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSubmissionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('body: $body, ')
          ..write('category: $category, ')
          ..write('rating: $rating, ')
          ..write('cardId: $cardId, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('packVersion: $packVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  late final $UserCardsTable userCards = $UserCardsTable(this);
  late final $ReviewLogTable reviewLog = $ReviewLogTable(this);
  late final $DeckSettingsTable deckSettings = $DeckSettingsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $LocalSubmissionsTable localSubmissions = $LocalSubmissionsTable(
    this,
  );
  late final Index reviewLogCard = Index(
    'review_log_card',
    'CREATE INDEX review_log_card ON review_log (card_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userCards,
    reviewLog,
    deckSettings,
    settings,
    localSubmissions,
    reviewLogCard,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
