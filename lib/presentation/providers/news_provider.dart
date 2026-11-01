import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/news/news_client.dart';
import '../../models/news_models.dart';
import 'content_update_provider.dart';

final newsClientProvider = Provider<NewsClient>((ref) {
  final auth = ref.read(contentAuthProvider);
  return NewsClient(
    auth.url.isEmpty ? null : Uri.parse(auth.url),
    auth.publicKey,
  );
});

/// The newest daily articles of a learning language, saved for offline use.
final newsProvider =
    AsyncNotifierProvider.family<NewsNotifier, List<NewsArticle>, String>(
      NewsNotifier.new,
    );

class NewsNotifier extends AsyncNotifier<List<NewsArticle>> {
  NewsNotifier(this.lang);

  final String lang;
  DateTime? _loaded;

  @override
  Future<List<NewsArticle>> build() {
    _loaded = DateTime.now();
    return ref.read(newsClientProvider).latest(lang);
  }

  /// News change once a day: opening the Stories tab reloads them after a
  /// few hours. Keeps what is shown when the new answer is empty.
  Future<void> refreshIfStale({Duration after = const Duration(hours: 2)}) async {
    final loaded = _loaded;
    if (loaded != null && DateTime.now().difference(loaded) < after) return;
    _loaded = DateTime.now();
    final next = await AsyncValue.guard(
      () => ref.read(newsClientProvider).latest(lang),
    );
    if (next.value?.isNotEmpty ?? false) state = next;
  }
}
