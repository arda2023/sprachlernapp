import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../../domain/widget_snapshot.dart';
import 'widget_gateway.dart';

class HomeWidgetGateway implements WidgetGateway {
  static const appGroup = 'group.com.ardasayar.linglossa';
  static const kinds = [
    'LinglossaStreak',
    'LinglossaWeek',
    'LinglossaLearning',
  ];
  Future<void>? _ready;
  final _coverFiles = <String, String>{};

  @override
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _initialize() =>
      _ready ??= HomeWidget.setAppGroupId(appGroup)
          .then<void>((_) {})
          .catchError((Object error) {
            _ready = null;
            throw error;
          });

  @override
  Stream<Uri?> get launches =>
      supported ? HomeWidget.widgetClicked : const Stream.empty();

  @override
  Future<Uri?> initialLaunch() async =>
      supported ? HomeWidget.initiallyLaunchedFromHomeWidget() : null;

  @override
  Future<void> write(LearningWidgetSnapshot snapshot) async {
    if (!supported) return;
    await _initialize();
    final data = Map<String, Object?>.of(snapshot.json);
    final asset = snapshot.coverAsset;
    if (asset != null && data['story'] is Map) {
      final story = data['story'] as Map;
      String? fileName;
      try {
        fileName = _coverFiles[asset];
        if (fileName == null) {
          final data = await rootBundle.load(asset);
          final bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          final key = 'cover_${sha256.convert(bytes)}';
          await HomeWidget.saveFile(key, bytes, extension: 'png');
          fileName = '$key.png';
          _coverFiles[asset] = fileName;
        }
      } catch (_) {
        fileName = null;
      }
      data['story'] = {...story, 'coverFileName': fileName};
    }
    await HomeWidget.saveWidgetData<String>(
      'learningSnapshot',
      jsonEncode(data),
    );
  }

  @override
  Future<void> reload() async {
    if (!supported) return;
    for (final kind in kinds) {
      await HomeWidget.updateWidget(iOSName: kind);
    }
  }
}
