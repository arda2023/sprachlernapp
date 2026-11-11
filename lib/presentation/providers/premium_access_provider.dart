import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/content_access_policy.dart';
import 'content_access_provider.dart';

/// Uses verified entitlement state, including the authorized sandbox test.
/// Unknown or expired access never unlocks paid content.
final premiumContentAccessProvider = Provider<bool>(
  (ref) => ref.watch(contentAccessProvider) == ContentAccessDecision.allowed,
);

/// Stable IDs of the Allgemeine Sprache deck in each bundled language pack.
/// Unknown and user-generated decks fail closed; labels are not authorization.
bool isFreeDeckId(String id) => const {
  '4630a4856f603afdad2f24776298c19a', // en
  'a68fbd9bac7f8fdad3a1d050663743bf', // es
  '710dcd3adadb272f2276325a383ba80e', // it
  '642b44a10fc668638c5361ec8ba784dc', // nb
  '50412378b3aeccaa77cfbffd65e55b0e', // pt-BR
}.contains(id);
