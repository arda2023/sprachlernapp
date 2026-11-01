import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Scaffold, SelectionArea;

import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import 'legal_document.dart';
import 'legal_release_gate.dart';

/// Offline-readable legal information. The same words are also kept as
/// standalone HTML under `assets/legal/` for a future static legal site.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.document,
    @visibleForTesting this.legalDocumentsApprovedOverride,
  });

  final LegalDocument document;

  /// Lets widget tests cover both build-flag states without changing the flag.
  @visibleForTesting
  final bool? legalDocumentsApprovedOverride;

  static Route<void> route({required LegalDocument document}) =>
      CupertinoPageRoute<void>(
        builder: (_) => LegalDocumentScreen(document: document),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final content = legalDocuments[document]!;
    final documentsApproved =
        legalDocumentsApprovedOverride ?? legalDocumentsApproved;
    final sections = documentsApproved
        ? content.sections.where((section) => !section.draftOnly)
        : content.sections;
    return Scaffold(
      backgroundColor: colors.nightPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackBar(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Material(
                color: colors.nightPage,
                child: SelectionArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    children: [
                      Text(
                        content.title,
                        style: AppType.chrome(
                          size: 28,
                          weight: FontWeight.w700,
                          color: colors.textPrimary,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!documentsApproved) ...[
                        _DraftBanner(colors: colors),
                        const SizedBox(height: 24),
                      ],
                      for (final section in sections) ...[
                        Text(
                          section.heading,
                          style: AppType.chrome(
                            size: 17,
                            weight: FontWeight.w700,
                            color: colors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          section.body,
                          style: AppType.chrome(
                            size: 15,
                            color: colors.textMuted,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner({required this.colors});

  final AppPalette colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colors.activeTint,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: colors.active.withValues(alpha: 0.45)),
    ),
    child: Text(
      legalDocumentDraftBanner,
      style: AppType.chrome(
        size: 15,
        weight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.4,
      ),
    ),
  );
}
