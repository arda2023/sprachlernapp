import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/preferences.dart';
import '../../../domain/srs_state.dart';
import '../../../presentation/providers/database_providers.dart';
import '../../../theme/app_theme.dart';

const problemCategories = [
  'Die Qualität des Kontextsatzes ist schlecht.',
  'Es gibt ein Problem mit der Übersetzung eines Satzes.',
  'Die Grammatik ist falsch.',
  'Es gibt ein Problem mit der Übersetzung eines Wortes.',
  'Mein Synonym wurde nicht anerkannt.',
  'Übersetzungs-Tooltip ist falsch.',
  'Das Audio ist unterbrochen.',
  'Das Bild ist unpassend.',
  'Anderes.',
];

Future<void> sharePracticeText(BuildContext context, String text) async {
  final box = context.findRenderObject() as RenderBox?;
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Teilen nicht verfügbar. Der lokale Eintrag bleibt erhalten.',
          ),
        ),
      );
    }
  }
}

class LocalSubmissionSheet extends ConsumerStatefulWidget {
  const LocalSubmissionSheet({
    super.key,
    this.category,
    this.cardId,
    this.sentenceId,
    this.packVersion,
  });
  final String? category, cardId, sentenceId, packVersion;
  static Future<void> open(
    BuildContext context, {
    String? category,
    String? cardId,
    String? sentenceId,
    String? packVersion,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => LocalSubmissionSheet(
        category: category,
        cardId: cardId,
        sentenceId: sentenceId,
        packVersion: packVersion,
      ),
    ),
  );
  static Future<void> openSaved(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const _SavedSubmissions()));
  @override
  ConsumerState<LocalSubmissionSheet> createState() =>
      _LocalSubmissionSheetState();
}

class _LocalSubmissionSheetState extends ConsumerState<LocalSubmissionSheet> {
  final _text = TextEditingController();
  final _id = randomUuidV4();
  final _created = DateTime.now();
  int? _rating;
  bool _busy = false;
  String? _error;
  LocalSubmission? _saved;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _saved != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final submission = LocalSubmission(
      id: _id,
      createdAt: _created,
      text: _text.text,
      category: widget.category,
      rating: _rating,
      cardId: widget.cardId,
      sentenceId: widget.sentenceId,
      packVersion: widget.packVersion,
    );
    try {
      await (await ref.read(userRepositoryProvider.future))
          .saveSubmission(submission);
      if (mounted) {
        FocusScope.of(context).unfocus();
        setState(() => _saved = submission);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nicht gespeichert. Bitte erneut versuchen.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Schließen',
        icon: const Icon(Icons.close),
        onPressed: _busy ? null : () => Navigator.pop(context),
      ),
      title: Text(widget.category == null ? 'Feedback' : 'Problem melden'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.category != null)
          Text(
            widget.category!,
            style: AppType.chrome(
              color: context.appColors.textPrimary,
              size: 18,
            ),
          )
        else ...[
          Text(
            'Wie hilfreich ist Sprachapp für dich?',
            style: AppType.chrome(
              color: context.appColors.textPrimary,
              size: 20,
            ),
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i ${i == 1 ? 'Stern' : 'Sterne'}',
                  onPressed: _saved != null || _busy
                      ? null
                      : () => setState(() => _rating = i),
                  icon: Icon(
                    i <= (_rating ?? 0) ? Icons.star : Icons.star_border,
                    size: 36,
                    color: i <= (_rating ?? 0)
                        ? context.appColors.newsKicker
                        : context.appColors.textMuted,
                  ),
                ),
            ],
          ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text('Wenig hilfreich')),
              SizedBox(width: 16),
              Expanded(
                child: Text('Sehr hilfreich', textAlign: TextAlign.right),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _text,
          enabled: !_busy && _saved == null,
          maxLength: 2000,
          minLines: 6,
          maxLines: 14,
          decoration: InputDecoration(
            labelText: 'Beschreibung (optional)',
            alignLabelWithHint: true,
            hintText: widget.category == null ? 'Dein Feedback …' : 'Beschreibe das Problem oder nenne das nicht erkannte Synonym.',
            filled: true,
            fillColor: context.appColors.raisedInk,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(_error!, style: TextStyle(color: context.appColors.error)),
        if (_saved == null)
          FilledButton(
            onPressed: _busy || (widget.category == null && _rating == null)
                ? null
                : _save,
            child: Text(_busy ? 'Wird gespeichert …' : 'Lokal speichern'),
          )
        else ...[
          const Text('Lokal gespeichert. Es wurde nichts versendet.'),
          TextButton.icon(
            onPressed: () => sharePracticeText(context, _saved!.exportText),
            icon: const Icon(Icons.ios_share),
            label: const Text('Teilen'),
          ),
        ],
      ],
    ),
  );
}

final _submissionsProvider = FutureProvider.autoDispose(
  (ref) async => (await ref.watch(userRepositoryProvider.future)).submissions(),
);

class _SavedSubmissions extends ConsumerWidget {
  const _SavedSubmissions();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Lokale Einträge')),
    body: ref
        .watch(_submissionsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(_submissionsProvider),
              child: const Text('Erneut laden'),
            ),
          ),
          data: (entries) => entries.isEmpty
              ? const Center(child: Text('Noch keine lokalen Einträge.'))
              : ListView(
                  children: [
                    for (final e in entries)
                      ListTile(
                        title: Text(e.category ?? 'Feedback · ${e.rating}/5'),
                        subtitle: Text(
                          e.text.isEmpty ? 'Ohne Beschreibung' : e.text,
                        ),
                        trailing: const Icon(Icons.ios_share),
                        onTap: () => sharePracticeText(context, e.exportText),
                      ),
                  ],
                ),
        ),
  );
}
