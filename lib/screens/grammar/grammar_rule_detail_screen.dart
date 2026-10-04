import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/services.dart';

import '../../models/grammar_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/emphasis_text.dart';

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
      value:
          (context.appColors.light
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: context.appColors.nightPage,
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
                              style: AppType.meta(
                                color: context.appColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              container: true,
                              header: true,
                              child: Text(
                                rule.title,
                                style: AppType.editorial(
                                  color: context.appColors.textPrimary,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              rule.summary,
                              style: AppType.editorial(
                                size: 17,
                                weight: FontWeight.w400,
                                color: context.appColors.textMuted,
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
          child: Text(
            section.heading,
            style: AppType.editorial(
              color: context.appColors.textPrimary,
              size: 22,
            ),
          ),
        ),
        for (final paragraph in section.paragraphs) ...[
          const SizedBox(height: 12),
          Semantics(
            container: true,
            child: Text.rich(emphasisSpan(paragraph, AppType.storyBody())),
          ),
        ],
        if (section.examples.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Beispiele',
            style: AppType.meta(color: context.appColors.textMuted),
          ),
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
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: context.appColors.hairline, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              emphasisSpan(
                example.english,
                AppType.editorial(
                  color: context.appColors.textPrimary,
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
                color: context.appColors.textMuted,
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
      color: context.appColors.textPrimary,
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
          color: context.appColors.raisedInk,
          border: Border.all(color: context.appColors.hairline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Typischer Fehler',
              style: AppType.chrome(
                color: context.appColors.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nicht',
              style: AppType.meta(color: context.appColors.textMuted),
            ),
            const SizedBox(height: 2),
            Semantics(
              label: 'Falsch: ${pitfall.wrong.replaceAll('*', '')}',
              excludeSemantics: true,
              child: Text(
                pitfall.wrong.replaceAll('*', ''),
                style: sentence.copyWith(
                  color: context.appColors.textMuted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: context.appColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sondern',
              style: AppType.meta(color: context.appColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text.rich(emphasisSpan(pitfall.right, sentence)),
          ],
        ),
      ),
    );
  }
}
