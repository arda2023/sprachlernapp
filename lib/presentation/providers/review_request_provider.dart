import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/platform/json_store.dart';
import '../../data/review/native_review_gateway.dart';
import '../review/review_request_service.dart';
import 'database_providers.dart';

final reviewRequestServiceProvider = Provider<ReviewRequestService>((ref) {
  return ReviewRequestService(
    store: platformJsonStore('review_requests'),
    gateway: NativeReviewGateway(),
    clock: ref.watch(clockProvider),
    supported:
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android),
  );
});
