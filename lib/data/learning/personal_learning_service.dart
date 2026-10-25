import 'dart:convert';

import '../../domain/content.dart';
import '../../domain/repositories.dart';
import '../../domain/story_learning.dart';
import '../../domain/personal_learning.dart';
import '../personal_learning_client.dart';
import 'practice_item_resolver.dart';

/// One explicit Add operation. No work is scheduled by reading a story.
class PersonalLearningService {
  PersonalLearningService({
    required this.content,
    required this.user,
    required this.client,
    required this.verify,
    this.release,
    this.translationHints,
  });
  final ContentRepository content;
  final UserRepository user;
  final PersonalLearningClient client;
  final void Function() verify;
  final Future<Map<String, dynamic>> Function()? release;
  final Future<Map<String, dynamic>> Function(PersonalTarget)? translationHints;
  final _inflight = <String, Future<StoryAddResult>>{};
  Future<StoryAddResult> add(PersonalTarget t) {
    final existing = _inflight[t.key];
    if (existing != null) return existing;
    final future = _add(t);
    _inflight[t.key] = future;
    return future.whenComplete(() => _inflight.remove(t.key));
  }

  Future<StoryAddResult?> saved(PersonalTarget t) async {
    final story = user as StoryLearningRepository;
    final bound = (await story.identityBindings())[t.identity.key];
    if (bound == null) return null;
    // Bound IDs always use the real repository guard; never treat errors as misses.
    final state = (await user.cardStates([bound]))[bound];
    if (state == null) {
      throw const PersonalLearningFailure(
        'Gespeicherte Zuordnung ist beschädigt.',
      );
    }
    if (state.localOnly &&
        !(await story.localPracticeItems()).any((i) => i.card.id == bound)) {
      throw const PersonalLearningFailure(
        'Gespeicherter Übungskontext ist nicht lesbar.',
      );
    }
    return StoryAddResult(
      state.retired
          ? StoryAddState.retired
          : state.disabled
          ? StoryAddState.disabled
          : StoryAddState.added,
      cardId: bound,
    );
  }

