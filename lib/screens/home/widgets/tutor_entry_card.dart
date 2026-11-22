import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/premium_offer.dart';
import '../../../presentation/providers/premium_access_provider.dart';
import '../../../presentation/providers/tutor_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/premium_content_gate.dart';
import '../../../widgets/press_scale.dart';
import '../../tutor/tutor_screen.dart';

/// The only tutor surface on Home; exercises live on their own route.
class TutorEntryCard extends ConsumerStatefulWidget {
  const TutorEntryCard({super.key});

  @override
  ConsumerState<TutorEntryCard> createState() => _TutorEntryCardState();
}

class _TutorEntryCardState extends ConsumerState<TutorEntryCard> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final available = ref.read(tutorAvailabilityProvider).asData?.value;
      final remaining = ref.read(tutorRemainingFreeTodayProvider).asData?.value;
      if (available == TutorAvailability.available &&
          !ref.read(premiumContentAccessProvider) &&
          remaining == 0) {
        final unlocked = await showPremiumContentPaywall(
          context,
          interest: 'AI-Tutor',
          reason: PremiumOfferReason.tutor,
        );
        if (!unlocked || !mounted) return;
      }
      if (mounted) await TutorScreen.open(context);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final availability = ref.watch(tutorAvailabilityProvider);
    final premium = ref.watch(premiumContentAccessProvider);
    final remaining = premium
        ? null
        : ref.watch(tutorRemainingFreeTodayProvider).asData?.value;
    final unavailable =
        availability.asData?.value == TutorAvailability.unsupportedLanguage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: PressScale(
        child: MergeSemantics(
          child: CupertinoButton(
            key: const Key('tutor-entry'),
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            color: colors.raisedInk,
            disabledColor: colors.raisedInk,
            onPressed: _opening ? null : _open,
            child: Semantics(
              label:
                  'AI-Tutor, Sätze frei übersetzen. Bis zu 10 Sätze pro Runde.'
                  '${remaining == null ? '' : ' Heute noch $remaining Sätze frei.'}'
                  '${unavailable ? ' Für diese Sprache noch nicht verfügbar.' : ''}',
              excludeSemantics: true,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.activeTint,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.sparkles,
                                size: 15,
                                color: colors.active,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'AI-Tutor',
                                style: AppType.chrome(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sätze frei übersetzen',
                          style: AppType.editorial(
                            size: 20,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bis zu 10 Sätze pro Runde.',
                          style: AppType.chrome(
                            size: 13,
                            color: colors.textMuted,
                          ),
                        ),
                        if (!premium) ...[
                          const SizedBox(height: 4),
                          Text(
                            remaining == null
                                ? 'Freie Sätze werden geladen …'
                                : 'Heute noch $remaining Sätze frei',
                            style: AppType.chrome(
                              size: 13,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 15,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
