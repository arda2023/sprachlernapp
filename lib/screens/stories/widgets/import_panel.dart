import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

/// Popover content behind "Importieren": where a text can come from. Pasting
/// works on the device; files, YouTube transcripts and web pages need a file
/// picker or the import backend and are shown as "Bald" until then.
class ImportPanel extends StatefulWidget {
  const ImportPanel({super.key, required this.onImportText});

  /// Stores [text]; returns an error message for the learner, or null.
  /// Null callback: importing is unavailable here.
  final String? Function(String text)? onImportText;

  @override
  State<ImportPanel> createState() => _ImportPanelState();
}

class _ImportPanelState extends State<ImportPanel> {
  static const _white = Color(0xFFFFFFFF);
  String? _message;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      setState(
        () => _message =
            'Die Zwischenablage ist leer. Kopiere zuerst einen Text, '
            'zum Beispiel ein YouTube-Transkript.',
      );
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

  @override
  Widget build(BuildContext context) {
    final options = [
      _Option(
        icon: CupertinoIcons.doc_on_clipboard,
        title: 'Text einfügen',
        detail: 'Aus der Zwischenablage',
        onTap: widget.onImportText == null ? null : _paste,
      ),
      const _Option(
        icon: CupertinoIcons.doc_text,
        title: 'Datei',
        detail: 'TXT, EPUB, PDF, SRT',
      ),
      const _Option(
        icon: CupertinoIcons.play_rectangle,
        title: 'YouTube',
        detail: 'Transkript per Link',
      ),
      const _Option(
        icon: CupertinoIcons.globe,
        title: 'Webseite',
        detail: 'Artikel per Link',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Eigene Texte importieren',
            style: AppType.chrome(
              size: 20,
              weight: FontWeight.w800,
              color: _white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lies Transkripte, E-Books oder Artikel mit Wort-Übersetzung.',
          style: AppType.chrome(
            size: 14,
            color: _white.withValues(alpha: 0.9),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
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
            child: Text(
              _message!,
              style: AppType.chrome(size: 14, color: _white, height: 1.35),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Importierte Texte bleiben auf diesem Gerät. Höchstens 5.000 Wörter.',
          style: AppType.chrome(
            size: 12,
            color: _white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.detail,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;

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
          label: available ? '$title, $detail' : '$title, bald verfügbar',
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
                    if (!available)
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
                  style: AppType.chrome(
                    size: 12,
                    color: available
                        ? context.appColors.popover.withValues(alpha: 0.8)
                        : white.withValues(alpha: 0.8),
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
