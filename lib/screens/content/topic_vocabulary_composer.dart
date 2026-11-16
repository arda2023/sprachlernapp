import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/generated_vocabulary_client.dart';
import '../../data/learning/generated_vocabulary_service.dart';
import '../../domain/generated_vocabulary.dart';
import '../../domain/srs_state.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/generated_vocabulary_provider.dart';
import '../../presentation/providers/personal_learning_provider.dart';
import '../../presentation/providers/premium_access_provider.dart';
import '../../widgets/premium_content_gate.dart';
import '../../theme/app_theme.dart';
import '../onboarding/widgets/account_sheet.dart';
import 'generated_vocabulary_selection_screen.dart';
import '../../widgets/light_sweep.dart';
import 'widgets/generation_progress_bar.dart';

/// Private vocabulary for a topic of the learner's own (PRODUCT.md ›
/// Inhalte): one sentence says what it does, the rest is the field.
class TopicVocabularyComposer extends ConsumerStatefulWidget {
  const TopicVocabularyComposer({super.key, required this.lang});
  final String lang;

  static const headline = 'Erstelle Vokabeln zu deinem Thema.';
  @override
  ConsumerState<TopicVocabularyComposer> createState() =>
      _TopicVocabularyComposerState();
}

class _TopicVocabularyComposerState
    extends ConsumerState<TopicVocabularyComposer> {
  final _text = TextEditingController();
  int _count = 25;
  bool _busy = false, _complete = false, _checkStatus = false;
  bool _pendingFree = false;
  String? _error, _notice;
  GeneratedVocabularyRequest? _request;
  final _topicFocus = FocusNode();
  ProviderSubscription<AsyncValue<GeneratedVocabularyRequest?>>?
  _pendingSubscription;

  @override
  void initState() {
    super.initState();
    _listenForPending();
  }

  void _listenForPending() {
    _pendingSubscription?.close();
    _pendingSubscription = ref.listenManual(
      pendingGeneratedVocabularyRequestProvider(widget.lang),
      (_, next) {
        final request = next.asData?.value;
        if (mounted && request != null && !_busy && _request == null) {
          _restorePending(request);
        }
      },
      fireImmediately: true,
    );
  }

  void _restorePending(GeneratedVocabularyRequest request) {
    setState(() {
      _request = request;
      _count = request.count;
      _text.text = request.prompt;
      _checkStatus = true;
      _pendingFree = true;
      _busy = false;
    });
  }

  @override
  void dispose() {
    _pendingSubscription?.close();
    _text.dispose();
    _topicFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TopicVocabularyComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang) {
      _text.clear();
      _request = null;
      _error = null;
      _notice = null;
      _busy = false;
      _complete = false;
      _checkStatus = false;
      _pendingFree = false;
      _listenForPending();
    }
  }

  Future<void> _generate() async {
    if (_busy) return;
    if (_requiresPremium(
      ref.read(premiumContentAccessProvider),
      ref.read(contentAuthProvider).configured,
      ref.read(freeVocabularyGenerationAvailableProvider).asData?.value,
    )) {
      await _openUpgrade();
      return;
    }
    final lang = widget.lang;
    final request = _request;
    try {
      _request =
          request ??
          GeneratedVocabularyRequest(
            requestId: randomUuidV4(),
            lang: lang,
            prompt: _text.text,
            count: _count,
          );
    } on FormatException {
      setState(
        () => _error = 'Bitte beschreibe dein Thema in höchstens zwei Sätzen und 400 Zeichen.',
      );
      return;
    }
    final attempt = _request!;
    final statusOnly = _checkStatus;
    final premium = ref.read(premiumContentAccessProvider);
    GeneratedVocabularyService? activeService;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _complete = false;
      _error = null;
      _notice = null;
    });
    try {
      final service = await ref.read(generatedVocabularyServiceProvider.future);
      if (!mounted || widget.lang != lang || _request != attempt) return;
      activeService = service;
      if (!statusOnly && !premium) {
        final pending = await service.stageFreeRequest(attempt);
        if (!mounted || widget.lang != lang || _request != attempt) return;
        if (pending.requestId != attempt.requestId) {
          _restorePending(pending);
          return;
        }
        _pendingFree = true;
        ref.invalidate(pendingGeneratedVocabularyRequestProvider(attempt.lang));
      }
      final draft = await service.generate(attempt, statusOnly: statusOnly);
      if (!mounted || widget.lang != lang || _request != attempt) return;
      ref.invalidate(freeVocabularyGenerationAvailableProvider);
      final hasDeck = await service.hasDeck();
      if (!mounted || widget.lang != lang || _request != attempt) return;
      draft.verify();
      setState(() {
        _complete = true;
        _checkStatus = false;
      });
      if (!MediaQuery.disableAnimationsOf(context)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (!mounted || widget.lang != lang || _request != attempt) return;
      final result = await Navigator.of(context).push<String>(
        CupertinoPageRoute(
          builder: (_) => GeneratedVocabularySelectionScreen(
            draft: draft,
            service: service,
            hasDeck: hasDeck,
          ),
        ),
      );
      if (!mounted || widget.lang != lang || _request != attempt) return;
      if (result != null || !draft.response.freeSample) {
        await _clearPending(service, attempt);
      }
      if (!mounted || widget.lang != lang || _request != attempt) return;
      setState(() {
        _notice = result;
        if (result != null) _text.clear();
        if (result == null && draft.response.freeSample) {
          _checkStatus = true;
        } else {
          _request = null;
        }
      });
    } on GeneratedVocabularyFailure catch (e) {
      if (!mounted || widget.lang != lang || _request != attempt) return;
      if (e.code != 'AUTH_REQUIRED' && e.code != 'CONSENT_REQUIRED') {
        ref.invalidate(freeVocabularyGenerationAvailableProvider);
      }
      final statusBlocked =
          statusOnly &&
          {
            'AUTH_REQUIRED',
            'CONSENT_REQUIRED',
            'ACCOUNT_UNVERIFIED',
            'ACCESS_CHANGED',
          }.contains(e.code);
      final keep = e.uncertain || statusBlocked || e.code == 'REQUEST_MISSING';
      if (!keep && activeService != null) {
        try {
          await _clearPending(activeService, attempt);
        } catch (_) {
          if (mounted && widget.lang == lang && _request == attempt) {
            setState(() {
              _error = e.message;
              _checkStatus = true;
            });
          }
          return;
        }
      }
      if (!mounted || widget.lang != lang || _request != attempt) return;
      setState(() {
        _error = e.message;
        _checkStatus = e.uncertain || statusBlocked;
        if (!_checkStatus && e.code != 'REQUEST_MISSING') _request = null;
        if (e.code == 'REQUEST_MISSING') {
          _checkStatus = false;
          _error = 'Es wurde noch keine Generierung gestartet. Du kannst es erneut versuchen.';
        }
      });
      switch (e.code) {
        case 'AUTH_REQUIRED':
          await AccountSheet.show(context, AccountReason.signIn);
        case 'CONSENT_REQUIRED':
          await _showConsent();
        case 'PREMIUM_REQUIRED':
          await _openUpgrade();
      }
    } catch (_) {
      if (!mounted || widget.lang != lang || _request != attempt) return;
      setState(() {
        _error = 'Vorschläge konnten nicht geladen werden. Bitte versuche es erneut.';
        _checkStatus = true;
      });
    } finally {
      if (mounted && widget.lang == lang && _request == attempt) {
        setState(() {
          _busy = false;
          _complete = false;
        });
      } else if (mounted && widget.lang == lang && _request == null) {
        setState(() {
          _busy = false;
          _complete = false;
        });
      }
    }
  }

  Future<void> _clearPending(
    GeneratedVocabularyService service,
    GeneratedVocabularyRequest attempt,
  ) async {
    if (!_pendingFree) return;
    await service.clearFreeRequest(attempt.requestId);
    if (mounted && _request == attempt) {
      ref.invalidate(pendingGeneratedVocabularyRequestProvider(attempt.lang));
      _pendingFree = false;
    }
  }

  Future<void> _changeTopic() async {
    final attempt = _request;
    if (_pendingFree && attempt != null) {
      try {
        final service = await ref.read(
          generatedVocabularyServiceProvider.future,
        );
        if (!mounted || _request != attempt) return;
        await _clearPending(service, attempt);
      } catch (_) {
        if (mounted && _request == attempt) {
          setState(
            () => _error = 'Die offene Anfrage konnte nicht entfernt werden.',
          );
        }
        return;
      }
    }
    if (!mounted || _request != attempt) return;
    setState(() {
      _request = null;
      _checkStatus = false;
      _error = null;
    });
  }

  bool _requiresPremium(bool premium, bool configured, bool? freeAvailable) =>
      !premium && !_checkStatus && (!configured || freeAvailable == false);

  Future<void> _openUpgrade() async {
    final lang = widget.lang;
    final auth = ref.read(contentAuthProvider);
    final owner = auth.localOwner;
    final paid = await showPremiumContentPaywall(
      context,
      interest: 'Eigene Vokabelthemen',
    );
    if (paid &&
        mounted &&
        widget.lang == lang &&
        (owner == null || owner == auth.localOwner)) {
      _topicFocus.requestFocus();
    }
  }

  Future<void> _showConsent() async {
    final client = ref.read(personalLearningClientProvider);
    final lang = widget.lang;
    try {
      final owner = await client.owner();
      final identity = client.revision();
      if (!mounted || owner == null || lang != widget.lang) return;
      final accepted = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Private Lernkarten mit KI'),
          content: const Text(
            'Für Themenvokabeln wird deine Themenbeschreibung an Anthropic '
            'gesendet. Die Freigabe gilt auch für private KI-Lernkarten '
            'und lässt sich in den Einstellungen widerrufen.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Später'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Freigeben'),
            ),
          ],
        ),
      );
      if (!mounted ||
          accepted != true ||
          identity != client.revision() ||
          lang != widget.lang) {
        return;
      }
      await client.setConsent(true);
      if (mounted && identity == client.revision()) {
        setState(() => _error = null);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Freigabe nicht gespeichert.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountSessionProvider, (previous, next) {
      final prior = previous?.asData?.value?.id;
      if (prior != null && prior != next.asData?.value?.id && next.hasValue) {
        setState(() {
          _text.clear();
          _request = null;
          _checkStatus = false;
          _pendingFree = false;
          _error = null;
          _notice = null;
          _busy = false;
          _complete = false;
        });
      }
    });
    final colors = context.appColors;
    final premium = ref.watch(premiumContentAccessProvider);
    final configured = ref.watch(contentAuthProvider).configured;
    final available = ref
        .watch(freeVocabularyGenerationAvailableProvider)
        .asData
        ?.value;
    final premiumRequired = _requiresPremium(premium, configured, available);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final locked = premiumRequired || _busy || _checkStatus || _pendingFree;
    final canGenerate =
        !premiumRequired &&
        !_busy &&
        (_checkStatus || _text.text.trim().isNotEmpty);
    final canChangeAttempt = _pendingFree ? !_checkStatus : _checkStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            TopicVocabularyComposer.headline,
            style: AppType.editorial(size: 24, color: colors.textPrimary),
          ),
        ),
        if (!premium && !premiumRequired && !_checkStatus)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Ein Thema mit bis zu 50 Wörtern kostenlos pro Konto.',
              style: AppType.meta(color: colors.textMuted),
            ),
          ),
        const SizedBox(height: 14),
        // One field like a prompt box (user request 01.11.2026): the topic on
        // top, word count and action in a row inside. While generating, a bar
        // appears in the space kept free above the text and the text glints;
        // nothing moves.
        Semantics(
          button: premiumRequired,
          label: premiumRequired
              ? "Vokabeln zu deinem Thema erstellen, mit Premium freischalten"
              : null,
          excludeSemantics: premiumRequired,
          onTap: premiumRequired ? _generate : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: premiumRequired ? _generate : null,
            child: AbsorbPointer(
              absorbing: premiumRequired,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.raisedInk,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LightSweep(
                          enabled: _busy && !_complete,
                          highlight: colors.textPrimary,
                          child: CupertinoTextField(
                            key: const ValueKey('generation-topic'),
                            controller: _text,
                            focusNode: _topicFocus,
                            enabled: !locked,
                            minLines: 3,
                            maxLines: 6,
                            maxLength: 400,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                            textCapitalization: TextCapitalization.sentences,
                            // An example request, slightly faded; it disappears
                            // with the first typed letter (user request 15.11.2026).
                            placeholder: 'Vokabeln über Medizin, speziell das Gehirn und wie man sich im Krankenhaus verständigt …',
                            placeholderStyle: AppType.chrome(
                              color: colors.textPrimary.withValues(alpha: 0.8),
                              height: 1.35,
                            ),
                            style: AppType.chrome(
                              color: _busy
                                  ? colors.textMuted
                                  : colors.textPrimary,
                              height: 1.35,
                            ),
                            cursorColor: colors.active,
                            // A tap anywhere else closes the keyboard.
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            padding: EdgeInsets.fromLTRB(
                              18,
                              premiumRequired ? 52 : _fieldTop,
                              18,
                              8,
                            ),
                            // Not null: a disabled field without decoration
                            // paints Cupertino's square near-black fill
                            // (locked and generating states).
                            decoration: const BoxDecoration(),
                            onChanged: (_) => setState(() {
                              _error = null;
                              _notice = null;
                              _request = null;
                            }),
                          ),
                        ),
                        // A Wrap, so very large text puts the action on its own line.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 8, 8),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 4,
                            children: [
                              Opacity(
                                opacity: locked ? 0.45 : 1,
                                child: CupertinoSlidingSegmentedControl<int>(
                                  groupValue: _count,
                                  thumbColor: colors.hairline,
                                  backgroundColor: colors.nightPage,
                                  padding: const EdgeInsets.all(3),
                                  children: {
                                    for (final n in [10, 25, 50])
                                      n: Semantics(
                                        label: '$n Wörter',
                                        child: ExcludeSemantics(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            child: Text(
                                              '$n',
                                              style: AppType.chrome(
                                                size: 15,
                                                weight: FontWeight.w600,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  },
                                  onValueChanged: locked
                                      ? (_) {}
                                      : (n) => setState(() {
                                          _count = n ?? _count;
                                          _request = null;
                                        }),
                                ),
                              ),
                              // The action fades in at its own place, so nothing shifts.
                              AnimatedSwitcher(
                                duration: reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 180),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween(
                                          begin: 0.85,
                                          end: 1.0,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: canGenerate
                                    ? _GenerateButton(
                                        key: ValueKey(_checkStatus),
                                        label: _checkStatus
                                            ? 'Ergebnis prüfen'
                                            : 'Generieren',
                                        onPressed: _generate,
                                      )
                                    : const SizedBox(
                                        key: ValueKey('none'),
                                        height: 44,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (premiumRequired)
                      PremiumVeil(
                        radius: BorderRadius.circular(22),
                        lockSize: 48,
                      ),
                    Positioned(
                      top: (_fieldTop - GenerationProgressBar.height) / 2,
                      left: 18,
                      right: 18,
                      child: GenerationProgressBar(
                        busy: _busy,
                        complete: _complete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: AppType.chrome(color: colors.textPrimary),
              ),
            ),
          ),
        if (!_busy && _request != null && canChangeAttempt)
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: _changeTopic,
              child: const Text('Eingabe ändern'),
            ),
          ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _notice!,
                style: AppType.chrome(color: colors.textPrimary),
              ),
            ),
          ),
      ],
    );
  }

  /// Room above the text for the progress bar.
  static const _fieldTop = 26.0;
}

/// Orange pill inside the topic field.
class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        // Only as wide as its label, never stretched by the Wrap around it.
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.active,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppType.chrome(
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.onActive,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
