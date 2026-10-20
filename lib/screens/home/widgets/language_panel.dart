import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/language_selection_provider.dart';

import '../../../theme/app_theme.dart';

/// Language picker using the same validated transition as Settings.
class LanguagePanel extends ConsumerStatefulWidget {
  const LanguagePanel({super.key, this.current = 'Englisch'});

  static const languages = [
    ('🇬🇧', 'Englisch'),
    ('🇧🇷', 'Portugiesisch (Brasilien)'),
  ];

  final String current;

  @override
  ConsumerState<LanguagePanel> createState() => _LanguagePanelState();
}

class _LanguagePanelState extends ConsumerState<LanguagePanel> {
  static const _white = Color(0xFFFFFFFF);
  static const _itemExtent = 44.0;

  late int _index = LanguagePanel.languages
      .indexWhere((l) => l.$2 == widget.current)
      .clamp(0, LanguagePanel.languages.length - 1);
  late final _wheel = FixedExtentScrollController(initialItem: _index);
  String? _note;

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final lang = _index == 0 ? 'en' : 'pt-BR';
    final controller = ref.read(languageSelectionProvider.notifier);
    // Close the popup before the app rebuilds its language scope.
    Navigator.of(context).pop();
    await controller.selectLanguage(lang);
  }

  @override
  Widget build(BuildContext context) {
    final (_, chosen) = LanguagePanel.languages[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Sprache wählen',
            style: AppType.chrome(
              size: 20,
              weight: FontWeight.w800,
              color: _white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _itemExtent * 5,
          child: CupertinoPicker(
            scrollController: _wheel,
            itemExtent: _itemExtent,
            magnification: 1.12,
            useMagnifier: true,
            squeeze: 1.1,
            selectionOverlay: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSelectedItemChanged: (i) => setState(() {
              _index = i;
              _note = null;
            }),
            children: [
              for (final (flag, name) in LanguagePanel.languages)
                Center(
                  child: Text(
                    '$flag  $name',
                    style: AppType.chrome(
                      size: 20,
                      weight: FontWeight.w700,
                      color: _white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_note != null) ...[
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: Text(
              _note!,
              textAlign: TextAlign.center,
              style: AppType.chrome(size: 14, color: _white, height: 1.35),
            ),
          ),
        ],
        const SizedBox(height: 14),
        MergeSemantics(
          child: CupertinoButton(
            onPressed: _choose,
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 50),
            child: Semantics(
              label: '$chosen auswählen',
              excludeSemantics: true,
              child: Container(
                constraints: const BoxConstraints(minHeight: 50),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Auswählen',
                  style: AppType.chrome(
                    size: 16,
                    weight: FontWeight.w800,
                    color: context.appColors.popover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
