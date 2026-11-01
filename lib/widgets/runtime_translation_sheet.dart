import 'speak_button.dart';
import '../domain/personal_learning.dart';
import 'personal_learning_button.dart';

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/offline_translation/offline_dictionary.dart';
import '../data/offline_translation/dictionary_selection.dart';
import '../data/runtime_translation_client.dart';
import '../presentation/providers/offline_translation_provider.dart';
import '../presentation/providers/purchase_provider.dart';
import '../presentation/providers/runtime_translation_provider.dart';
import '../theme/app_theme.dart';
import 'anchored_popover.dart';
import 'popover_content.dart';
import 'dictionary_sources_sheet.dart' show showDictionarySources;
import 'translation_paywall_card.dart';
import 'word_bubble.dart';

/// The reader has already checked its exact pack/context translation.
/// Only a word tap can start an automatic cloud lookup, and only after the
/// onboarding or Settings consent; mounting alone cannot. Dictionary sources
/// and licence live in Settings ([showDictionarySources]).
/// Shown as the orange popover pointing at the tapped word or sentence, like
/// a stored translation (design-system.md › Overlay-Regel).
class RuntimeTranslationSheet extends ConsumerStatefulWidget {
  const RuntimeTranslationSheet({
    super.key,
    required this.lang,
    required this.text,
    this.form,
    this.displayText,
    this.start,
    this.senseRef,
    this.formRef,
    this.wordTap = false,
    this.learningTarget,
    this.paywallFirst = false,
  });
  final PersonalTarget? learningTarget;
  final String lang, text;
  final String? form, displayText, senseRef, formRef;
  final int? start;
  final bool wordTap;

  /// The free AI translations are known to be used up: the bubble opens at
  /// the Premium card's size and only grows back for a saved translation.
  final bool paywallFirst;

  /// A word gets the small bubble, a sentence the full width.
  static double _width(BuildContext context, String? form, String? shown) =>
      form != null ? wordBubbleWidth(context, word: shown ?? form) : 440;
  static EdgeInsets _padding(String? form) =>
      form != null ? wordBubblePadding : const EdgeInsets.all(20);

  static bool _freeUsedUp(ProviderContainer container) =>
      container.read(freeTranslationsUsedUpProvider) &&
      !container.read(purchaseProvider).hasPremiumUiAccess;

  static Future<void> show(
    BuildContext context, {
    required Rect anchor,
    required String lang,
    required String text,
    String? form,
    String? displayText,
    int? start,
    String? senseRef,
    String? formRef,
    bool wordTap = false,
    PersonalTarget? learningTarget,
  }) {
    final paywallFirst = _freeUsedUp(
      ProviderScope.containerOf(context, listen: false),
    );
    return showAnchoredPopoverAt<void>(
      context: context,
      anchor: anchor,
      color: context.appColors.popover,
      maxWidth: paywallFirst
          ? wordBubbleWidth(context)
          : _width(context, form, displayText),
      padding: paywallFirst ? translationPaywallPadding : _padding(form),
      builder: (_) => RuntimeTranslationSheet(
        lang: lang,
        text: text,
        form: form,
        displayText: displayText,
        start: start,
        senseRef: senseRef,
        formRef: formRef,
        wordTap: wordTap,
        learningTarget: learningTarget,
        paywallFirst: paywallFirst,
      ),
    );
  }

  @override
  ConsumerState<RuntimeTranslationSheet> createState() =>
      _RuntimeTranslationSheetState();
}

