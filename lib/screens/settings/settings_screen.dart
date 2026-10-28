import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Colors,
        LinearProgressIndicator,
        Material,
        MaterialPageRoute,
        Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/language_profile.dart';
import '../../domain/preferences.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/providers/language_selection_provider.dart';
import '../../presentation/providers/preferences_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anchored_popover.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/personal_learning_button.dart';
import '../../widgets/translation_cache_delete_tile.dart';
import '../../widgets/word_cloud_consent.dart';
import '../decks/widgets/local_submission_sheet.dart';
import '../home/widgets/goal_panel.dart';
import '../previews/screen_previews_screen.dart';
import 'content_updates_screen.dart';

/// Settings as grouped, rounded sections on the page tone (Redesign
/// 28.10.2026, references: CapWords, Uxcel Go, ChatGPT and Claude settings
/// on Mobbin): learning language, appearance with live previews, practice
/// switches, features that are not available yet, content and help.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;
  String? _error;

  /// The large title scrolled away: the bar shows a small one (iOS large
  /// title behaviour).
  final _titleGone = ValueNotifier(false);
  late final ScrollController _scroll = ScrollController()
    ..addListener(() => _titleGone.value = _scroll.offset > 44);

  /// The daily goal's popover points at its value pill, which turns
  /// orange meanwhile.
  final _goalKey = GlobalKey();
  bool _goalOpen = false;

  @override
  void dispose() {
    _scroll.dispose();
    _titleGone.dispose();
    super.dispose();
  }

  Future<void> _editGoal(PracticePreferences p) async {
    final anchor = _goalKey.currentContext;
    if (anchor == null || _goalOpen) return;
    HapticFeedback.selectionClick();
    setState(() => _goalOpen = true);
    await showAnchoredPopover<void>(
      anchorContext: anchor,
      color: context.appColors.popover,
      builder: (_) => GoalPanel(
        onSetGoal: (target) => _save(
          (ref.read(preferencesProvider).value ?? p).copyWith(dailyGoal: target),
        ),
      ),
    );
    if (mounted) setState(() => _goalOpen = false);
  }
  Future<void> _save(PracticePreferences value) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(preferencesProvider.notifier).save(value);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nicht gespeichert. Bitte erneut versuchen.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _push(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preferencesProvider);
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.nightPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                BackBar(onBack: () => Navigator.of(context).maybePop()),
                IgnorePointer(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _titleGone,
                    builder: (context, gone, _) => AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: gone ? 1 : 0,
                      child: ExcludeSemantics(
                        child: Text(
                          'Einstellungen',
                          style: AppType.chrome(
                            size: 17,
                            weight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: state.when(
                skipLoadingOnReload: false,
                skipLoadingOnRefresh: false,
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (_, _) => Center(
                  child: CupertinoButton(
                    onPressed: () => ref.invalidate(preferencesProvider),
                    child: const Text('Einstellungen erneut laden'),
                  ),
                ),
                data: _content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(PracticePreferences p) {
    final colors = context.appColors;
    final language = ref.watch(selectedContentLanguageProvider);
    final selection = ref.watch(languageSelectionProvider);
    final selectedProfile = ContentLanguageProfile.forLanguage(
      language.asData?.value ?? 'en',
    );
    final version = ref.watch(appInfoProvider).asData?.value;
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Einstellungen',
            style: AppType.editorial(color: colors.textPrimary, size: 32),
          ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Lernsprache',
          footer: 'Die Oberfläche bleibt Deutsch.',
          children: [
            for (final profile in ContentLanguageProfile.selectable)
              _LanguageRow(
                profile: profile,
                selected:
                    !language.isLoading &&
                    language.asData?.value == profile.lang,
                status: ref
                    .watch(languageInstallationProvider(profile.lang))
                    .when(
                      data: (status) => status,
                      loading: () => 'Installation prüfen …',
                      error: (_, _) => 'Installation nicht lesbar',
                    ),
                onTap: selection.switching || _saving || language.isLoading
                    ? null
                    : () => ref
                          .read(languageSelectionProvider.notifier)
                          .selectLanguage(profile.lang),
              ),
          ],
        ),
        if (selection.switching)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (selection.message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                selection.message!,
                style: AppType.chrome(size: 14, color: colors.textMuted),
              ),
            ),
          ),
        _Section(
          title: 'Darstellung',
          children: [
            _MotifPicker(
              value: p.motif,
              onChanged: _saving ? null : (m) => _save(p.copyWith(motif: m)),
            ),
          ],
        ),
        _Section(
          title: 'Üben',
          children: [
            _Row(
              icon: CupertinoIcons.scope,
              title: 'Tagesziel',
              value: '${p.dailyGoal} Wörter',
              valueKey: _goalKey,
              open: _goalOpen,
              onTap: () => _editGoal(p),
            ),
            if (selectedProfile?.requiresDiacritics ?? false)
              _Row(
                icon: CupertinoIcons.textformat_abc,
                title: selectedProfile!.lang == 'pt-BR'
                    ? 'Akzente sind für Portugiesisch erforderlich'
                    : 'Akzente sind für ${selectedProfile.displayName} erforderlich',
                subtitle:
                    'Sprachspezifische Buchstaben und Akzente gehören zur richtigen Antwort. Die englische Einstellung bleibt erhalten.',
              )
            else
              _SwitchRow(
                icon: CupertinoIcons.textformat_abc,
                title: 'Diakritische Zeichen einbeziehen',
                subtitle:
                    'Akzente sind bei der Antwort erforderlich. Standardmäßig eingeschaltet.',
                value: p.includeDiacritics,
                onChanged: _saving
                    ? null
                    : (v) => _save(p.copyWith(includeDiacritics: v)),
              ),
            _SwitchRow(
              icon: CupertinoIcons.forward_end,
              title: 'Automatisch nächste Karte anzeigen',
              subtitle:
                  'Nach dem Speichern und einer kurzen Rückmeldung weitergehen.',
              value: p.autoNext,
              onChanged: _saving
                  ? null
                  : (v) => _save(p.copyWith(autoNext: v)),
            ),
            _SwitchRow(
              icon: CupertinoIcons.table,
              title: 'Grammatiktabellen anzeigen',
              subtitle:
                  'Vorhandene Forminformationen nach der richtigen Antwort öffnen.',
              value: p.showGrammar,
              onChanged: _saving
                  ? null
                  : (v) => _save(p.copyWith(showGrammar: v)),
            ),
          ],
        ),
        _Section(
          title: 'Audio und Erinnerungen',
          footer:
              'Noch nicht verfügbar – diese Funktionen kommen mit einem späteren Update.',
          children: [
            for (final (icon, title, detail) in const [
              (
                CupertinoIcons.bell,
                'Lern-Benachrichtigungen',
                'Lernerinnerungen',
              ),
              (
                CupertinoIcons.speaker_slash,
                'Ton aus',
                'Automatische Audioinhalte stummschalten; manuelles Abspielen bleibt möglich.',
              ),
              (
                CupertinoIcons.speedometer,
                'Audiogeschwindigkeit',
                'Geschwindigkeit der Audiowiedergabe',
              ),
              (
                CupertinoIcons.mic,
                'Spracheingabe aktivieren',
                'Mit geräteinterner Spracherkennung antworten.',
              ),
            ])
              _Row(
                icon: icon,
                title: title,
                subtitle: detail,
                semanticsHint: 'Noch nicht verfügbar',
                enabled: false,
                trailing: const _SoonChip(),
              ),
          ],
        ),
        const _Section(
          title: 'Daten und Datenschutz',
          children: [
            // These tiles carry no inset of their own.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: WordCloudConsentTile(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: PersonalLearningConsentTile(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TranslationCacheDeleteTile(),
            ),
          ],
        ),
        _Section(
          title: 'Inhalte und Hilfe',
          children: [
            _Row(
              icon: CupertinoIcons.arrow_down_circle,
              title: 'Inhaltsupdates',
              subtitle: 'Private Versionen und Anmeldung',
              onTap: () => _push(const ContentUpdatesScreen()),
            ),
            _Row(
              icon: CupertinoIcons.chat_bubble_text,
              title: 'Lokale Berichte und Feedback',
              subtitle: 'Gespeicherte Einträge ansehen und teilen.',
              onTap: () => LocalSubmissionSheet.openSaved(context),
            ),
            _Row(
              icon: CupertinoIcons.play_rectangle,
              title: 'Bildschirm-Vorschauen',
              subtitle: 'Onboarding, Abschluss und Wochenstern ausprobieren',
              onTap: () => _push(const ScreenPreviewsScreen()),
            ),
          ],
        ),
        if (_saving)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Text(_error!, style: AppType.chrome(color: colors.error)),
          ),
        if (version != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Sprachapp · Version $version',
              textAlign: TextAlign.center,
              style: AppType.meta(color: colors.textMuted),
            ),
          ),
      ],
    );
  }
}

