import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';

import '../../data/generated_vocabulary_client.dart';
import '../../data/learning/generated_vocabulary_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/press_scale.dart';

class GeneratedVocabularySelectionScreen extends StatefulWidget {
  const GeneratedVocabularySelectionScreen({
    super.key,
    required this.draft,
    required this.service,
    required this.hasDeck,
  });
  final GeneratedVocabularyDraft draft;
  final GeneratedVocabularyService service;
  final bool hasDeck;
  @override
  State<GeneratedVocabularySelectionScreen> createState() =>
      _GeneratedVocabularySelectionScreenState();
}

class _GeneratedVocabularySelectionScreenState
    extends State<GeneratedVocabularySelectionScreen>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.isDismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  late final _selected = {
    for (var i = 0; i < widget.draft.response.items.length; i++)
      if (!widget.draft.existingForms.contains(
        widget.draft.response.items[i].formNorm,
      ))
        i,
  };
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving || _selected.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.service.save(widget.draft, Set.of(_selected));
      if (!mounted) return;
      if (result.savedCount == 0) {
        setState(
          () => _error =
              'Diese Wörter sind deaktiviert oder zurückgestellt. '
              'Dein bestehender Lernstand bleibt erhalten.',
        );
      } else {
        Navigator.of(context).pop(
          '${result.addedIds.length} Wörter im Stapel „Generierte Vokabeln“ gespeichert.'
          '${result.blockedForms.isEmpty ? '' : ' ${result.blockedForms.length} deaktivierte oder zurückgestellte Wörter übersprungen.'}',
        );
      }
    } on GeneratedVocabularyFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Speichern nicht bestätigt. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = widget.draft.response.items;
    // Scaffold, not CupertinoPageScaffold: it gives the text its default
    // style (without one Flutter underlines every Text in yellow).
    return Scaffold(
      backgroundColor: colors.nightPage,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                BackBar(
                  onBack: () {
                    if (!_saving) Navigator.of(context).maybePop();
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Wähle deine Wörter',
                          style: AppType.editorial(
                            size: 32,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Small chips side by side (user request 01.11.2026, like the
                      // Jenzi word picker): word and German only; tap to (de)select.
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < items.length; i++) _chip(i),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              style: AppType.chrome(color: colors.textPrimary),
                            ),
                          ),
                        ),
                      PrimaryActionButton(
                        label: _saving
                            ? 'Wird gespeichert'
                            : widget.hasDeck
                            ? 'Zum Stapel hinzufügen'
                            : 'Stapel erstellen',
                        onPressed: _saving || _selected.isEmpty ? null : _save,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(int index) {
    final item = widget.draft.response.items[index];
    final existing = widget.draft.existingForms.contains(item.formNorm);
    // Chips arrive one after another, quickly.
    final start = (index * 0.03).clamp(0.0, 0.6);
    final arrive = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, start + 0.4, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: arrive,
      child: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.0).animate(arrive),
        child: GeneratedWordChip(
          key: ValueKey('generated-word-$index'),
          word: item.form,
          gloss: existing ? 'Bereits im Stapel' : item.glossDe,
          selected: _selected.contains(index),
          onTap: existing || _saving
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (!_selected.remove(index)) _selected.add(index);
                  });
                },
        ),
      ),
    );
  }
}

/// One generated word: the word in serif with its German below. Selected
/// chips look like any card; a deselected one is greyed out, no check mark.
class GeneratedWordChip extends StatelessWidget {
  const GeneratedWordChip({
    super.key,
    required this.word,
    required this.gloss,
    required this.selected,
    required this.onTap,
  });

  final String word, gloss;
  final bool selected;

  /// Null: already in the deck, cannot be chosen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: '$word, $gloss',
      excludeSemantics: true,
      child: PressScale(
        pressedScale: 0.95,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
            decoration: BoxDecoration(
              color: selected ? colors.raisedInk : colors.nightPage,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colors.raisedInk : colors.hairline,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: duration,
                  style: AppType.editorial(
                    size: 17,
                    height: 1.25,
                    color: selected ? colors.textPrimary : colors.iconOff,
                  ),
                  child: Text(word),
                ),
                const SizedBox(height: 1),
                AnimatedDefaultTextStyle(
                  duration: duration,
                  style: AppType.chrome(
                    size: 13,
                    weight: FontWeight.w500,
                    color: selected ? colors.textMuted : colors.iconOff,
                  ),
                  child: Text(gloss),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
