import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/runtime_translation_client.dart';
import '../presentation/providers/runtime_translation_provider.dart';
import '../theme/app_theme.dart';
import 'anchored_popover.dart';
import 'popover_content.dart';

/// Missing translations only. No network until the explicit button is tapped.
/// Shown as the orange popover pointing at the tapped word or sentence, like
/// a stored translation.
class RuntimeTranslationSheet extends ConsumerStatefulWidget {
  const RuntimeTranslationSheet({
    super.key,
    required this.lang,
    required this.text,
    this.form,
    this.displayText,
  });
  final String lang, text;
  final String? form, displayText;
  static Future<void> show(
    BuildContext context, {
    required Rect anchor,
    required String lang,
    required String text,
    String? form,
    String? displayText,
  }) => showAnchoredPopoverAt<void>(
    context: context,
    anchor: anchor,
    color: context.appColors.popover,
    builder: (_) => RuntimeTranslationSheet(
      lang: lang,
      text: text,
      form: form,
      displayText: displayText,
    ),
  );
  @override
  ConsumerState<RuntimeTranslationSheet> createState() =>
      _RuntimeTranslationSheetState();
}

class _RuntimeTranslationSheetState
    extends ConsumerState<RuntimeTranslationSheet> {
  bool started = false, loading = false;
  RuntimeTranslation? result;
  String? error;
  Future<void> request() async {
    if (started) return;
    setState(() {
      started = true;
      loading = true;
    });
    try {
      final value = await ref
          .read(runtimeTranslationProvider)
          .translate(lang: widget.lang, text: widget.text, form: widget.form);
      if (mounted) setState(() => result = value);
    } on TranslationFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Übersetzung derzeit nicht verfügbar.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = popoverInk.withValues(alpha: 0.85);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.displayText ?? widget.form ?? widget.text,
          style: AppType.editorial(
            color: popoverInk,
            size: widget.form != null ? 26 : 19,
            weight: FontWeight.w600,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
        if (widget.form != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.text,
            style: AppType.editorial(
              color: muted,
              size: 17,
              weight: FontWeight.w400,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
        ],
        const SizedBox(height: 14),
        const PopoverDivider(),
        const SizedBox(height: 12),
        if (!started) ...[
          Text(
            'Keine gespeicherte Übersetzung. Für eine KI-Übersetzung wird dieser Satz an Anthropic übermittelt. Keine ausschließliche EU-Verarbeitung.',
            style: AppType.chrome(size: 14, color: muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          PopoverPillButton(
            label: 'Mit KI übersetzen',
            icon: CupertinoIcons.sparkles,
            onPressed: request,
          ),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: CupertinoActivityIndicator(color: popoverInk),
          ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              semanticsLabel: error,
              style: AppType.chrome(color: popoverInk, height: 1.4),
            ),
          ),
        if (result case final value?) ...[
          Text(
            'Deutsch',
            style: AppType.meta(color: muted),
          ),
          const SizedBox(height: 2),
          Text(
            value.text,
            style: AppType.editorial(
              color: popoverInk,
              size: 20,
              weight: FontWeight.w400,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'KI · ${value.model}',
            style: AppType.meta(color: muted),
          ),
          SelectableText(
            'Anfrage: ${value.requestId}',
            style: AppType.chrome(
              size: 12,
              color: popoverInk.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
