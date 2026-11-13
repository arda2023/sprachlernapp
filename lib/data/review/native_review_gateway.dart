import 'package:in_app_review/in_app_review.dart';

import '../../domain/review_request.dart';

class NativeReviewGateway implements ReviewGateway {
  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}
