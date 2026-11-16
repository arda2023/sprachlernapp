import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/billing/premium_offer_history.dart';
import 'database_providers.dart';

final premiumOfferHistoryProvider = FutureProvider<PremiumOfferHistory>((
  ref,
) async {
  final database = await ref.watch(userDatabaseProvider.future);
  return PremiumOfferHistory(database, clock: ref.read(clockProvider));
});
