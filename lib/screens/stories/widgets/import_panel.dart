import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../domain/content_access_policy.dart';
import '../../../domain/preferences.dart';
import '../../../presentation/providers/content_access_provider.dart';
import '../../../presentation/providers/preferences_provider.dart';
import '../../onboarding/paywall_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/popover_content.dart';
import '../../../widgets/premium_content_gate.dart';

/// Popover content behind "Importieren": where a text can come from. Pasting
/// works on the device; files, YouTube transcripts and web pages need a file
/// picker or the import backend and are shown as "Bald" until then. Without
/// Premium every source carries a lock and opens the paywall.
class ImportPanel extends ConsumerStatefulWidget {
  const ImportPanel({super.key, required this.onImportText});

  /// Stores [text]; returns an error message for the learner, or null.
  /// Null callback: importing is unavailable here.
  final String? Function(String text)? onImportText;

  @override
  ConsumerState<ImportPanel> createState() => _ImportPanelState();
}

class _ImportPanelState extends ConsumerState<ImportPanel> {
  String? _message;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      setState(() => _message = 'Die Zwischenablage ist leer.');
      return;
    }
    final error = widget.onImportText!(text);
    if (error != null) {
      setState(() => _message = error);
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(true);
  }

  Future<void> _viewPremium() async {
    final preferences =
        ref.read(preferencesProvider).asData?.value ??
        const PracticePreferences();
    await Navigator.of(context).push<void>(
      PaywallScreen.route(
        plan: (interest: 'Eigene Texte', dailyGoal: preferences.dailyGoal),
        onContinue: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Without confirmed Premium every source is shown, marked and leads to
    // the paywall, so learners still see what is possible (31.10.2026).
    final locked =
        ref.watch(contentAccessProvider) != ContentAccessDecision.allowed;
    VoidCallback? tap(VoidCallback? available) =>
        locked ? _viewPremium : available;
    final options = [
      _Option(
        icon: CupertinoIcons.doc_on_clipboard,
        title: 'Text einfügen',
        detail: 'Aus der Zwischenablage',
        locked: locked,
        onTap: tap(widget.onImportText == null ? null : _paste),
      ),
      _Option(
        icon: CupertinoIcons.doc_text,
        title: 'Datei',
        detail: 'TXT, EPUB, PDF, SRT',
        locked: locked,
        onTap: tap(null),
      ),
      _Option(
        icon: CupertinoIcons.play_rectangle,
        title: 'YouTube',
        detail: 'Transkript per Link',
        locked: locked,
        onTap: tap(null),
      ),
      _Option(
        icon: CupertinoIcons.globe,
        title: 'Webseite',
        detail: 'Artikel per Link',
        locked: locked,
        onTap: tap(null),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 280 ? 1 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in options)
                  SizedBox(width: width, child: option),
              ],
            );
          },
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: PopoverText.small()),
          ),
        ],
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.detail,
    this.locked = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;

  /// Needs Premium: shown with a crown mark; [onTap] opens the paywall.
  final bool locked;

  /// Null: not available yet ("Bald").
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final available = onTap != null;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        pressedOpacity: 0.75,
        child: Semantics(
          label: locked
              ? '$title, $detail, mit Premium'
              : available
              ? '$title, $detail'
              : '$title, bald verfügbar',
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: available ? white : const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: available ? context.appColors.popover : white,
                    ),
                    const Spacer(),
                    if (locked)
                      const PremiumLockBadge(size: 24)
                    else if (!available)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Bald',
                          style: AppType.chrome(
                            size: 11,
                            weight: FontWeight.w800,
                            color: white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppType.chrome(
                    size: 15,
                    weight: FontWeight.w800,
                    color: available ? context.appColors.popover : white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  // Orange on white is 3.3:1 as well: bold, full strength.
                  style: PopoverText.caption().copyWith(
                    fontSize: 13,
                    color: available ? context.appColors.popover : white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
