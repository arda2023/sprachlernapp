import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/services.dart';

import '../../models/grammar_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';

/// One grammar rule, set like a reader page on the Night Page: German prose
/// in the editorial serif, English forms in italic w600 (the citation
/// convention of print grammars, no ink), examples with their translation,
/// and the typical mistake of German speakers.
class GrammarRuleDetailScreen extends StatelessWidget {
  const GrammarRuleDetailScreen({super.key, required this.rule});

  final GrammarRule rule;

  static Future<void> open(BuildContext context, GrammarRule rule) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => GrammarRuleDetailScreen(rule: rule),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.nightPage,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BackBar(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${rule.level.label} · ${rule.minutes} Min',
                              style: AppType.meta(),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              container: true,
                              header: true,
                              child: Text(
                                rule.title,
                                style: AppType.editorial(size: 32),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              rule.summary,
                              style: AppType.editorial(
                                size: 17,
                                weight: FontWeight.w400,
                                color: AppColors.textMuted,
                                height: 1.45,
                                letterSpacing: 0,
                              ),
                            ),
                            for (final section in rule.sections) ...[
                              const SizedBox(height: 36),
                              _Section(section: section),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [source] with its `*…*` forms in italic w600, on [style].
TextSpan grammarSpan(String source, TextStyle style) => TextSpan(
  style: style,
  children: [
    for (final piece in parseEmphasis(source))
      TextSpan(text: piece.text, style: piece.emphasis ? _emphasis : null),
  ],
);

const _emphasis = TextStyle(
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
);

class _Section extends StatelessWidget {
  const _Section({required this.section});

  final GrammarSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text(section.heading, style: AppType.editorial(size: 22)),
        ),
        for (final paragraph in section.paragraphs) ...[
          const SizedBox(height: 12),
          Semantics(
            container: true,
            child: Text.rich(grammarSpan(paragraph, AppType.storyBody())),
          ),
        ],
        if (section.examples.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Beispiele', style: AppType.meta()),
          for (final example in section.examples) ...[
            const SizedBox(height: 12),
            _Example(example: example),
          ],
        ],
        if (section.pitfall case final pitfall?) ...[
          const SizedBox(height: 24),
          _Pitfall(pitfall: pitfall),
        ],
      ],
    );
  }
}

/// English sentence over its German translation, hung on a Hairline rule.
class _Example extends StatelessWidget {
  const _Example({required this.example});

  final GrammarExample example;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.only(left: 14),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.hairline, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              grammarSpan(
                example.english,
                AppType.editorial(
                  size: 19,
                  weight: FontWeight.w400,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              example.german,
              style: AppType.editorial(
                size: 16,
                weight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.45,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The typical mistake: "Nicht" (struck through, muted) and "Sondern". The
/// labels carry the meaning; no Feedback color outside exercises.
class _Pitfall extends StatelessWidget {
  const _Pitfall({required this.pitfall});

  final GrammarPitfall pitfall;

  @override
  Widget build(BuildContext context) {
    final sentence = AppType.editorial(
      size: 17,
      weight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
    );
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.raisedInk,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Typischer Fehler',
              style: AppType.chrome(weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text('Nicht', style: AppType.meta()),
            const SizedBox(height: 2),
            Semantics(
              label: 'Falsch: ${pitfall.wrong.replaceAll('*', '')}',
              excludeSemantics: true,
              child: Text(
                pitfall.wrong.replaceAll('*', ''),
                style: sentence.copyWith(
                  color: AppColors.textMuted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Sondern', style: AppType.meta()),
            const SizedBox(height: 2),
            Text.rich(grammarSpan(pitfall.right, sentence)),
          ],
        ),
      ),
    );
  }
}