/// A heading, one rounded group on `raisedInk` and an optional footnote.
/// Rows inside are separated by an inset hairline, never framed.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.footer});

  final String title;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppType.chrome(
                  size: 14,
                  weight: FontWeight.w700,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            // A Material, so embedded ListTiles (consent rows) paint here.
            child: Material(
              color: colors.raisedInk,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Container(
                          height: 1,
                          color: colors.hairline.withValues(alpha: 0.6),
                        ),
                      ),
                    child,
                  ],
                ],
              ),
            ),
          ),
          if (footer case final footer?)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                footer,
                style: AppType.chrome(
                  size: 13,
                  color: colors.textMuted,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Icon, title, optional subtitle and value; a chevron when it navigates.
/// [open]: its popover shows, so the row's value turns popover orange.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.open = false,
    this.valueKey,
    this.semanticsHint,
  });

  final IconData icon;
  final String title;
  final String? subtitle, value;

  /// Read aloud after the row (e.g. "Noch nicht verfügbar").
  final String? semanticsHint;

  /// Lets a popover point at the value pill.
  final Key? valueKey;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled, open;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ink = enabled ? colors.textPrimary : colors.textMuted;
    // Large text: the value moves under the title instead of squeezing it.
    final stacked = MediaQuery.textScalerOf(context).scale(16) > 16 * 1.35;
    final valuePill = value == null
        ? null
        : AnimatedContainer(
            key: valueKey,
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            // Pulls the pill's inset back so a stacked value keeps the
            // title's edge.
            transform: Matrix4.translationValues(stacked ? -10 : 0, 0, 0),
            decoration: BoxDecoration(
              color: open ? colors.popover : colors.popover.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              value!,
              style: AppType.chrome(
                size: 15,
                weight: FontWeight.w600,
                color: open ? const Color(0xFFFFFFFF) : colors.textMuted,
                tabular: true,
              ),
            ),
          );
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(
              icon,
              size: 22,
              color: enabled ? colors.textPrimary : colors.iconOff,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppType.chrome(
                    size: 16,
                    weight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                if (subtitle case final subtitle?) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppType.chrome(
                      size: 13,
                      color: colors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
                if (stacked && valuePill != null) valuePill,
              ],
            ),
          ),
          if (!stacked && valuePill != null) ...[
            const SizedBox(width: 8),
            valuePill,
          ],
          if (trailing case final trailing?) ...[
            const SizedBox(width: 8),
            trailing,
          ] else if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: colors.textMuted,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return MergeSemantics(
        child: Semantics(enabled: enabled, hint: semanticsHint, child: row),
      );
    }
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 56),
        pressedOpacity: 0.6,
        child: Semantics(button: true, child: row),
      ),
    );
  }
}

