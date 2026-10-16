import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'content.dart';

String learningHash(List<Object?> values) =>
    sha256.convert(utf8.encode(jsonEncode(values))).toString();

class LearningIdentity {
  const LearningIdentity(this.lang, this.formNorm, this.semanticAnchor, {this.function});
  final String? function;
  final String lang, formNorm, semanticAnchor;
  String get key =>
      learningHash(function == null ? ['learning-identity-v1', lang, formNorm, semanticAnchor] : ['form-learning-identity-v1', lang, formNorm, semanticAnchor, function]);
  String get localId =>
      'u:${learningHash(function == null ? ['local-card-v1', lang, formNorm, semanticAnchor] : ['local-form-card-v1', lang, formNorm, semanticAnchor, function])}';
}

/// Optional content capability. Read-only exclusions, never learner mutations.
abstract interface class RetiredLearningContentRepository {
  Future<Map<String, LearningIdentity>> retiredLearningIdentities();
}

class StorySummary {
  const StorySummary({
    required this.id,
    required this.title,
    required this.titleDe,
    required this.level,
    required this.minutes,
  });
  final String id, title, titleDe, level;
  final int minutes;
}

class StoryDocument {
  const StoryDocument(this.summary, this.revision, this.sentences);
  final StorySummary summary;
  final String revision;
  final List<StorySentence> sentences;
}

class StorySentence {
  const StorySentence({
    required this.id,
    required this.text,
    required this.translation,
    required this.paragraph,
    required this.tokens,
  });
  final String id, text, translation;
  final int paragraph;
  final List<StoryToken> tokens;
}

class StoryToken {
  const StoryToken({
    required this.index,
    required this.start,
    required this.end,
    required this.surface,
    this.cardId,
    this.formTarget,
    this.formFunction,
    this.lexicalTargetId,
    this.lemmaId,
    this.lemma,
    this.pos,
    this.senseId,
    this.senseKey,
    this.gloss,
    this.definition,
    this.contextApproved = false,
  });
  final int index, start, end;
  final FormTarget? formTarget;
  final String? formFunction, lexicalTargetId;
  String? get function => formTarget?.function ?? formFunction;
  String? get lexicalId => formTarget?.lexicalTargetId ?? lexicalTargetId;
  final String surface;
  final String? cardId,
      lemmaId,
      lemma,
      pos,
      senseId,
      senseKey,
      gloss,
      definition;
  final bool contextApproved;
  bool get annotated => [
    lemmaId,
    lemma,
    pos,
    senseId,
    senseKey,
    gloss,
    definition,
  ].every((s) => s != null && s.trim().isNotEmpty);
}

