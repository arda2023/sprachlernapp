import '../../domain/widget_snapshot.dart';

abstract interface class WidgetGateway {
  bool get supported;
  Stream<Uri?> get launches;
  Future<Uri?> initialLaunch();
  Future<void> write(LearningWidgetSnapshot snapshot);
  Future<void> reload();
}