/// A row with an orange switch; tapping anywhere on the row toggles it.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final change = onChanged;
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: change == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                change(!value);
              },
        child: _Row(
          icon: icon,
          title: title,
          subtitle: subtitle,
          trailing: CupertinoSwitch(
            value: value,
            onChanged: change,
            activeTrackColor: colors.active,
            inactiveTrackColor: colors.hairline,
            thumbColor: const Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}

/// Flag, language and installation state; the current one carries an
/// orange check.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.profile,
    required this.selected,
    required this.status,
    required this.onTap,
  });

  final ContentLanguageProfile profile;
  final bool selected;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 60),
        pressedOpacity: 0.6,
        child: Semantics(
          button: true,
          selected: selected,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    profile.flag,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: AppType.chrome(
                          size: 16,
                          weight: selected ? FontWeight.w700 : FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        style: AppType.chrome(size: 13, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: selected ? 1 : 0,
                  child: Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 22,
                    color: colors.active,
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

/// "Bald" on features that are not implemented yet.
class _SoonChip extends StatelessWidget {
  const _SoonChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.appColors.hairline,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      'Bald',
      style: AppType.chrome(
        size: 12,
        weight: FontWeight.w700,
        color: context.appColors.textMuted,
      ),
    ),
  );
}

/// Automatisch · Hell · Dunkel as three small previews of the app in that
/// motif; the chosen one is ringed in orange. Narrow screens and large text
/// get one row per motif.
class _MotifPicker extends StatelessWidget {
  const _MotifPicker({required this.value, required this.onChanged});

  final AppMotif value;
  final ValueChanged<AppMotif>? onChanged;

  static String label(AppMotif m) => switch (m) {
    AppMotif.automatic => 'Automatisch',
    AppMotif.light => 'Hell',
    AppMotif.dark => 'Dunkel',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(15) / 15;
        final columns = constraints.maxWidth >= 300 && scale <= 1.35;
        final tiles = [
          for (final m in AppMotif.values)
            _MotifTile(
              motif: m,
              label: label(m),
              selected: m == value,
              wide: !columns,
              onTap: onChanged == null
                  ? null
                  : () {
                      if (m == value) return;
                      HapticFeedback.selectionClick();
                      onChanged!(m);
                    },
            ),
        ];
        return Padding(
          padding: const EdgeInsets.all(12),
          child: columns
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, tile) in tiles.indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: tile),
                    ],
                  ],
                )
              : Column(children: tiles),
        );
      },
    );
  }
}

