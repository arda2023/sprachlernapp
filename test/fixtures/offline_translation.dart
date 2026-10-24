import 'dart:io';
import 'package:device_translation/device_translation.dart';
import 'package:sprachapp/data/offline_translation/offline_dictionary.dart';

/// Existing HTTP/cache widget scenarios do not perform filesystem/platform IO.
/// Real asset installation and channel integration have separate tests.
class EmptyDictionary extends OfflineDictionary {
  EmptyDictionary() : super(directory: () async => Directory('unused'), asset: (_) async => throw StateError('unused'));
  @override
  Future<List<DictionaryCandidate>> lookup(String lang, String form) async => [];
}
class UnsupportedDeviceTranslation extends DeviceTranslation {
  @override
  Future<DeviceModelState> status(String lang) async => DeviceModelState.unsupported;
  @override
  Future<void> cancel() async {}
}
