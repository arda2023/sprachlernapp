import 'package:flutter/services.dart';

enum DeviceModelState { installed, supported, unsupported }

class DeviceTranslation {
  static const channel = MethodChannel('device_translation');
  Future<DeviceModelState> status(String lang) async {
    if (!{'en', 'pt-BR'}.contains(lang)) return DeviceModelState.unsupported;
    try {
      final value = await channel.invokeMethod<String>('status', {
        'lang': lang,
      });
      return DeviceModelState.values.firstWhere(
        (v) => v.name == value,
        orElse: () => DeviceModelState.unsupported,
      );
    } on MissingPluginException {
      return DeviceModelState.unsupported;
    }
  }

  Future<void> prepare(String lang) =>
      channel.invokeMethod<void>('prepare', {'lang': lang});
  Future<String> translate(String lang, String text) async {
    if (!{'en', 'pt-BR'}.contains(lang) ||
        text.trim().isEmpty ||
        text.length > 600) {
      throw PlatformException(code: 'invalid');
    }
    final value = await channel.invokeMethod<String>('translate', {
      'lang': lang,
      'text': text,
    });
    if (value == null || value.trim().isEmpty || value.length > 2400) {
      throw PlatformException(code: 'invalid_result');
    }
    return value;
  }

  Future<void> cancel() async {
    try {
      await channel.invokeMethod<void>('cancel');
    } on MissingPluginException {
      /* unsupported host */
    }
  }
}
