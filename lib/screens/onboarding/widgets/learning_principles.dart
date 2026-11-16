import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/learning_evidence.dart';
import '../../../theme/app_theme.dart';
import 'onboarding_motion.dart';

/// Small, interactive explanations. They never write learning progress.
class LearningPrinciples extends StatefulWidget {
  const LearningPrinciples({super.key, this.language = 'en'});
  final String language;

  @override
  State<LearningPrinciples> createState() => _LearningPrinciplesState();
}

class _LearningPrinciplesState extends State<LearningPrinciples> {
  double _visible = 0.55;
  bool _revealed = false;
  int _visit = 0;

  ({String text, String sentence, String word}) get _example =>
      switch (widget.language) {
        'pt-BR' => (
          text: 'Uma pequena história abre uma porta para novas palavras. Cada frase dá mais sentido ao que você aprende.',
          sentence: 'Eu … a porta.',
          word: 'abro',
        ),
        'es' => (
          text: 'Una pequeña historia abre una puerta a nuevas palabras. Cada frase da más sentido a lo que aprendes.',
          sentence: 'Yo … la puerta.',
          word: 'abro',
        ),
        'it' => (
          text: 'Una piccola storia apre una porta a nuove parole. Ogni frase dà più senso a quello che impari.',
          sentence: 'Io … la porta.',
          word: 'apro',
        ),
        'nb' => (
          text: 'En liten historie åpner en dør til nye ord. Hver setning gir mer mening til det du lærer.',
          sentence: 'Jeg … døren.',
          word: 'åpner',
        ),
        _ => (
          text: 'A small story opens a door to new words. Every sentence gives more meaning to what you learn.',
          sentence: 'I … the door.',
          word: 'open',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final example = _example;
    final words = example.text.split(' ');
    final shown = (_visible * words.length).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Warum so lernen?',
          style: AppType.editorial(size: 28, color: colors.textPrimary),
        ),
        const SizedBox(height: 22),
        _Principle(
          number: '01',
          title: 'Im Satz verstehen.',
          detail: 'Zusammenhang macht Wörter greifbar.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label:
                    'Beispieltext: $shown von ${words.length} Wörtern sichtbar.',
                value: [
                  for (final (i, word) in words.indexed)
                    (i.isEven ? i ~/ 2 : (words.length + 1) ~/ 2 + i ~/ 2) <
                            shown
                        ? word
                        : '…',
                ].join(' '),
                child: ExcludeSemantics(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 7,
                    children: [
                      for (final (i, word) in words.indexed)
                        // A fixed permutation reveals scattered words rather
                        // than a prefix. Counts refer only to this example.
                        AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (i.isEven
                                        ? i ~/ 2
                                        : (words.length + 1) ~/ 2 + i ~/ 2) <
                                    shown
                                ? const Color(0x00000000)
                                : colors.hairline,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            word,
                            style: AppType.editorial(
                              size: 20,
                              height: 1.45,
                              color:
                                  (i.isEven
                                          ? i ~/ 2
                                          : (words.length + 1) ~/ 2 + i ~/ 2) <
                                      shown
                                  ? colors.textPrimary
                                  : const Color(0x00000000),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Wörter im Beispiel aufdecken',
                child: CupertinoSlider(
                  key: const Key('context-words-slider'),
                  value: _visible,
                  min: 0.2,
                  activeColor: colors.textPrimary,
                  onChanged: (value) => setState(() => _visible = value),
                ),
              ),
              ColoredBox(
                color: colors.raisedInk,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$shown von ${words.length} Wörtern sichtbar',
                    textAlign: TextAlign.center,
                    style: AppType.meta(color: colors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _Principle(
          number: '02',
          title: 'Selbst abrufen.',
          detail: 'Vom deutschen Gedanken zum Wort in der Lernsprache.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ich öffne die Tür.',
                style: AppType.chrome(color: colors.textMuted),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: Text(
                  _revealed
                      ? example.sentence.replaceFirst('…', example.word)
                      : example.sentence,
                  key: ValueKey((_revealed, widget.language)),
                  style: AppType.editorial(size: 24, color: colors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                key: const Key('retrieval-reveal'),
                color: colors.nightPage,
                borderRadius: BorderRadius.circular(16),
                onPressed: () {
                  Haptic.select();
                  setState(() => _revealed = !_revealed);
                },
                child: Text(
                  _revealed ? 'Noch einmal abrufen' : 'Wort aufdecken',
                  style: AppType.chrome(
                    weight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _Principle(
          number: '03',
          title: 'Mit Abstand festigen.',
          detail: 'Wiedersehen. Erinnern. Weiterlernen.',
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Semantics(
                      selected: _visit == i,
                      child: CupertinoButton(
                        key: Key('spaced-visit-$i'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        color: _visit == i
                            ? colors.textPrimary
                            : colors.nightPage,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: () {
                          Haptic.select();
                          setState(() => _visit = i);
                        },
                        child: Text(
                          ['Heute', 'Morgen', 'Später'][i],
                          style: AppType.chrome(
                            size: 15,
                            weight: FontWeight.w600,
                            color: _visit == i
                                ? colors.nightPage
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                child: Column(
                  key: ValueKey(_visit),
                  children: [
                    Icon(
                      [
                        CupertinoIcons.book,
                        CupertinoIcons.arrow_clockwise,
                        CupertinoIcons.checkmark_circle,
                      ][_visit],
                      size: 30,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      [
                        'Entdecken',
                        'Wieder abrufen',
                        'Erneut festigen',
                      ][_visit],
                      style: AppType.chrome(
                        weight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Beispielrhythmus. Deine Antworten bestimmen die Abstände.',
                textAlign: TextAlign.center,
                style: AppType.meta(color: colors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextAction(
            label: 'Die Forschung dahinter',
            onTap: () => showLearningEvidence(context),
            size: 15,
          ),
        ),
      ],
    );
  }
}

class _Principle extends StatelessWidget {
  const _Principle({
    required this.number,
    required this.title,
    required this.detail,
    required this.child,
  });
  final String number, title, detail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(number, style: AppType.meta(color: colors.textMuted)),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppType.editorial(size: 24, color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Text(detail, style: AppType.chrome(color: colors.textMuted)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.raisedInk,
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ],
    );
  }
}

Future<void> showLearningEvidence(
  BuildContext context,
) => showCupertinoModalPopup<void>(
  context: context,
  builder: (sheetContext) {
    final colors = sheetContext.appColors;
    return SafeArea(
      top: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        decoration: BoxDecoration(
          color: colors.raisedInk,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextAction(
                  label: 'Schließen',
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ),
              Text(
                'Gut erforschte Lernprinzipien.',
                style: AppType.editorial(size: 28, color: colors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Diese Studien untersuchen Lernmethoden. Eine eigene Wirksamkeitsstudie zu Linglossa liegt noch nicht vor.',
                style: AppType.chrome(color: colors.textMuted),
              ),
              for (final evidence in learningEvidence) ...[
                const SizedBox(height: 24),
                Text(
                  evidence.title,
                  style: AppType.chrome(
                    weight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  evidence.finding,
                  style: AppType.chrome(color: colors.textMuted),
                ),
                TextAction(
                  label: 'Studie öffnen',
                  size: 15,
                  onTap: () async {
                    try {
                      if (await launchUrl(
                        Uri.parse(evidence.url),
                        mode: LaunchMode.externalApplication,
                      )) {
                        return;
                      }
                    } catch (_) {
                      /* Keep the evidence sheet available. */
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Die Studie konnte nicht geöffnet werden.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  },
);

class PremiumComparison extends StatelessWidget {
  const PremiumComparison({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const rows = [
      ('Wortschatz-Stapel', 'Allgemeine Sprache', 'Alle'),
      ('Stories', '1', 'Alle'),
      ('Eigene Themen', '1× bis 50 Wörter', '5 Aufträge / 24 h¹'),
      ('Eigene Texte', '—', '✓'),
      ('Text-, Hör- & Grammatikübungen', '—', '✓'),
      ('Neue KI-Übersetzungen', '5 gesamt', '500 / Monat'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Dein Tempo.\nDein Umfang.',
            style: AppType.editorial(size: 28, color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: 20),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.65),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                const SizedBox(),
                _cell(context, 'Free', true),
                _cell(context, 'Premium', true),
              ],
            ),
            for (final row in rows)
              TableRow(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.hairline)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 10, 16),
                    child: Text(
                      row.$1,
                      style: AppType.chrome(
                        size: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  _cell(context, row.$2, false),
                  _cell(context, row.$3, true),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '¹ Bis zu 50 Wörter pro Auftrag, höchstens 250 in 24 Stunden. Gemeinsame Kostenlimits können die Nutzung zusätzlich begrenzen.',
          style: AppType.meta(color: colors.textMuted),
        ),
        const SizedBox(height: 8),
        Text(
          'Free bleibt kostenlos. Ohne Testabo.',
          style: AppType.chrome(
            size: 15,
            weight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, String text, bool strong) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
    child: text == '✓' || text == '—'
        ? Semantics(
            label: text == '✓' ? 'Enthalten' : 'Nicht enthalten',
            child: ExcludeSemantics(
              child: Icon(
                text == '✓' ? CupertinoIcons.checkmark : CupertinoIcons.minus,
                size: 20,
                color: context.appColors.textPrimary,
              ),
            ),
          )
        : Text(
            text,
            textAlign: TextAlign.center,
            style: AppType.chrome(
              size: 15,
              weight: strong ? FontWeight.w700 : FontWeight.w500,
              color: context.appColors.textPrimary,
            ),
          ),
  );
}
