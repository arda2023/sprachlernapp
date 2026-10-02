import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;

import '../../models/grammar_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/chevron_row.dart';
import '../../widgets/segmented_tabs.dart';
import 'grammar_rule_detail_screen.dart';

/// Grammatikregeln: a level filter on top, then one row per rule.
class GrammarRulesScreen extends StatefulWidget {
  const GrammarRulesScreen({super.key, required this.rules});

  final List<GrammarRule> rules;

  static Future<void> open(BuildContext context, List<GrammarRule> rules) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => GrammarRulesScreen(rules: rules),
        ),
      );

  @override
  State<GrammarRulesScreen> createState() => _GrammarRulesScreenState();
}

class _GrammarRulesScreenState extends State<GrammarRulesScreen> {
  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  GrammarLevel _level = GrammarLevel.beginner;

  @override
  Widget build(BuildContext context) {
    final rules = [
      for (final rule in widget.rules)
        if (rule.level == _level) rule,
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackBar(onBack: () => Navigator.of(context).maybePop()),
            const SizedBox(height: 8),
            Padding(
              padding: _gutter,
              child: Semantics(
                header: true,
                child: Text(
                  'Grammatikregeln',
                  style: AppType.editorial(size: 32),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: _gutter,
              child: Text(
                '${widget.rules.length} Regeln · erklärt auf Deutsch',
                style: AppType.meta(),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: _gutter,
              child: SegmentedTabs(
                values: GrammarLevel.values,
                labelOf: (level) => level.label,
                selected: _level,
                onChanged: (level) => setState(() => _level = level),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                key: ValueKey(_level),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  for (final rule in rules)
                    ChevronRow(
                      title: rule.title,
                      summary: rule.summary,
                      onTap: () => GrammarRuleDetailScreen.open(context, rule),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