class StoryLearningCandidate {
  const StoryLearningCandidate({
    required this.storyId,
    required this.revision,
    required this.lang,
    required this.sentence,
    required this.token,
    this.card,
    this.retired = false,
    this.problem,
    this.otherForms = const {},
    this.groupMembers = const [],
  });
  final String storyId, revision, lang;
  final StorySentence sentence;
  final StoryToken token;
  final ContentCard? card;
  final bool retired;
  final String? problem;
  final Set<String> otherForms;
  final List<ContentCard> groupMembers;
  LearningIdentity get identity => LearningIdentity(
    lang,
    contentFormNorm(token.surface),
    token.senseId ?? '',
    function: token.function,
  );
  String get sourceFingerprint => learningHash([
    storyId,
    revision,
    sentence.id,
    token.index,
    sentence.text,
    sentence.translation,
    token.start,
    token.end,
    identity.key,
  ]);
  String? get unavailableReason => validationProblem();
  String? validationProblem({bool needsContext = true}) {
    if (problem != null) return problem;
    if (retired) return 'Diese Bedeutung ist nicht mehr zum Lernen verfügbar.';
    if (!token.annotated) {
      return 'Bedeutung oder Übersetzung ist nicht eindeutig belegt.';
    }
    if (token.start < 0 ||
        token.end > sentence.text.length ||
        token.start >= token.end ||
        sentence.text.substring(token.start, token.end) != token.surface) {
      return 'Die Wortstelle passt nicht zum gespeicherten Satz.';
    }
    if (token.function != null &&
        (!{'base', 'past', 'past_participle'}.contains(token.function) ||
         !{'VERB', 'AUX'}.contains(token.pos) ||
         token.lexicalId == null || token.lexicalId!.trim().isEmpty)) {
      return 'Form und Bedeutung sind nicht vollständig belegt.';
    }
    final form = token.formTarget;
    if (form != null && (form.cardId != token.cardId || form.senseId != token.senseId || contentFormNorm(form.form) != identity.formNorm)) {
      return 'Die Formreferenz passt nicht zum angetippten Wort.';
    }
    if (card != null && token.function != null && (card!.formFunction != token.function || card!.lexicalTargetId != token.lexicalId)) {
      return 'Die Lernkarte gehört zu einer anderen Form.';
    }
    if (card != null &&
        (card!.lang != lang ||
            card!.formNorm != identity.formNorm ||
            card!.senseId != identity.semanticAnchor)) {
      return 'Die Lernkarte passt nicht zur belegten Bedeutung.';
    }
    if (needsContext &&
        card == null &&
        (!token.contextApproved ||
            sentence.translation.trim().isEmpty ||
            sentence.tokens.where((t) => t.lemmaId != null).length > 20)) {
      return 'Für diese Bedeutung fehlt ein geprüfter Übungskontext.';
    }
    if (needsContext && card == null && token.function != null) {
      var cursor = 0;
      final ordered = [...sentence.tokens]..sort((a,b) => a.start.compareTo(b.start));
      for (var i = 0; i < ordered.length; i++) {
        final t = ordered[i];
        if (t.index != i || t.start < cursor || t.end <= t.start || t.end > sentence.text.length ||
            sentence.text.substring(cursor,t.start).trim().isNotEmpty ||
            sentence.text.substring(t.start,t.end) != t.surface ||
            (RegExp(r'[a-zA-Z]').hasMatch(t.surface) && !t.annotated)) {
          return 'Für diese Form fehlt eine vollständige Satzannotation.';
        }
        cursor = t.end;
      }
      if (sentence.text.substring(cursor).trim().isNotEmpty || !ordered.contains(token)) {
        return 'Für diese Form fehlt eine vollständige Satzannotation.';
      }
    }
    return null;
  }

  void validate() {
    if (unavailableReason case final message?) {
      throw StateError(message);
    }
  }
}

enum StoryAddState {
  available,
  added,
  disabled,
  retired,
  unavailable,
  conflict,
}

class StoryAddResult {
  const StoryAddResult(this.state, {this.cardId, this.message});
  final StoryAddState state;
  final String? cardId, message;
  bool get canAdd => state == StoryAddState.available;
  String get label => switch (state) {
    StoryAddState.available => 'Zum Lernen hinzufügen',
    StoryAddState.added => 'Bereits hinzugefügt',
    StoryAddState.disabled => 'Deaktiviert',
    StoryAddState.retired => 'Nicht mehr verfügbar',
    StoryAddState.unavailable => 'Zum Lernen nicht verfügbar',
    StoryAddState.conflict => 'Mehrere Lernstände vorhanden',
  };
}

abstract interface class StoryContentRepository {
  Future<List<StorySummary>> storySummaries();
  Future<StoryDocument> storyDocument(String id);
  Future<StoryLearningCandidate> resolveStoryWord(
    String storyId,
    String sentenceId,
    int tokenIndex,
  );
}

abstract interface class StoryLearningRepository {
  Future<StoryAddResult> storyLearningStatus(StoryLearningCandidate candidate);
  Future<StoryAddResult> addStoryWord(
    StoryLearningCandidate candidate, {
    required DateTime now,
  });
  Future<Map<String, DateTime>> explicitStoryAdditions();
  Future<Map<String, String>> identityBindings();
  Future<List<PracticeItem>> localPracticeItems();
  Future<CardSentence?> localHistoricalSentence(
    String cardId,
    String contextId,
  );
}
