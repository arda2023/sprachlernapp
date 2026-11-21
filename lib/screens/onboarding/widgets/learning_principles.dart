import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/learning_evidence.dart';
import '../../../theme/app_theme.dart';
import 'onboarding_motion.dart';
import 'paywall_demos.dart';

/// The paywall benefits, each with a short animation of the real surface
/// (user request 21.11.2026). Not interactive; they never write learning
/// progress.
class LearningPrinciples extends StatelessWidget {
  const LearningPrinciples({super.key, this.language = 'en'});
  final String language;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final examples = PaywallExamples.of(language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Warum so lernen?',
          style: AppType.editorial(size: 28, color: colors.textPrimary),
        ),
        const SizedBox(height: 22),
        _Principle(
          title: 'Selbst abrufen.',
          detail: 'Wörter, die du selbst abrufst, bleiben besser hängen.',
          child: RecallDemo(examples: examples),
        ),
        const SizedBox(height: 32),
        _Principle(
          title: 'Im Satz verstehen.',
          detail:
              'Ein Tipp aufs Wort zeigt die Bedeutung, ohne den Lesefluss zu stoppen.',
          child: GlossDemo(examples: examples),
        ),
        const SizedBox(height: 32),
        _Principle(
          title: 'Frei schreiben.',
          detail:
              'Übersetze ganze Sätze. Der AI-Tutor zeigt dir, was sich verbessern lässt.',
          child: TutorDemo(examples: examples),
        ),
        const SizedBox(height: 32),
        _Principle(
          title: 'Wörter zu deinem Thema.',
          detail: 'Beschreibe ein Thema. Linglossa erstellt passende Vokabeln.',
          child: TopicDemo(examples: examples),
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
    required this.title,
    required this.detail,
    required this.child,
  });
  final String title, detail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppType.editorial(size: 24, color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          style: AppType.chrome(color: colors.textMuted, height: 1.35),
        ),
        const SizedBox(height: 16),
        // The demonstrations draw their own surfaces, like in the app.
        child,
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

/// Free against Premium as one card (user reference 21.11.2026): feature
/// names left, Free in ink, Premium in orange. Where three columns do not
/// fit without breaking inside a word, first the type steps down to 13,
/// then each feature's values stack below its name.
class PremiumComparison extends StatelessWidget {
  const PremiumComparison({super.key});

  /// Feature, Free, Premium. "✓" and "—" are drawn as icons. The line break
  /// only applies in the table; a no-break space keeps "im Monat" together.
  static const rows = [
    ('Stapel', 'Basis', 'Alle'),
    ('Stories', '1', 'Alle'),
    ('AI-Tutor', '3 Sätze\npro Tag', 'Unlimited'),
    ('Vokabelgenerierung', '1× im Monat', 'Unlimited'),
    ('Eigene Texte', '—', '✓'),
    ('Text-, Hör- & Grammatikübungen', '—', '✓'),
  ];

  /// Label column: right padding plus rounding slack.
  static const _labelGap = 9.0;

  /// Value columns: horizontal padding plus rounding slack.
  static const _valueGap = 9.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          // Text also inherits the theme's letter spacing.
          final inherited = DefaultTextStyle.of(context).style;
          // The widest unbreakable run (as the line breaker sees it) of
          // each column decides whether three columns fit.
          double widest(Iterable<String> texts, TextStyle style) {
            var widest = 0.0;
            for (final text in texts) {
              final painter = TextPainter(
                text: TextSpan(text: text, style: inherited.merge(style)),
                textDirection: TextDirection.ltr,
                textScaler: scaler,
              )..layout();
              widest = math.max(widest, painter.minIntrinsicWidth);
              painter.dispose();
            }
            return widest;
          }

          for (final size in const [15.0, 13.0]) {
            final label =
                widest([for (final row in rows) row.$1], _label(colors, size)) +
                _labelGap;
            final value =
                math.max(
                  widest([
                    'Free',
                    'Premium',
                    for (final row in rows) ...[row.$2, row.$3],
                  ], _premium(colors, size)),
                  24,
                ) +
                _valueGap;
            if (label + 2 * value <= constraints.maxWidth) {
              return _table(
                context,
                size,
                math.min(96, (constraints.maxWidth - label) / 2),
              );
            }
          }
          return _stacked(context);
        },
      ),
    );
  }

  TextStyle _label(AppPalette colors, [double size = 15]) =>
      AppType.chrome(size: size, color: colors.textPrimary, height: 1.35);

  TextStyle _free(AppPalette colors, [double size = 15]) => AppType.chrome(
    size: size,
    weight: FontWeight.w600,
    color: colors.textPrimary,
    height: 1.35,
  );

  TextStyle _premium(AppPalette colors, [double size = 15]) => AppType.chrome(
    size: size,
    weight: FontWeight.w700,
    color: colors.accentText,
    height: 1.35,
  );

  Widget _table(BuildContext context, double size, double valueWidth) {
    final colors = context.appColors;
    return Table(
      columnWidths: {
        0: const FlexColumnWidth(),
        1: FixedColumnWidth(valueWidth),
        2: FixedColumnWidth(valueWidth),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Funktionen',
                style: AppType.chrome(
                  size: size,
                  color: colors.textMuted,
                  height: 1.35,
                ),
              ),
            ),
            _cell(
              context,
              'Free',
              _free(colors, size).copyWith(fontWeight: FontWeight.w700),
              header: true,
            ),
            _cell(context, 'Premium', _premium(colors, size), header: true),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 11, 8, 11),
                child: Text(row.$1, style: _label(colors, size)),
              ),
              _cell(context, row.$2, _free(colors, size)),
              _cell(context, row.$3, _premium(colors, size)),
            ],
          ),
      ],
    );
  }

  Widget _stacked(BuildContext context) {
    final colors = context.appColors;
    Widget line(String plan, String value, TextStyle style) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              plan,
              style: AppType.chrome(color: colors.textMuted, height: 1.35),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: _value(context, value, style, TextAlign.end)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  row.$1,
                  style: _label(colors).copyWith(fontWeight: FontWeight.w700),
                ),
                line('Free', row.$2.replaceAll('\n', ' '), _free(colors)),
                line('Premium', row.$3, _premium(colors)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    String text,
    TextStyle style, {
    bool header = false,
  }) => Padding(
    padding: header
        ? const EdgeInsets.fromLTRB(4, 0, 4, 4)
        : const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
    child: _value(context, text, style, TextAlign.center),
  );

  Widget _value(
    BuildContext context,
    String text,
    TextStyle style,
    TextAlign align,
  ) => text == '✓' || text == '—'
      ? Semantics(
          label: text == '✓' ? 'Enthalten' : 'Nicht enthalten',
          child: ExcludeSemantics(
            child: Align(
              alignment: align == TextAlign.center
                  ? Alignment.center
                  : Alignment.centerRight,
              child: Icon(
                text == '✓' ? CupertinoIcons.checkmark : CupertinoIcons.minus,
                size: 20,
                color: text == '✓' ? style.color : context.appColors.textMuted,
              ),
            ),
          ),
        )
      : Text(text, textAlign: align, style: style);
}
