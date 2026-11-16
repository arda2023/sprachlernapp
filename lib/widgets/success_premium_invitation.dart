import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/premium_access_provider.dart';
import '../presentation/providers/premium_offer_provider.dart';
import '../theme/app_theme.dart';
import 'premium_content_gate.dart';

final _successOfferProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  id,
) async {
  if (ref.watch(premiumContentAccessProvider)) return false;
  final history = await ref.watch(premiumOfferHistoryProvider.future);
  if (!ref.mounted) return false;
  try {
    return await history.claim(id);
  } catch (_) {
    return false;
  }
});

/// Render only after a real achievement. No automatic modal or purchase.
class SuccessPremiumInvitation extends ConsumerStatefulWidget {
  const SuccessPremiumInvitation({
    super.key,
    required this.opportunityId,
    this.interest = 'Stories',
  });
  final String opportunityId, interest;

  @override
  ConsumerState<SuccessPremiumInvitation> createState() =>
      _SuccessPremiumInvitationState();
}

class _SuccessPremiumInvitationState
    extends ConsumerState<SuccessPremiumInvitation> {
  bool _dismissed = false;

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      await (await ref.read(premiumOfferHistoryProvider.future)).dismiss();
    } catch (_) {
      /* Quiet on a storage failure. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligible =
        ref.watch(_successOfferProvider(widget.opportunityId)).asData?.value ==
        true;
    if (!eligible || _dismissed) return const SizedBox.shrink();
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerLeft,
              onPressed: () async {
                setState(() => _dismissed = true);
                await showPremiumContentPaywall(
                  context,
                  interest: widget.interest,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weiter entdecken',
                    style: AppType.editorial(
                      size: 20,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Premium ansehen',
                    style: AppType.chrome(size: 15, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(12),
            onPressed: _dismiss,
            child: Semantics(
              label: 'Premium-Hinweis schließen',
              child: Icon(
                CupertinoIcons.xmark,
                size: 16,
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