  Future<StoryAddResult> _add(PersonalTarget t) async {
    t.validate();
    verify();
    if (content.info.lang != t.lang) {
      throw const PersonalLearningFailure(
        'Sprache geändert. Bitte erneut öffnen.',
      );
    }
    final prior = await saved(t);
    if (prior != null) return prior;
    final resolver = await PracticeItemResolver.load(user, content);
    verify();
    final norm = contentFormNorm(t.form);
    // Resolver hides retired aliases from practice. Keep their evidence for
    // semantic comparison without reactivating them or changing any row.
    final locals = {
      for (final item
          in await (user as StoryLearningRepository).localPracticeItems())
        item.card.id: item,
    };
    final cards = {
      ...resolver.cards,
      for (final item in locals.values) item.card.id: item.card,
    };
    final retired = content is RetiredLearningContentRepository
        ? await (content as RetiredLearningContentRepository)
              .retiredLearningIdentities()
        : <String, LearningIdentity>{};
    final blocked = <String>{
      for (final e in retired.entries)
        if (e.value.lang == t.lang && e.value.formNorm == norm) e.key,
      for (final c in cards.values)
        if (c.lang == t.lang &&
            c.formNorm == norm &&
            (resolver.states[c.id]?.disabled == true ||
                resolver.states[c.id]?.retired == true))
          c.id,
    };
    final candidates =
        cards.values
            .where(
              // Case variants are one word; the gap keeps the exact surface.
              (c) => c.lang == t.lang && c.formNorm == norm && c.senseId != null,
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final localCandidates = <Map<String, dynamic>>[
      for (final c in candidates.where((c) => locals.containsKey(c.id)))
        {
          'id': c.id,
          'lemma': c.lemma,
          'pos': c.pos,
          'function': c.formFunction,
          'form': c.form,
          'lang': c.lang,
          'gloss_de': c.translationDe,
          'sentence': locals[c.id]!.practiceSentence.text,
          'translation_de': locals[c.id]!.practiceSentence.translationDe,
        },
    ];
    if (candidates.length > 24 || localCandidates.length > 4) {
      throw const PersonalLearningFailure(
        'Zu viele mögliche Bedeutungen. Dieses Ziel benötigt eine geprüfte Zuordnung.',
      );
    }
    await client.owner();
    final epoch = client.revision(), consentEpoch = client.consentRevision;
    final reference = await release?.call();
    if (reference == null) {
      throw const PersonalLearningFailure(
        'Ein veröffentlichter Inhaltspack ist erforderlich. Bitte Inhalte aktualisieren.',
      );
    }
    final hints = await translationHints?.call(t) ?? <String, dynamic>{};
    verify();
    if (epoch != client.revision() || consentEpoch != client.consentRevision) {
      throw const PersonalLearningFailure('Konto oder Freigabe geändert.');
    }
    final response = await client.create(
      t,
      candidates
          .where((c) => !locals.containsKey(c.id))
          .map((c) => c.id)
          .toList(),
      localCandidates: localCandidates,
      release: reference,
      hints: hints,
      blocked: blocked.toList(),
    );
    validatePersonalResponse(t, response);
    final distinctions = response['distinctions'] as Map;
    if (blocked.any((id) => distinctions[id]?['relation'] != 'independent')) {
      return const StoryAddResult(
        StoryAddState.unavailable,
        message: 'Diese Bedeutung ist zurückgestellt oder nicht eindeutig zuordenbar.',
      );
    }
    validatePersonalHints(t, response, hints);
    void current() {
      verify();
      if (epoch != client.revision() ||
          consentEpoch != client.consentRevision) {
        throw const PersonalLearningFailure(
          'Konto oder Freigabe geändert. Nichts gespeichert.',
        );
      }
    }

    current();
    final StoryLearningCandidate candidate;
    if (response['reuse_id'] case final String id) {
      final matches = candidates.where((c) => c.id == id).toList();
      if (matches.length != 1) {
        throw const PersonalLearningFailure('Unbekannte Kartenreferenz.');
      }
      final c = matches.single;
      if (blocked.any(
        (id) =>
            cards[id]?.senseId == c.senseId ||
            retired[id]?.semanticAnchor == c.senseId,
      )) {
        return const StoryAddResult(
          StoryAddState.unavailable,
          message: 'Diese Bedeutung ist zurückgestellt.',
        );
      }
      if (c.lemma != response['lemma'] ||
          c.pos != response['pos'] ||
          c.formFunction != response['function']) {
        throw const PersonalLearningFailure(
          'Bedeutung oder Formreferenz passt nicht.',
        );
      }
      // Check the actual active pack again, including its complete exercise.
      if (locals.containsKey(id)) {
        final currentItems = await (user as StoryLearningRepository)
            .localPracticeItems();
        if (!currentItems.any(
          (item) =>
              item.card.id == id &&
              item.card.senseId == c.senseId &&
              item.card.form == c.form,
        )) {
          throw const PersonalLearningFailure(
            'Lokale Kartenreferenz ist nicht mehr gültig.',
          );
        }
      } else {
        await content.practiceItems([id]);
      }
      final token = StoryToken(
        index: 0,
        start: t.start,
        end: t.end,
        surface: t.form,
        cardId: c.id,
        lemmaId: c.lemmaId,
        lemma: c.lemma,
        pos: c.pos,
        senseId: c.senseId,
        senseKey: c.senseKey ?? c.senseId,
        gloss: c.translationDe ?? response['gloss_de'],
        definition: response['definition_de'],
        formFunction: c.formFunction,
        lexicalTargetId: c.lexicalTargetId,
      );
      candidate = StoryLearningCandidate(
        storyId: t.source,
        revision: jsonEncode({'kind': 'private_link_v1', 'original': t.body}),
        lang: t.lang,
        sentence: StorySentence(
          id: t.key,
          text: t.text,
          translation: '',
          paragraph: 0,
          tokens: [token],
        ),
        token: token,
        card: c,
        groupMembers: cards.values
            .where(
              (other) =>
                  !other.id.startsWith('u:') &&
                  other.learningGroup == c.learningGroup,
            )
            .toList(),
      );
    } else {
      candidate = PersonalLearningCandidate.parse(
        t,
        response,
        independentOf: blocked,
        hints: hints,
      );
    }
    current();
    return (user as PersonalLearningStore).savePersonalLearning(
      candidate,
      now: DateTime.now(),
      source: t,
      verify: current,
    );
  }
}