class _MotifTile extends StatelessWidget {
  const _MotifTile({
    required this.motif,
    required this.label,
    required this.selected,
    required this.wide,
    required this.onTap,
  });

  final AppMotif motif;
  final String label;
  final bool selected, wide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final preview = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // State ring only: the chosen motif.
        border: Border.all(
          color: selected ? colors.active : Colors.transparent,
          width: 2,
        ),

        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: wide ? 40 : 64,
        width: wide ? 56 : double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
        // The preview's own edge, so a page-coloured preview never melts
        // into the card behind it.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: colors.hairline),
        ),
        child: CustomPaint(painter: _MotifPreviewPainter(motif)),
      ),
    );
    final text = Text(
      label,
      textAlign: wide ? TextAlign.start : TextAlign.center,
      style: AppType.chrome(
        size: 14,
        weight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? colors.textPrimary : colors.textMuted,
      ),
    );
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        pressedOpacity: 0.7,
        child: Semantics(
          label: 'Motiv $label',
          selected: selected,
          button: true,
          excludeSemantics: true,
          child: wide
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      preview,
                      const SizedBox(width: 12),
                      Expanded(child: text),
                      if (selected)
                        Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 20,
                          color: colors.active,
                        ),
                    ],
                  ),
                )
              : Column(
                  children: [preview, const SizedBox(height: 8), text],
                ),
        ),
      ),
    );
  }
}

/// A tiny Home in the motif's colours: page, a raised card with two lines,
/// an orange progress bar. "Automatisch" is split diagonally.
class _MotifPreviewPainter extends CustomPainter {
  const _MotifPreviewPainter(this.motif);
  final AppMotif motif;

  void _paintMotif(Canvas canvas, Size size, Brightness brightness) {
    final palette = AppPalette(brightness);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.nightPage);
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.2,
        size.width * 0.76,
        size.height * 0.6,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(card, Paint()..color = palette.raisedInk);
    final line = Paint()
      ..color = palette.textMuted.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final left = card.left + 7;
    canvas.drawLine(
      Offset(left, card.top + card.height * 0.32),
      Offset(card.right - card.width * 0.3, card.top + card.height * 0.32),
      line,
    );
    canvas.drawLine(
      Offset(left, card.top + card.height * 0.55),
      Offset(card.right - card.width * 0.5, card.top + card.height * 0.55),
      line,
    );
    canvas.drawLine(
      Offset(left, card.top + card.height * 0.78),
      Offset(card.right - 7, card.top + card.height * 0.78),
      line..color = palette.hairline,
    );
    canvas.drawLine(
      Offset(left, card.top + card.height * 0.78),
      Offset(left + (card.width - 14) * 0.55, card.top + card.height * 0.78),
      line..color = AppColors.active,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (motif) {
      case AppMotif.light:
        _paintMotif(canvas, size, Brightness.light);
      case AppMotif.dark:
        _paintMotif(canvas, size, Brightness.dark);
      case AppMotif.automatic:
        _paintMotif(canvas, size, Brightness.light);
        canvas.save();
        canvas.clipPath(
          Path()
            ..moveTo(size.width, 0)
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close(),
        );
        _paintMotif(canvas, size, Brightness.dark);
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MotifPreviewPainter old) => old.motif != motif;
}
