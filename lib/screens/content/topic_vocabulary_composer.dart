import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/generated_vocabulary_client.dart';
import '../../domain/generated_vocabulary.dart';
import '../../domain/srs_state.dart';
import '../../presentation/providers/generated_vocabulary_provider.dart';
import '../../presentation/providers/premium_access_provider.dart';
import '../../widgets/premium_content_gate.dart';
import '../../theme/app_theme.dart';
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
  String? _error, _notice;
  GeneratedVocabularyRequest? _request;

  @override
  void dispose() {
    _text.dispose();
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
    }
  }

  Future<void> _generate() async {
    if (_busy) return;
    if (!ref.read(premiumContentAccessProvider)) {
      await showPremiumContentPaywall(
        context,
        interest: 'Eigene Vokabelthemen',
      );
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
      final draft = await service.generate(attempt, statusOnly: _checkStatus);
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
      setState(() {
        _notice = result;
        if (result != null) _text.clear();
        _request = null;
      });
    } on GeneratedVocabularyFailure catch (e) {
      if (!mounted || widget.lang != lang || _request != attempt) return;
      setState(() {
        _error = e.message;
        _checkStatus = e.uncertain || e.code == 'REQUEST_PENDING';
        if (!_checkStatus && e.code != 'REQUEST_MISSING') _request = null;
        if (e.code == 'REQUEST_MISSING') {
          _checkStatus = false;
          _error = 'Es wurde noch keine Generierung gestartet. Du kannst es erneut versuchen.';
        }
      });
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final premium = ref.watch(premiumContentAccessProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final locked = !premium || _busy || _checkStatus;
    final canGenerate =
        premium && !_busy && (_checkStatus || _text.text.trim().isNotEmpty);
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
        const SizedBox(height: 14),
        // One field like a prompt box (user request 01.11.2026): the topic on
        // top, word count and action in a row inside. While generating, a bar
        // appears in the space kept free above the text and the text glints;
        // nothing moves.
        Semantics(
          button: !premium,
          label: !premium
              ? "Vokabeln zu deinem Thema erstellen, mit Premium freischalten"
              : null,
          excludeSemantics: !premium,
          onTap: !premium ? _generate : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: !premium ? _generate : null,
            child: AbsorbPointer(
              absorbing: !premium,
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
                            enabled: !locked,
                            minLines: 3,
                            maxLines: 6,
                            maxLength: 400,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                            textCapitalization: TextCapitalization.sentences,
                            placeholder: 'Zum Beispiel: Medizin, besonders Gehirn, Arme und Krankheiten.',
                            placeholderStyle: AppType.chrome(
                              color: colors.textMuted,
                              height: 1.45,
                            ),
                            style: AppType.chrome(
                              color: _busy
                                  ? colors.textMuted
                                  : colors.textPrimary,
                              height: 1.45,
                            ),
                            cursorColor: colors.active,
                            padding: EdgeInsets.fromLTRB(
                              18,
                              premium ? _fieldTop : 52,
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
                    if (!premium)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: PremiumLockBadge(),
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
        if (_checkStatus && !_busy)
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () => setState(() {
                _request = null;
                _checkStatus = false;
                _error = null;
              }),
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
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
