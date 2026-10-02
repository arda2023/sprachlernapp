import 'package:flutter/foundation.dart';

/// Stories the learner has opened, in memory until the Drift layer exists.
/// Feeds "Aus deinen Stories" in the text library.
class ReadingHistory extends ChangeNotifier {
  ReadingHistory([Iterable<String> storyIds = const []]) : _ids = {...storyIds};

  final Set<String> _ids;

  Set<String> get storyIds => Set.unmodifiable(_ids);

  void markRead(String storyId) {
    if (_ids.add(storyId)) notifyListeners();
  }
}
