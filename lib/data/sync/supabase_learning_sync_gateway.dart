import 'package:supabase_flutter/supabase_flutter.dart';

import '../content/content_auth_repository.dart';
import 'learning_sync.dart';

class SupabaseLearningSyncGateway implements LearningSyncGateway {
  SupabaseLearningSyncGateway(ContentAuthRepository auth, String owner)
    : _client = SupabaseClient(
        auth.url,
        auth.publicKey,
        accessToken: () async {
          if (await auth.cacheOwner() != owner) {
            throw StateError('Lernkonto hat sich geändert.');
          }
          final token = await auth.accessToken();
          if (auth.localOwner != owner) {
            throw StateError('Lernkonto hat sich geändert.');
          }
          return token;
        },
      );
  final SupabaseClient _client;
  @override
  Future<void> push(List<LearningSyncRow> rows) async {
    await _client
        .rpc(
          'push_learning_rows',
          params: {'rows': rows.map((r) => r.toJson()).toList()},
        )
        .timeout(const Duration(seconds: 30));
  }

  @override
  Future<List<LearningSyncRow>> pull({String? after}) async {
    final result = await _client
        .rpc('pull_learning_rows', params: {'after_key': after})
        .timeout(const Duration(seconds: 30));
    return (result as List)
        .map(
          (r) => LearningSyncRow.fromJson(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  Future<void> close() => _client.dispose();
}
