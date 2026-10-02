import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;

import '../../models/grammar_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
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
              child: _LevelControl(
                level: _level,
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
                    _RuleRow(
                      rule: rule,
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

/// Neutral segmented control: Raised Ink groove, Hairline thumb, labels in
/// `textMuted` and `textPrimary` when selected. Text scaling is clamped like
/// the tab labels, since three segments share one row.
class _LevelControl extends StatelessWidget {
  const _LevelControl({required this.level, required this.onChanged});

  final GrammarLevel level;
  final ValueChanged<GrammarLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: CupertinoSlidingSegmentedControl<GrammarLevel>(
        groupValue: level,
        backgroundColor: AppColors.raisedInk,
        thumbColor: AppColors.hairline,
        padding: const EdgeInsets.all(2),
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
        children: {
          for (final value in GrammarLevel.values)
            value: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: Text(
                  value.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppType.chrome(
                    size: 13,
                    weight: FontWeight.w600,
                    color: value == level
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule, required this.onTap});

  final GrammarRule rule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 56),
        child: Semantics(
          label: '${rule.title}, ${rule.summary}',
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.title,
                        style: AppType.chrome(
                          size: 17,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(rule.summary, style: AppType.meta()),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