class _RuntimeTranslationSheetState
    extends ConsumerState<RuntimeTranslationSheet> {
  StreamSubscription<void>? _changes;
  int _epoch = 0;
  bool checking = true, loading = false, started = false;

  /// Shows [TranslationPaywallCard] instead of the source text.
  bool usedUp = false;

  /// Opened at the Premium card's size, not yet grown back.
  late bool _compact = widget.paywallFirst;
  WordCloudConsent? consent;
  RuntimeTranslation? result;
  String? dictionaryText, error;

  /// The add button's last message (compact mode reports it here).
  String? learningMessage;
  List<DictionaryCandidate> candidates = [];
  bool _current(int epoch) => mounted && epoch == _epoch;

  @override
  void initState() {
    super.initState();
    _changes = ref.read(runtimeTranslationProvider).changes.listen((_) {
      _epoch++;
      if (!mounted) return;
      setState(() {
        result = null;
        dictionaryText = null;
        candidates = [];
        consent = null;
        started = true;
        loading = false;
        checking = false;
        usedUp = false;
        error =
            'Konto oder Übersetzungsspeicher geändert. Bitte erneut öffnen.';
      });
      _grow();
    });
    _load();
  }

  @override
  void didUpdateWidget(covariant RuntimeTranslationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang == widget.lang &&
        oldWidget.text == widget.text &&
        oldWidget.form == widget.form &&
        oldWidget.start == widget.start &&
        oldWidget.senseRef == widget.senseRef &&
        oldWidget.formRef == widget.formRef &&
        oldWidget.wordTap == widget.wordTap) {
      return;
    }
    _epoch++;
    result = null;
    dictionaryText = null;
    candidates = [];
    consent = null;
    started = false;
    loading = false;
    checking = true;
    usedUp = false;
    error = null;
    _load();
  }

  /// Back from the Premium card's size to the normal word or sentence
  /// bubble (a saved translation, an error, a word without AI).
  void _grow() {
    if (!_compact || !mounted) return;
    _compact = false;
    PopoverResize.to(
      context,
      maxWidth: RuntimeTranslationSheet._width(
        context,
        widget.form,
        widget.displayText,
      ),
      padding: RuntimeTranslationSheet._padding(widget.form),
    );
  }

  /// The free translations are gone: the bubble shrinks to the word
  /// bubble's size and turns into the Premium card.
  void _showPaywall() {
    if (!mounted) return;
    setState(() {
      usedUp = true;
      started = true;
      checking = false;
      loading = false;
      error = null;
    });
    if (_compact) return;
    _compact = true;
    PopoverResize.to(
      context,
      maxWidth: wordBubbleWidth(context),
      padding: translationPaywallPadding,
    );
  }

  Future<void> _load() async {
    final epoch = _epoch;
    final client = ref.read(runtimeTranslationProvider);
    try {
      final saved = await client.cached(
        lang: widget.lang,
        text: widget.text,
        form: widget.form,
        start: widget.start,
        senseRef: widget.senseRef,
        formRef: widget.formRef,
      );
      if (!_current(epoch)) return;
      if (saved != null) {
        setState(() {
          result = saved;
          checking = false;
        });
        _grow();
        return;
      }
      final form = widget.form;
      if (form != null) {
        final values = await ref
            .read(offlineDictionaryProvider)
            .lookup(widget.lang, form);
        if (!_current(epoch)) return;
        candidates = values;
        dictionaryText = singleDictionaryTranslation(form, values);
        if (dictionaryText == null && widget.wordTap) {
          consent = await client.wordCloudConsent();
          if (!_current(epoch)) return;
        }
      } else {
        consent = await client.wordCloudConsent();
        if (!_current(epoch)) return;
      }
      setState(() => checking = false);
      // With the AI switch on, words and sentences translate right away
      // (user decision 31.10.2026: no further notice in the bubble).
      if (consent == WordCloudConsent.enabled &&
          (form == null || widget.wordTap && dictionaryText == null)) {
        await request();
      } else if (widget.paywallFirst && form == null) {
        // "Übersetzen" could only fail now.
        _showPaywall();
      } else {
        _grow();
      }
    } on TranslationFailure catch (e) {
      if (_current(epoch)) {
        setState(() {
          error = e.message;
          started = true;
          checking = false;
        });
        _grow();
      }
    } catch (_) {
      if (_current(epoch)) {
        setState(() {
          error = 'Lokaler Übersetzungsspeicher nicht lesbar. Keine Onlineanfrage gestartet.';
          started = true;
          checking = false;
        });
        _grow();
      }
    }
  }

  Future<void> request() async {
    if (started || checking || loading) return;
    if (widget.form != null &&
        (!widget.wordTap || consent != WordCloudConsent.enabled)) {
      return;
    }
    if (RuntimeTranslationSheet._freeUsedUp(
      ProviderScope.containerOf(context),
    )) {
      _showPaywall();
      return;
    }
    final epoch = _epoch;
    setState(() {
      started = true;
      loading = true;
    });
    try {
      final client = ref.read(runtimeTranslationProvider);
      final value = widget.form == null
          ? await client.translate(lang: widget.lang, text: widget.text)
          : await client.translateWordOnTap(
              lang: widget.lang,
              text: widget.text,
              form: widget.form!,
              start: widget.start,
              senseRef: widget.senseRef,
              formRef: widget.formRef,
            );
      if (_current(epoch)) {
        setState(() => result = value);
        _grow();
      }
    } on TranslationFailure catch (e) {
      final premium =
          e.freeQuotaUsedUp && ref.read(purchaseProvider).hasPremiumUiAccess;
      if (e.freeQuotaUsedUp && !premium) {
        ref.read(freeTranslationsUsedUpProvider.notifier).markUsedUp();
        if (_current(epoch)) _showPaywall();
      } else if (premium) {
        // The app already knows Premium, the server not yet (entitlement
        // still syncing): no paywall and no free-quota sentence.
        if (_current(epoch)) {
          setState(
            () => error = 'Dein Premium wird noch bestätigt. Bitte gleich erneut versuchen.',
          );
          _grow();
        }
      } else if (_current(epoch)) {
        setState(() => error = e.message);
        _grow();
      }
    } catch (_) {
      if (_current(epoch)) {
        setState(() => error = 'Übersetzung derzeit nicht verfügbar.');
        _grow();
      }
    } finally {
      if (_current(epoch)) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _epoch++;
    _changes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Widget content = usedUp
        ? const TranslationPaywallCard(key: ValueKey('paywall'))
        : _compact
        ? const SizedBox(
            key: ValueKey('wait'),
            height: 56,
            child: Center(child: CupertinoActivityIndicator(color: popoverInk)),
          )
        : KeyedSubtree(
            key: const ValueKey('translation'),
            child: widget.form != null ? _word(context) : _sentence(context),
          );
    // The old face fades out on top while the bubble resizes to the new.
    final switcher = AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [
          for (final child in previous)
            Positioned(left: 0, right: 0, top: 0, child: child),
          ?current,
        ],
      ),
      child: content,
    );
    // AnimatedSize with a zero duration re-dirties itself during layout,
    // so reduced motion simply goes without it.
    if (reduceMotion) return switcher;
    return AnimatedSize(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: switcher,
    );
  }

  /// The small word bubble: word and speaker (and the add button) on one
  /// line, the translation below; nothing else unless something failed.
  Widget _word(BuildContext context) {
    final shown = widget.displayText ?? widget.form!;
    final translation = result?.text ?? dictionaryText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WordBubbleHeader(
          word: shown,
          speak: shown,
          language: widget.lang,
          trailing: switch (widget.learningTarget) {
            final target? => PersonalLearningButton(
              key: ValueKey(target.key),
              target: target,
              foregroundColor: popoverInk,
              compact: true,
              onMessage: (message) {
                if (mounted && message != learningMessage) {
                  setState(() => learningMessage = message);
                }
              },
            ),
            null => null,
          },
        ),
        if (checking || loading)
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CupertinoActivityIndicator(color: popoverInk),
            ),
          )
        else if (translation != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 6),
            child: Text(translation, style: wordBubbleTranslation()),
          ),
        if (result?.storageWarning case final warning?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(warning, style: PopoverText.caption()),
          ),
        if (error ?? learningMessage case final message?)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 6),
              child: Text(message, style: PopoverText.caption()),
            ),
          ),
      ],
    );
  }

  Widget _sentence(BuildContext context) {
    final serif = AppType.editorial(
      color: popoverInk,
      size: 20,
      weight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.displayText ?? widget.text,
          style: AppType.editorial(
            color: popoverInk,
            size: 19,
            weight: FontWeight.w600,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: SpeakButton(
            text: widget.displayText ?? widget.text,
            language: widget.lang,
          ),
        ),
        const SizedBox(height: 12),
        const PopoverDivider(),
        const SizedBox(height: 12),
        if (checking || loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CupertinoActivityIndicator(color: popoverInk),
          ),
        if (result case final value?) ...[
          Text(value.text, style: serif),
          if (value.storageWarning != null) ...[
            const SizedBox(height: 6),
            Text(value.storageWarning!, style: PopoverText.small()),
          ],
        ] else if (!checking && !loading && !started)
          // AI switched off: one explicit tap translates this sentence.
          PopoverPillButton(label: 'Übersetzen', onPressed: request),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: PopoverText.small()),
            ),
          ),
      ],
    );
  }
}
