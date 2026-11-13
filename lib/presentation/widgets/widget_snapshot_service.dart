import '../../data/widgets/widget_gateway.dart';
import '../../domain/widget_snapshot.dart';

/// Serializes shared-container writes so a prior account can never finish last.
class WidgetSnapshotService {
  WidgetSnapshotService(this.gateway);
  final WidgetGateway gateway;
  Future<void> _tail = Future.value();
  int _generation = 0;
  bool _disposed = false;

  Future<void> publish(LearningWidgetSnapshot snapshot) {
    if (!gateway.supported || _disposed) return Future.value();
    final generation = ++_generation;
    return _tail = _tail.then((_) async {
      if (_disposed ||
          (generation != _generation && snapshot.json['available'] != false)) {
        return;
      }
      try {
        await gateway.write(snapshot);
        // Reload even an intermediate clear: an account transition must not
        // leave the previous user's pixels visible until another app launch.
        await gateway.reload();
      } catch (_) {
        // Widget I/O must not break practice or account deletion. The next
        // lifecycle/data change retries; no exception text containing data.
      }
    });
  }

  void dispose() {
    _disposed = true;
    _generation++;
  }
}
