import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/language_profile.dart';
import '../../../presentation/providers/language_selection_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/popover_content.dart';

/// Language picker using the same validated transition as Settings.
class LanguagePanel extends ConsumerStatefulWidget {
  const LanguagePanel({super.key, this.current = 'Englisch'});

  /// Every selectable language ([ContentLanguageProfile.selectable]).
  static const languages = ContentLanguageProfile.selectable;

  /// Display name of the current language.
  final String current;

  @override
  ConsumerState<LanguagePanel> createState() => _LanguagePanelState();
}

class _LanguagePanelState extends ConsumerState<LanguagePanel> {
  static const _white = Color(0xFFFFFFFF);
  static const _itemExtent = 44.0;

  late int _index = LanguagePanel.languages
      .indexWhere((l) => l.displayName == widget.current)
      .clamp(0, LanguagePanel.languages.length - 1);
  late final _wheel = FixedExtentScrollController(initialItem: _index);
  String? _note;

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final lang = LanguagePanel.languages[_index].lang;
    final controller = ref.read(languageSelectionProvider.notifier);
    // Close the popup before the app rebuilds its language scope.
    Navigator.of(context).pop();
    await controller.selectLanguage(lang);
  }

  @override
  Widget build(BuildContext context) {
    final chosen = LanguagePanel.languages[_index].displayName;
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
              for (final language in LanguagePanel.languages)
                Center(
                  child: Text(
                    '${language.flag}  ${language.displayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              style: PopoverText.small(),
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
