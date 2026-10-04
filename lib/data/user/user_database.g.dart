// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_database.dart';

// ignore_for_file: type=lint
class $UserCardsTable extends UserCards
    with TableInfo<$UserCardsTable, UserCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _formMeta = const VerificationMeta('form');
  @override
  late final GeneratedColumn<String> form = GeneratedColumn<String>(
    'form',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formNormMeta = const VerificationMeta(
    'formNorm',
  );
  @override
  late final GeneratedColumn<String> formNorm = GeneratedColumn<String>(
    'form_norm',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glossDeMeta = const VerificationMeta(
    'glossDe',
  );
  @override
  late final GeneratedColumn<String> glossDe = GeneratedColumn<String>(
    'gloss_de',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posMeta = const VerificationMeta('pos');
  @override
  late final GeneratedColumn<String> pos = GeneratedColumn<String>(
    'pos',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lemmaIdentityMeta = const VerificationMeta(
    'lemmaIdentity',
  );
  @override
  late final GeneratedColumn<String> lemmaIdentity = GeneratedColumn<String>(
    'lemma_identity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senseIdentityMeta = const VerificationMeta(
    'senseIdentity',
  );
  @override
  late final GeneratedColumn<String> senseIdentity = GeneratedColumn<String>(
    'sense_identity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senseKeyMeta = const VerificationMeta(
    'senseKey',
  );
  @override
  late final GeneratedColumn<String> senseKey = GeneratedColumn<String>(
    'sense_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaryContextIdMeta = const VerificationMeta(
    'primaryContextId',
  );
  @override
  late final GeneratedColumn<String> primaryContextId = GeneratedColumn<String>(
    'primary_context_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
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
    form,
    formNorm,
    glossDe,
    lemma,
    pos,
    lemmaIdentity,
    senseIdentity,
    senseKey,
    primaryContextId,
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
    if (data.containsKey('form')) {
      context.handle(
        _formMeta,
        form.isAcceptableOrUnknown(data['form']!, _formMeta),
      );
    }
    if (data.containsKey('form_norm')) {
      context.handle(
        _formNormMeta,
        formNorm.isAcceptableOrUnknown(data['form_norm']!, _formNormMeta),
      );
    }
    if (data.containsKey('gloss_de')) {
      context.handle(
        _glossDeMeta,
        glossDe.isAcceptableOrUnknown(data['gloss_de']!, _glossDeMeta),
      );
    }
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
      );
    }
    if (data.containsKey('pos')) {
      context.handle(
        _posMeta,
        pos.isAcceptableOrUnknown(data['pos']!, _posMeta),
      );
    }
    if (data.containsKey('lemma_identity')) {
      context.handle(
        _lemmaIdentityMeta,
        lemmaIdentity.isAcceptableOrUnknown(
          data['lemma_identity']!,
          _lemmaIdentityMeta,
        ),
      );
    }
    if (data.containsKey('sense_identity')) {
      context.handle(
        _senseIdentityMeta,
        senseIdentity.isAcceptableOrUnknown(
          data['sense_identity']!,
          _senseIdentityMeta,
        ),
      );
    }
    if (data.containsKey('sense_key')) {
      context.handle(
        _senseKeyMeta,
        senseKey.isAcceptableOrUnknown(data['sense_key']!, _senseKeyMeta),
      );
    }
    if (data.containsKey('primary_context_id')) {
      context.handle(
        _primaryContextIdMeta,
        primaryContextId.isAcceptableOrUnknown(
          data['primary_context_id']!,
          _primaryContextIdMeta,
        ),
      );
    }
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
      form: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form'],
      ),
      formNorm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form_norm'],
      ),
      glossDe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gloss_de'],
      ),
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      ),
      pos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pos'],
      ),
      lemmaIdentity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma_identity'],
      ),
      senseIdentity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sense_identity'],
      ),
      senseKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sense_key'],
      ),
      primaryContextId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_context_id'],
      ),
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
  final String? form;
  final String? formNorm;
  final String? glossDe;
  final String? lemma;
  final String? pos;
  final String? lemmaIdentity;
  final String? senseIdentity;
  final String? senseKey;
  final String? primaryContextId;
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
    this.form,
    this.formNorm,
    this.glossDe,
    this.lemma,
    this.pos,
    this.lemmaIdentity,
    this.senseIdentity,
    this.senseKey,
    this.primaryContextId,
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
    if (!nullToAbsent || form != null) {
      map['form'] = Variable<String>(form);
    }
    if (!nullToAbsent || formNorm != null) {
      map['form_norm'] = Variable<String>(formNorm);
    }
    if (!nullToAbsent || glossDe != null) {
      map['gloss_de'] = Variable<String>(glossDe);
    }
    if (!nullToAbsent || lemma != null) {
      map['lemma'] = Variable<String>(lemma);
    }
    if (!nullToAbsent || pos != null) {
      map['pos'] = Variable<String>(pos);
    }
    if (!nullToAbsent || lemmaIdentity != null) {
      map['lemma_identity'] = Variable<String>(lemmaIdentity);
    }
    if (!nullToAbsent || senseIdentity != null) {
      map['sense_identity'] = Variable<String>(senseIdentity);
    }
    if (!nullToAbsent || senseKey != null) {
      map['sense_key'] = Variable<String>(senseKey);
    }
    if (!nullToAbsent || primaryContextId != null) {
      map['primary_context_id'] = Variable<String>(primaryContextId);
    }
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
      form: form == null && nullToAbsent ? const Value.absent() : Value(form),
      formNorm: formNorm == null && nullToAbsent
          ? const Value.absent()
          : Value(formNorm),
      glossDe: glossDe == null && nullToAbsent
          ? const Value.absent()
          : Value(glossDe),
      lemma: lemma == null && nullToAbsent
          ? const Value.absent()
          : Value(lemma),
      pos: pos == null && nullToAbsent ? const Value.absent() : Value(pos),
      lemmaIdentity: lemmaIdentity == null && nullToAbsent
          ? const Value.absent()
          : Value(lemmaIdentity),
      senseIdentity: senseIdentity == null && nullToAbsent
          ? const Value.absent()
          : Value(senseIdentity),
      senseKey: senseKey == null && nullToAbsent
          ? const Value.absent()
          : Value(senseKey),
      primaryContextId: primaryContextId == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryContextId),
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
      form: serializer.fromJson<String?>(json['form']),
      formNorm: serializer.fromJson<String?>(json['formNorm']),
      glossDe: serializer.fromJson<String?>(json['glossDe']),
      lemma: serializer.fromJson<String?>(json['lemma']),
      pos: serializer.fromJson<String?>(json['pos']),
      lemmaIdentity: serializer.fromJson<String?>(json['lemmaIdentity']),
      senseIdentity: serializer.fromJson<String?>(json['senseIdentity']),
      senseKey: serializer.fromJson<String?>(json['senseKey']),
      primaryContextId: serializer.fromJson<String?>(json['primaryContextId']),
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
      'form': serializer.toJson<String?>(form),
      'formNorm': serializer.toJson<String?>(formNorm),
      'glossDe': serializer.toJson<String?>(glossDe),
      'lemma': serializer.toJson<String?>(lemma),
      'pos': serializer.toJson<String?>(pos),
      'lemmaIdentity': serializer.toJson<String?>(lemmaIdentity),
      'senseIdentity': serializer.toJson<String?>(senseIdentity),
      'senseKey': serializer.toJson<String?>(senseKey),
      'primaryContextId': serializer.toJson<String?>(primaryContextId),
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
    Value<String?> form = const Value.absent(),
    Value<String?> formNorm = const Value.absent(),
    Value<String?> glossDe = const Value.absent(),
    Value<String?> lemma = const Value.absent(),
    Value<String?> pos = const Value.absent(),
    Value<String?> lemmaIdentity = const Value.absent(),
    Value<String?> senseIdentity = const Value.absent(),
    Value<String?> senseKey = const Value.absent(),
    Value<String?> primaryContextId = const Value.absent(),
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
    form: form.present ? form.value : this.form,
    formNorm: formNorm.present ? formNorm.value : this.formNorm,
    glossDe: glossDe.present ? glossDe.value : this.glossDe,
    lemma: lemma.present ? lemma.value : this.lemma,
    pos: pos.present ? pos.value : this.pos,
    lemmaIdentity: lemmaIdentity.present
        ? lemmaIdentity.value
        : this.lemmaIdentity,
    senseIdentity: senseIdentity.present
        ? senseIdentity.value
        : this.senseIdentity,
    senseKey: senseKey.present ? senseKey.value : this.senseKey,
    primaryContextId: primaryContextId.present
        ? primaryContextId.value
        : this.primaryContextId,
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
      form: data.form.present ? data.form.value : this.form,
      formNorm: data.formNorm.present ? data.formNorm.value : this.formNorm,
      glossDe: data.glossDe.present ? data.glossDe.value : this.glossDe,
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      pos: data.pos.present ? data.pos.value : this.pos,
      lemmaIdentity: data.lemmaIdentity.present
          ? data.lemmaIdentity.value
          : this.lemmaIdentity,
      senseIdentity: data.senseIdentity.present
          ? data.senseIdentity.value
          : this.senseIdentity,
      senseKey: data.senseKey.present ? data.senseKey.value : this.senseKey,
      primaryContextId: data.primaryContextId.present
          ? data.primaryContextId.value
          : this.primaryContextId,
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
          ..write('form: $form, ')
          ..write('formNorm: $formNorm, ')
          ..write('glossDe: $glossDe, ')
          ..write('lemma: $lemma, ')
          ..write('pos: $pos, ')
          ..write('lemmaIdentity: $lemmaIdentity, ')
          ..write('senseIdentity: $senseIdentity, ')
          ..write('senseKey: $senseKey, ')
          ..write('primaryContextId: $primaryContextId, ')
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
  int get hashCode => Object.hashAll([
    form,
    formNorm,
    glossDe,
    lemma,
    pos,
    lemmaIdentity,
    senseIdentity,
    senseKey,
    primaryContextId,
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
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserCardRow &&
          other.form == this.form &&
          other.formNorm == this.formNorm &&
          other.glossDe == this.glossDe &&
          other.lemma == this.lemma &&
          other.pos == this.pos &&
          other.lemmaIdentity == this.lemmaIdentity &&
          other.senseIdentity == this.senseIdentity &&
          other.senseKey == this.senseKey &&
          other.primaryContextId == this.primaryContextId &&
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
  final Value<String?> form;
  final Value<String?> formNorm;
  final Value<String?> glossDe;
  final Value<String?> lemma;
  final Value<String?> pos;
  final Value<String?> lemmaIdentity;
  final Value<String?> senseIdentity;
  final Value<String?> senseKey;
  final Value<String?> primaryContextId;
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
    this.form = const Value.absent(),
    this.formNorm = const Value.absent(),
    this.glossDe = const Value.absent(),
    this.lemma = const Value.absent(),
    this.pos = const Value.absent(),
    this.lemmaIdentity = const Value.absent(),
    this.senseIdentity = const Value.absent(),
    this.senseKey = const Value.absent(),
    this.primaryContextId = const Value.absent(),
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
    this.form = const Value.absent(),
    this.formNorm = const Value.absent(),
    this.glossDe = const Value.absent(),
    this.lemma = const Value.absent(),
    this.pos = const Value.absent(),
    this.lemmaIdentity = const Value.absent(),
    this.senseIdentity = const Value.absent(),
    this.senseKey = const Value.absent(),
    this.primaryContextId = const Value.absent(),
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
    Expression<String>? form,
    Expression<String>? formNorm,
    Expression<String>? glossDe,
    Expression<String>? lemma,
    Expression<String>? pos,
    Expression<String>? lemmaIdentity,
    Expression<String>? senseIdentity,
    Expression<String>? senseKey,
    Expression<String>? primaryContextId,
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
      if (form != null) 'form': form,
      if (formNorm != null) 'form_norm': formNorm,
      if (glossDe != null) 'gloss_de': glossDe,
      if (lemma != null) 'lemma': lemma,
      if (pos != null) 'pos': pos,
      if (lemmaIdentity != null) 'lemma_identity': lemmaIdentity,
      if (senseIdentity != null) 'sense_identity': senseIdentity,
      if (senseKey != null) 'sense_key': senseKey,
      if (primaryContextId != null) 'primary_context_id': primaryContextId,
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
    Value<String?>? form,
    Value<String?>? formNorm,
    Value<String?>? glossDe,
    Value<String?>? lemma,
    Value<String?>? pos,
    Value<String?>? lemmaIdentity,
    Value<String?>? senseIdentity,
    Value<String?>? senseKey,
    Value<String?>? primaryContextId,
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
      form: form ?? this.form,
      formNorm: formNorm ?? this.formNorm,
      glossDe: glossDe ?? this.glossDe,
      lemma: lemma ?? this.lemma,
      pos: pos ?? this.pos,
      lemmaIdentity: lemmaIdentity ?? this.lemmaIdentity,
      senseIdentity: senseIdentity ?? this.senseIdentity,
      senseKey: senseKey ?? this.senseKey,
      primaryContextId: primaryContextId ?? this.primaryContextId,
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
    if (form.present) {
      map['form'] = Variable<String>(form.value);
    }
    if (formNorm.present) {
      map['form_norm'] = Variable<String>(formNorm.value);
    }
    if (glossDe.present) {
      map['gloss_de'] = Variable<String>(glossDe.value);
    }
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    if (lemmaIdentity.present) {
      map['lemma_identity'] = Variable<String>(lemmaIdentity.value);
    }
    if (senseIdentity.present) {
      map['sense_identity'] = Variable<String>(senseIdentity.value);
    }
    if (senseKey.present) {
      map['sense_key'] = Variable<String>(senseKey.value);
    }
    if (primaryContextId.present) {
      map['primary_context_id'] = Variable<String>(primaryContextId.value);
    }
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
          ..write('form: $form, ')
          ..write('formNorm: $formNorm, ')
          ..write('glossDe: $glossDe, ')
          ..write('lemma: $lemma, ')
          ..write('pos: $pos, ')
          ..write('lemmaIdentity: $lemmaIdentity, ')
          ..write('senseIdentity: $senseIdentity, ')
          ..write('senseKey: $senseKey, ')
          ..write('primaryContextId: $primaryContextId, ')
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

class $CardContextsTable extends CardContexts
    with TableInfo<$CardContextsTable, CardContextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardContextsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _textValueMeta = const VerificationMeta(
    'textValue',
  );
  @override
  late final GeneratedColumn<String> textValue = GeneratedColumn<String>(
    'text_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationDeMeta = const VerificationMeta(
    'translationDe',
  );
  @override
  late final GeneratedColumn<String> translationDe = GeneratedColumn<String>(
    'translation_de',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gapStartMeta = const VerificationMeta(
    'gapStart',
  );
  @override
  late final GeneratedColumn<int> gapStart = GeneratedColumn<int>(
    'gap_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gapEndMeta = const VerificationMeta('gapEnd');
  @override
  late final GeneratedColumn<int> gapEnd = GeneratedColumn<int>(
    'gap_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta(
    'sourceRef',
  );
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentenceRefMeta = const VerificationMeta(
    'sentenceRef',
  );
  @override
  late final GeneratedColumn<String> sentenceRef = GeneratedColumn<String>(
    'sentence_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenIndexMeta = const VerificationMeta(
    'tokenIndex',
  );
  @override
  late final GeneratedColumn<int> tokenIndex = GeneratedColumn<int>(
    'token_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<String> revision = GeneratedColumn<String>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tokensJsonMeta = const VerificationMeta(
    'tokensJson',
  );
  @override
  late final GeneratedColumn<String> tokensJson = GeneratedColumn<String>(
    'tokens_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _otherFormsJsonMeta = const VerificationMeta(
    'otherFormsJson',
  );
  @override
  late final GeneratedColumn<String> otherFormsJson = GeneratedColumn<String>(
    'other_forms_json',
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
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    textValue,
    translationDe,
    gapStart,
    gapEnd,
    sourceRef,
    sentenceRef,
    tokenIndex,
    revision,
    fingerprint,
    tokensJson,
    otherFormsJson,
    lang,
    provenance,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardContextRow> instance, {
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
    if (data.containsKey('text_value')) {
      context.handle(
        _textValueMeta,
        textValue.isAcceptableOrUnknown(data['text_value']!, _textValueMeta),
      );
    } else if (isInserting) {
      context.missing(_textValueMeta);
    }
    if (data.containsKey('translation_de')) {
      context.handle(
        _translationDeMeta,
        translationDe.isAcceptableOrUnknown(
          data['translation_de']!,
          _translationDeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationDeMeta);
    }
    if (data.containsKey('gap_start')) {
      context.handle(
        _gapStartMeta,
        gapStart.isAcceptableOrUnknown(data['gap_start']!, _gapStartMeta),
      );
    } else if (isInserting) {
      context.missing(_gapStartMeta);
    }
    if (data.containsKey('gap_end')) {
      context.handle(
        _gapEndMeta,
        gapEnd.isAcceptableOrUnknown(data['gap_end']!, _gapEndMeta),
      );
    } else if (isInserting) {
      context.missing(_gapEndMeta);
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceRefMeta);
    }
    if (data.containsKey('sentence_ref')) {
      context.handle(
        _sentenceRefMeta,
        sentenceRef.isAcceptableOrUnknown(
          data['sentence_ref']!,
          _sentenceRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sentenceRefMeta);
    }
    if (data.containsKey('token_index')) {
      context.handle(
        _tokenIndexMeta,
        tokenIndex.isAcceptableOrUnknown(data['token_index']!, _tokenIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenIndexMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('tokens_json')) {
      context.handle(
        _tokensJsonMeta,
        tokensJson.isAcceptableOrUnknown(data['tokens_json']!, _tokensJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_tokensJsonMeta);
    }
    if (data.containsKey('other_forms_json')) {
      context.handle(
        _otherFormsJsonMeta,
        otherFormsJson.isAcceptableOrUnknown(
          data['other_forms_json']!,
          _otherFormsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_otherFormsJsonMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    } else if (isInserting) {
      context.missing(_provenanceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardContextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardContextRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      textValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_value'],
      )!,
      translationDe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_de'],
      )!,
      gapStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gap_start'],
      )!,
      gapEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gap_end'],
      )!,
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      )!,
      sentenceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence_ref'],
      )!,
      tokenIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}token_index'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      tokensJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tokens_json'],
      )!,
      otherFormsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_forms_json'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CardContextsTable createAlias(String alias) {
    return $CardContextsTable(attachedDatabase, alias);
  }
}

class CardContextRow extends DataClass implements Insertable<CardContextRow> {
  final String id;
  final String cardId;
  final String textValue;
  final String translationDe;
  final int gapStart;
  final int gapEnd;
  final String sourceRef;
  final String sentenceRef;
  final int tokenIndex;
  final String revision;
  final String fingerprint;
  final String tokensJson;
  final String otherFormsJson;
  final String lang;
  final String provenance;
  final DateTime createdAt;
  const CardContextRow({
    required this.id,
    required this.cardId,
    required this.textValue,
    required this.translationDe,
    required this.gapStart,
    required this.gapEnd,
    required this.sourceRef,
    required this.sentenceRef,
    required this.tokenIndex,
    required this.revision,
    required this.fingerprint,
    required this.tokensJson,
    required this.otherFormsJson,
    required this.lang,
    required this.provenance,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_id'] = Variable<String>(cardId);
    map['text_value'] = Variable<String>(textValue);
    map['translation_de'] = Variable<String>(translationDe);
    map['gap_start'] = Variable<int>(gapStart);
    map['gap_end'] = Variable<int>(gapEnd);
    map['source_ref'] = Variable<String>(sourceRef);
    map['sentence_ref'] = Variable<String>(sentenceRef);
    map['token_index'] = Variable<int>(tokenIndex);
    map['revision'] = Variable<String>(revision);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['tokens_json'] = Variable<String>(tokensJson);
    map['other_forms_json'] = Variable<String>(otherFormsJson);
    map['lang'] = Variable<String>(lang);
    map['provenance'] = Variable<String>(provenance);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CardContextsCompanion toCompanion(bool nullToAbsent) {
    return CardContextsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      textValue: Value(textValue),
      translationDe: Value(translationDe),
      gapStart: Value(gapStart),
      gapEnd: Value(gapEnd),
      sourceRef: Value(sourceRef),
      sentenceRef: Value(sentenceRef),
      tokenIndex: Value(tokenIndex),
      revision: Value(revision),
      fingerprint: Value(fingerprint),
      tokensJson: Value(tokensJson),
      otherFormsJson: Value(otherFormsJson),
      lang: Value(lang),
      provenance: Value(provenance),
      createdAt: Value(createdAt),
    );
  }

  factory CardContextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardContextRow(
      id: serializer.fromJson<String>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      textValue: serializer.fromJson<String>(json['textValue']),
      translationDe: serializer.fromJson<String>(json['translationDe']),
      gapStart: serializer.fromJson<int>(json['gapStart']),
      gapEnd: serializer.fromJson<int>(json['gapEnd']),
      sourceRef: serializer.fromJson<String>(json['sourceRef']),
      sentenceRef: serializer.fromJson<String>(json['sentenceRef']),
      tokenIndex: serializer.fromJson<int>(json['tokenIndex']),
      revision: serializer.fromJson<String>(json['revision']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      tokensJson: serializer.fromJson<String>(json['tokensJson']),
      otherFormsJson: serializer.fromJson<String>(json['otherFormsJson']),
      lang: serializer.fromJson<String>(json['lang']),
      provenance: serializer.fromJson<String>(json['provenance']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardId': serializer.toJson<String>(cardId),
      'textValue': serializer.toJson<String>(textValue),
      'translationDe': serializer.toJson<String>(translationDe),
      'gapStart': serializer.toJson<int>(gapStart),
      'gapEnd': serializer.toJson<int>(gapEnd),
      'sourceRef': serializer.toJson<String>(sourceRef),
      'sentenceRef': serializer.toJson<String>(sentenceRef),
      'tokenIndex': serializer.toJson<int>(tokenIndex),
      'revision': serializer.toJson<String>(revision),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'tokensJson': serializer.toJson<String>(tokensJson),
      'otherFormsJson': serializer.toJson<String>(otherFormsJson),
      'lang': serializer.toJson<String>(lang),
      'provenance': serializer.toJson<String>(provenance),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CardContextRow copyWith({
    String? id,
    String? cardId,
    String? textValue,
    String? translationDe,
    int? gapStart,
    int? gapEnd,
    String? sourceRef,
    String? sentenceRef,
    int? tokenIndex,
    String? revision,
    String? fingerprint,
    String? tokensJson,
    String? otherFormsJson,
    String? lang,
    String? provenance,
    DateTime? createdAt,
  }) => CardContextRow(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    textValue: textValue ?? this.textValue,
    translationDe: translationDe ?? this.translationDe,
    gapStart: gapStart ?? this.gapStart,
    gapEnd: gapEnd ?? this.gapEnd,
    sourceRef: sourceRef ?? this.sourceRef,
    sentenceRef: sentenceRef ?? this.sentenceRef,
    tokenIndex: tokenIndex ?? this.tokenIndex,
    revision: revision ?? this.revision,
    fingerprint: fingerprint ?? this.fingerprint,
    tokensJson: tokensJson ?? this.tokensJson,
    otherFormsJson: otherFormsJson ?? this.otherFormsJson,
    lang: lang ?? this.lang,
    provenance: provenance ?? this.provenance,
    createdAt: createdAt ?? this.createdAt,
  );
  CardContextRow copyWithCompanion(CardContextsCompanion data) {
    return CardContextRow(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      textValue: data.textValue.present ? data.textValue.value : this.textValue,
      translationDe: data.translationDe.present
          ? data.translationDe.value
          : this.translationDe,
      gapStart: data.gapStart.present ? data.gapStart.value : this.gapStart,
      gapEnd: data.gapEnd.present ? data.gapEnd.value : this.gapEnd,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      sentenceRef: data.sentenceRef.present
          ? data.sentenceRef.value
          : this.sentenceRef,
      tokenIndex: data.tokenIndex.present
          ? data.tokenIndex.value
          : this.tokenIndex,
      revision: data.revision.present ? data.revision.value : this.revision,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      tokensJson: data.tokensJson.present
          ? data.tokensJson.value
          : this.tokensJson,
      otherFormsJson: data.otherFormsJson.present
          ? data.otherFormsJson.value
          : this.otherFormsJson,
      lang: data.lang.present ? data.lang.value : this.lang,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardContextRow(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('textValue: $textValue, ')
          ..write('translationDe: $translationDe, ')
          ..write('gapStart: $gapStart, ')
          ..write('gapEnd: $gapEnd, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('sentenceRef: $sentenceRef, ')
          ..write('tokenIndex: $tokenIndex, ')
          ..write('revision: $revision, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('tokensJson: $tokensJson, ')
          ..write('otherFormsJson: $otherFormsJson, ')
          ..write('lang: $lang, ')
          ..write('provenance: $provenance, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    textValue,
    translationDe,
    gapStart,
    gapEnd,
    sourceRef,
    sentenceRef,
    tokenIndex,
    revision,
    fingerprint,
    tokensJson,
    otherFormsJson,
    lang,
    provenance,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardContextRow &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.textValue == this.textValue &&
          other.translationDe == this.translationDe &&
          other.gapStart == this.gapStart &&
          other.gapEnd == this.gapEnd &&
          other.sourceRef == this.sourceRef &&
          other.sentenceRef == this.sentenceRef &&
          other.tokenIndex == this.tokenIndex &&
          other.revision == this.revision &&
          other.fingerprint == this.fingerprint &&
          other.tokensJson == this.tokensJson &&
          other.otherFormsJson == this.otherFormsJson &&
          other.lang == this.lang &&
          other.provenance == this.provenance &&
          other.createdAt == this.createdAt);
}

class CardContextsCompanion extends UpdateCompanion<CardContextRow> {
  final Value<String> id;
  final Value<String> cardId;
  final Value<String> textValue;
  final Value<String> translationDe;
  final Value<int> gapStart;
  final Value<int> gapEnd;
  final Value<String> sourceRef;
  final Value<String> sentenceRef;
  final Value<int> tokenIndex;
  final Value<String> revision;
  final Value<String> fingerprint;
  final Value<String> tokensJson;
  final Value<String> otherFormsJson;
  final Value<String> lang;
  final Value<String> provenance;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CardContextsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.textValue = const Value.absent(),
    this.translationDe = const Value.absent(),
    this.gapStart = const Value.absent(),
    this.gapEnd = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.sentenceRef = const Value.absent(),
    this.tokenIndex = const Value.absent(),
    this.revision = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.tokensJson = const Value.absent(),
    this.otherFormsJson = const Value.absent(),
    this.lang = const Value.absent(),
    this.provenance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardContextsCompanion.insert({
    required String id,
    required String cardId,
    required String textValue,
    required String translationDe,
    required int gapStart,
    required int gapEnd,
    required String sourceRef,
    required String sentenceRef,
    required int tokenIndex,
    required String revision,
    required String fingerprint,
    required String tokensJson,
    required String otherFormsJson,
    required String lang,
    required String provenance,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cardId = Value(cardId),
       textValue = Value(textValue),
       translationDe = Value(translationDe),
       gapStart = Value(gapStart),
       gapEnd = Value(gapEnd),
       sourceRef = Value(sourceRef),
       sentenceRef = Value(sentenceRef),
       tokenIndex = Value(tokenIndex),
       revision = Value(revision),
       fingerprint = Value(fingerprint),
       tokensJson = Value(tokensJson),
       otherFormsJson = Value(otherFormsJson),
       lang = Value(lang),
       provenance = Value(provenance),
       createdAt = Value(createdAt);
  static Insertable<CardContextRow> custom({
    Expression<String>? id,
    Expression<String>? cardId,
    Expression<String>? textValue,
    Expression<String>? translationDe,
    Expression<int>? gapStart,
    Expression<int>? gapEnd,
    Expression<String>? sourceRef,
    Expression<String>? sentenceRef,
    Expression<int>? tokenIndex,
    Expression<String>? revision,
    Expression<String>? fingerprint,
    Expression<String>? tokensJson,
    Expression<String>? otherFormsJson,
    Expression<String>? lang,
    Expression<String>? provenance,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (textValue != null) 'text_value': textValue,
      if (translationDe != null) 'translation_de': translationDe,
      if (gapStart != null) 'gap_start': gapStart,
      if (gapEnd != null) 'gap_end': gapEnd,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (sentenceRef != null) 'sentence_ref': sentenceRef,
      if (tokenIndex != null) 'token_index': tokenIndex,
      if (revision != null) 'revision': revision,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (tokensJson != null) 'tokens_json': tokensJson,
      if (otherFormsJson != null) 'other_forms_json': otherFormsJson,
      if (lang != null) 'lang': lang,
      if (provenance != null) 'provenance': provenance,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardContextsCompanion copyWith({
    Value<String>? id,
    Value<String>? cardId,
    Value<String>? textValue,
    Value<String>? translationDe,
    Value<int>? gapStart,
    Value<int>? gapEnd,
    Value<String>? sourceRef,
    Value<String>? sentenceRef,
    Value<int>? tokenIndex,
    Value<String>? revision,
    Value<String>? fingerprint,
    Value<String>? tokensJson,
    Value<String>? otherFormsJson,
    Value<String>? lang,
    Value<String>? provenance,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CardContextsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      textValue: textValue ?? this.textValue,
      translationDe: translationDe ?? this.translationDe,
      gapStart: gapStart ?? this.gapStart,
      gapEnd: gapEnd ?? this.gapEnd,
      sourceRef: sourceRef ?? this.sourceRef,
      sentenceRef: sentenceRef ?? this.sentenceRef,
      tokenIndex: tokenIndex ?? this.tokenIndex,
      revision: revision ?? this.revision,
      fingerprint: fingerprint ?? this.fingerprint,
      tokensJson: tokensJson ?? this.tokensJson,
      otherFormsJson: otherFormsJson ?? this.otherFormsJson,
      lang: lang ?? this.lang,
      provenance: provenance ?? this.provenance,
      createdAt: createdAt ?? this.createdAt,
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
    if (textValue.present) {
      map['text_value'] = Variable<String>(textValue.value);
    }
    if (translationDe.present) {
      map['translation_de'] = Variable<String>(translationDe.value);
    }
    if (gapStart.present) {
      map['gap_start'] = Variable<int>(gapStart.value);
    }
    if (gapEnd.present) {
      map['gap_end'] = Variable<int>(gapEnd.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    if (sentenceRef.present) {
      map['sentence_ref'] = Variable<String>(sentenceRef.value);
    }
    if (tokenIndex.present) {
      map['token_index'] = Variable<int>(tokenIndex.value);
    }
    if (revision.present) {
      map['revision'] = Variable<String>(revision.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (tokensJson.present) {
      map['tokens_json'] = Variable<String>(tokensJson.value);
    }
    if (otherFormsJson.present) {
      map['other_forms_json'] = Variable<String>(otherFormsJson.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardContextsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('textValue: $textValue, ')
          ..write('translationDe: $translationDe, ')
          ..write('gapStart: $gapStart, ')
          ..write('gapEnd: $gapEnd, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('sentenceRef: $sentenceRef, ')
          ..write('tokenIndex: $tokenIndex, ')
          ..write('revision: $revision, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('tokensJson: $tokensJson, ')
          ..write('otherFormsJson: $otherFormsJson, ')
          ..write('lang: $lang, ')
          ..write('provenance: $provenance, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoryLearningAdditionsTable extends StoryLearningAdditions
    with TableInfo<$StoryLearningAdditionsTable, StoryAdditionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryLearningAdditionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cardId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_learning_additions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryAdditionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  StoryAdditionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryAdditionRow(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $StoryLearningAdditionsTable createAlias(String alias) {
    return $StoryLearningAdditionsTable(attachedDatabase, alias);
  }
}

class StoryAdditionRow extends DataClass
    implements Insertable<StoryAdditionRow> {
  final String cardId;
  final DateTime addedAt;
  const StoryAdditionRow({required this.cardId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<String>(cardId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  StoryLearningAdditionsCompanion toCompanion(bool nullToAbsent) {
    return StoryLearningAdditionsCompanion(
      cardId: Value(cardId),
      addedAt: Value(addedAt),
    );
  }

  factory StoryAdditionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryAdditionRow(
      cardId: serializer.fromJson<String>(json['cardId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<String>(cardId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  StoryAdditionRow copyWith({String? cardId, DateTime? addedAt}) =>
      StoryAdditionRow(
        cardId: cardId ?? this.cardId,
        addedAt: addedAt ?? this.addedAt,
      );
  StoryAdditionRow copyWithCompanion(StoryLearningAdditionsCompanion data) {
    return StoryAdditionRow(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryAdditionRow(')
          ..write('cardId: $cardId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cardId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryAdditionRow &&
          other.cardId == this.cardId &&
          other.addedAt == this.addedAt);
}

class StoryLearningAdditionsCompanion
    extends UpdateCompanion<StoryAdditionRow> {
  final Value<String> cardId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const StoryLearningAdditionsCompanion({
    this.cardId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoryLearningAdditionsCompanion.insert({
    required String cardId,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId),
       addedAt = Value(addedAt);
  static Insertable<StoryAdditionRow> custom({
    Expression<String>? cardId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoryLearningAdditionsCompanion copyWith({
    Value<String>? cardId,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return StoryLearningAdditionsCompanion(
      cardId: cardId ?? this.cardId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryLearningAdditionsCompanion(')
          ..write('cardId: $cardId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoryWordSourcesTable extends StoryWordSources
    with TableInfo<$StoryWordSourcesTable, StorySourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryWordSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta(
    'sourceRef',
  );
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentenceRefMeta = const VerificationMeta(
    'sentenceRef',
  );
  @override
  late final GeneratedColumn<String> sentenceRef = GeneratedColumn<String>(
    'sentence_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenIndexMeta = const VerificationMeta(
    'tokenIndex',
  );
  @override
  late final GeneratedColumn<int> tokenIndex = GeneratedColumn<int>(
    'token_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<String> revision = GeneratedColumn<String>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cardId,
    fingerprint,
    sourceRef,
    sentenceRef,
    tokenIndex,
    revision,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_word_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorySourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceRefMeta);
    }
    if (data.containsKey('sentence_ref')) {
      context.handle(
        _sentenceRefMeta,
        sentenceRef.isAcceptableOrUnknown(
          data['sentence_ref']!,
          _sentenceRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sentenceRefMeta);
    }
    if (data.containsKey('token_index')) {
      context.handle(
        _tokenIndexMeta,
        tokenIndex.isAcceptableOrUnknown(data['token_index']!, _tokenIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenIndexMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId, fingerprint};
  @override
  StorySourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorySourceRow(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      )!,
      sentenceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence_ref'],
      )!,
      tokenIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}token_index'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $StoryWordSourcesTable createAlias(String alias) {
    return $StoryWordSourcesTable(attachedDatabase, alias);
  }
}

class StorySourceRow extends DataClass implements Insertable<StorySourceRow> {
  final String cardId;
  final String fingerprint;
  final String sourceRef;
  final String sentenceRef;
  final int tokenIndex;
  final String revision;
  final DateTime addedAt;
  const StorySourceRow({
    required this.cardId,
    required this.fingerprint,
    required this.sourceRef,
    required this.sentenceRef,
    required this.tokenIndex,
    required this.revision,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<String>(cardId);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['source_ref'] = Variable<String>(sourceRef);
    map['sentence_ref'] = Variable<String>(sentenceRef);
    map['token_index'] = Variable<int>(tokenIndex);
    map['revision'] = Variable<String>(revision);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  StoryWordSourcesCompanion toCompanion(bool nullToAbsent) {
    return StoryWordSourcesCompanion(
      cardId: Value(cardId),
      fingerprint: Value(fingerprint),
      sourceRef: Value(sourceRef),
      sentenceRef: Value(sentenceRef),
      tokenIndex: Value(tokenIndex),
      revision: Value(revision),
      addedAt: Value(addedAt),
    );
  }

  factory StorySourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorySourceRow(
      cardId: serializer.fromJson<String>(json['cardId']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      sourceRef: serializer.fromJson<String>(json['sourceRef']),
      sentenceRef: serializer.fromJson<String>(json['sentenceRef']),
      tokenIndex: serializer.fromJson<int>(json['tokenIndex']),
      revision: serializer.fromJson<String>(json['revision']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<String>(cardId),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'sourceRef': serializer.toJson<String>(sourceRef),
      'sentenceRef': serializer.toJson<String>(sentenceRef),
      'tokenIndex': serializer.toJson<int>(tokenIndex),
      'revision': serializer.toJson<String>(revision),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  StorySourceRow copyWith({
    String? cardId,
    String? fingerprint,
    String? sourceRef,
    String? sentenceRef,
    int? tokenIndex,
    String? revision,
    DateTime? addedAt,
  }) => StorySourceRow(
    cardId: cardId ?? this.cardId,
    fingerprint: fingerprint ?? this.fingerprint,
    sourceRef: sourceRef ?? this.sourceRef,
    sentenceRef: sentenceRef ?? this.sentenceRef,
    tokenIndex: tokenIndex ?? this.tokenIndex,
    revision: revision ?? this.revision,
    addedAt: addedAt ?? this.addedAt,
  );
  StorySourceRow copyWithCompanion(StoryWordSourcesCompanion data) {
    return StorySourceRow(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      sentenceRef: data.sentenceRef.present
          ? data.sentenceRef.value
          : this.sentenceRef,
      tokenIndex: data.tokenIndex.present
          ? data.tokenIndex.value
          : this.tokenIndex,
      revision: data.revision.present ? data.revision.value : this.revision,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorySourceRow(')
          ..write('cardId: $cardId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('sentenceRef: $sentenceRef, ')
          ..write('tokenIndex: $tokenIndex, ')
          ..write('revision: $revision, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cardId,
    fingerprint,
    sourceRef,
    sentenceRef,
    tokenIndex,
    revision,
    addedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorySourceRow &&
          other.cardId == this.cardId &&
          other.fingerprint == this.fingerprint &&
          other.sourceRef == this.sourceRef &&
          other.sentenceRef == this.sentenceRef &&
          other.tokenIndex == this.tokenIndex &&
          other.revision == this.revision &&
          other.addedAt == this.addedAt);
}

class StoryWordSourcesCompanion extends UpdateCompanion<StorySourceRow> {
  final Value<String> cardId;
  final Value<String> fingerprint;
  final Value<String> sourceRef;
  final Value<String> sentenceRef;
  final Value<int> tokenIndex;
  final Value<String> revision;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const StoryWordSourcesCompanion({
    this.cardId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.sentenceRef = const Value.absent(),
    this.tokenIndex = const Value.absent(),
    this.revision = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoryWordSourcesCompanion.insert({
    required String cardId,
    required String fingerprint,
    required String sourceRef,
    required String sentenceRef,
    required int tokenIndex,
    required String revision,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId),
       fingerprint = Value(fingerprint),
       sourceRef = Value(sourceRef),
       sentenceRef = Value(sentenceRef),
       tokenIndex = Value(tokenIndex),
       revision = Value(revision),
       addedAt = Value(addedAt);
  static Insertable<StorySourceRow> custom({
    Expression<String>? cardId,
    Expression<String>? fingerprint,
    Expression<String>? sourceRef,
    Expression<String>? sentenceRef,
    Expression<int>? tokenIndex,
    Expression<String>? revision,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (sentenceRef != null) 'sentence_ref': sentenceRef,
      if (tokenIndex != null) 'token_index': tokenIndex,
      if (revision != null) 'revision': revision,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoryWordSourcesCompanion copyWith({
    Value<String>? cardId,
    Value<String>? fingerprint,
    Value<String>? sourceRef,
    Value<String>? sentenceRef,
    Value<int>? tokenIndex,
    Value<String>? revision,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return StoryWordSourcesCompanion(
      cardId: cardId ?? this.cardId,
      fingerprint: fingerprint ?? this.fingerprint,
      sourceRef: sourceRef ?? this.sourceRef,
      sentenceRef: sentenceRef ?? this.sentenceRef,
      tokenIndex: tokenIndex ?? this.tokenIndex,
      revision: revision ?? this.revision,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    if (sentenceRef.present) {
      map['sentence_ref'] = Variable<String>(sentenceRef.value);
    }
    if (tokenIndex.present) {
      map['token_index'] = Variable<int>(tokenIndex.value);
    }
    if (revision.present) {
      map['revision'] = Variable<String>(revision.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryWordSourcesCompanion(')
          ..write('cardId: $cardId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('sentenceRef: $sentenceRef, ')
          ..write('tokenIndex: $tokenIndex, ')
          ..write('revision: $revision, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningIdentityBindingsTable extends LearningIdentityBindings
    with TableInfo<$LearningIdentityBindingsTable, LearningBindingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningIdentityBindingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _identityKeyMeta = const VerificationMeta(
    'identityKey',
  );
  @override
  late final GeneratedColumn<String> identityKey = GeneratedColumn<String>(
    'identity_key',
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
  static const VerificationMeta _formNormMeta = const VerificationMeta(
    'formNorm',
  );
  @override
  late final GeneratedColumn<String> formNorm = GeneratedColumn<String>(
    'form_norm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semanticAnchorMeta = const VerificationMeta(
    'semanticAnchor',
  );
  @override
  late final GeneratedColumn<String> semanticAnchor = GeneratedColumn<String>(
    'semantic_anchor',
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
  @override
  List<GeneratedColumn> get $columns => [
    identityKey,
    lang,
    formNorm,
    semanticAnchor,
    cardId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_identity_bindings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningBindingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('identity_key')) {
      context.handle(
        _identityKeyMeta,
        identityKey.isAcceptableOrUnknown(
          data['identity_key']!,
          _identityKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityKeyMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('form_norm')) {
      context.handle(
        _formNormMeta,
        formNorm.isAcceptableOrUnknown(data['form_norm']!, _formNormMeta),
      );
    } else if (isInserting) {
      context.missing(_formNormMeta);
    }
    if (data.containsKey('semantic_anchor')) {
      context.handle(
        _semanticAnchorMeta,
        semanticAnchor.isAcceptableOrUnknown(
          data['semantic_anchor']!,
          _semanticAnchorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_semanticAnchorMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {identityKey};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {lang, formNorm, semanticAnchor},
  ];
  @override
  LearningBindingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningBindingRow(
      identityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_key'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      formNorm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form_norm'],
      )!,
      semanticAnchor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semantic_anchor'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
    );
  }

  @override
  $LearningIdentityBindingsTable createAlias(String alias) {
    return $LearningIdentityBindingsTable(attachedDatabase, alias);
  }
}

class LearningBindingRow extends DataClass
    implements Insertable<LearningBindingRow> {
  final String identityKey;
  final String lang;
  final String formNorm;
  final String semanticAnchor;
  final String cardId;
  const LearningBindingRow({
    required this.identityKey,
    required this.lang,
    required this.formNorm,
    required this.semanticAnchor,
    required this.cardId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['identity_key'] = Variable<String>(identityKey);
    map['lang'] = Variable<String>(lang);
    map['form_norm'] = Variable<String>(formNorm);
    map['semantic_anchor'] = Variable<String>(semanticAnchor);
    map['card_id'] = Variable<String>(cardId);
    return map;
  }

  LearningIdentityBindingsCompanion toCompanion(bool nullToAbsent) {
    return LearningIdentityBindingsCompanion(
      identityKey: Value(identityKey),
      lang: Value(lang),
      formNorm: Value(formNorm),
      semanticAnchor: Value(semanticAnchor),
      cardId: Value(cardId),
    );
  }

  factory LearningBindingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningBindingRow(
      identityKey: serializer.fromJson<String>(json['identityKey']),
      lang: serializer.fromJson<String>(json['lang']),
      formNorm: serializer.fromJson<String>(json['formNorm']),
      semanticAnchor: serializer.fromJson<String>(json['semanticAnchor']),
      cardId: serializer.fromJson<String>(json['cardId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'identityKey': serializer.toJson<String>(identityKey),
      'lang': serializer.toJson<String>(lang),
      'formNorm': serializer.toJson<String>(formNorm),
      'semanticAnchor': serializer.toJson<String>(semanticAnchor),
      'cardId': serializer.toJson<String>(cardId),
    };
  }

  LearningBindingRow copyWith({
    String? identityKey,
    String? lang,
    String? formNorm,
    String? semanticAnchor,
    String? cardId,
  }) => LearningBindingRow(
    identityKey: identityKey ?? this.identityKey,
    lang: lang ?? this.lang,
    formNorm: formNorm ?? this.formNorm,
    semanticAnchor: semanticAnchor ?? this.semanticAnchor,
    cardId: cardId ?? this.cardId,
  );
  LearningBindingRow copyWithCompanion(LearningIdentityBindingsCompanion data) {
    return LearningBindingRow(
      identityKey: data.identityKey.present
          ? data.identityKey.value
          : this.identityKey,
      lang: data.lang.present ? data.lang.value : this.lang,
      formNorm: data.formNorm.present ? data.formNorm.value : this.formNorm,
      semanticAnchor: data.semanticAnchor.present
          ? data.semanticAnchor.value
          : this.semanticAnchor,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningBindingRow(')
          ..write('identityKey: $identityKey, ')
          ..write('lang: $lang, ')
          ..write('formNorm: $formNorm, ')
          ..write('semanticAnchor: $semanticAnchor, ')
          ..write('cardId: $cardId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(identityKey, lang, formNorm, semanticAnchor, cardId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningBindingRow &&
          other.identityKey == this.identityKey &&
          other.lang == this.lang &&
          other.formNorm == this.formNorm &&
          other.semanticAnchor == this.semanticAnchor &&
          other.cardId == this.cardId);
}

class LearningIdentityBindingsCompanion
    extends UpdateCompanion<LearningBindingRow> {
  final Value<String> identityKey;
  final Value<String> lang;
  final Value<String> formNorm;
  final Value<String> semanticAnchor;
  final Value<String> cardId;
  final Value<int> rowid;
  const LearningIdentityBindingsCompanion({
    this.identityKey = const Value.absent(),
    this.lang = const Value.absent(),
    this.formNorm = const Value.absent(),
    this.semanticAnchor = const Value.absent(),
    this.cardId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningIdentityBindingsCompanion.insert({
    required String identityKey,
    required String lang,
    required String formNorm,
    required String semanticAnchor,
    required String cardId,
    this.rowid = const Value.absent(),
  }) : identityKey = Value(identityKey),
       lang = Value(lang),
       formNorm = Value(formNorm),
       semanticAnchor = Value(semanticAnchor),
       cardId = Value(cardId);
  static Insertable<LearningBindingRow> custom({
    Expression<String>? identityKey,
    Expression<String>? lang,
    Expression<String>? formNorm,
    Expression<String>? semanticAnchor,
    Expression<String>? cardId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (identityKey != null) 'identity_key': identityKey,
      if (lang != null) 'lang': lang,
      if (formNorm != null) 'form_norm': formNorm,
      if (semanticAnchor != null) 'semantic_anchor': semanticAnchor,
      if (cardId != null) 'card_id': cardId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningIdentityBindingsCompanion copyWith({
    Value<String>? identityKey,
    Value<String>? lang,
    Value<String>? formNorm,
    Value<String>? semanticAnchor,
    Value<String>? cardId,
    Value<int>? rowid,
  }) {
    return LearningIdentityBindingsCompanion(
      identityKey: identityKey ?? this.identityKey,
      lang: lang ?? this.lang,
      formNorm: formNorm ?? this.formNorm,
      semanticAnchor: semanticAnchor ?? this.semanticAnchor,
      cardId: cardId ?? this.cardId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (identityKey.present) {
      map['identity_key'] = Variable<String>(identityKey.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (formNorm.present) {
      map['form_norm'] = Variable<String>(formNorm.value);
    }
    if (semanticAnchor.present) {
      map['semantic_anchor'] = Variable<String>(semanticAnchor.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningIdentityBindingsCompanion(')
          ..write('identityKey: $identityKey, ')
          ..write('lang: $lang, ')
          ..write('formNorm: $formNorm, ')
          ..write('semanticAnchor: $semanticAnchor, ')
          ..write('cardId: $cardId, ')
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
  late final $CardContextsTable cardContexts = $CardContextsTable(this);
  late final $StoryLearningAdditionsTable storyLearningAdditions =
      $StoryLearningAdditionsTable(this);
  late final $StoryWordSourcesTable storyWordSources = $StoryWordSourcesTable(
    this,
  );
  late final $LearningIdentityBindingsTable learningIdentityBindings =
      $LearningIdentityBindingsTable(this);
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
    cardContexts,
    storyLearningAdditions,
    storyWordSources,
    learningIdentityBindings,
    reviewLogCard,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
