import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/theme/app_theme.dart';

/// Every literal size passed to [AppType.chrome] or [AppType.editorial]
/// belongs to its scale (user request 01.11.2026: one consistent set of
/// font sizes across the app).
void main() {
  test('literal font sizes stay on the type scale', () {
    final call = RegExp(r'AppType\.(chrome|editorial)\(');
    final size = RegExp(r'(?<![\w.])size:\s*(\d+(?:\.\d+)?)\b');
    final offScale = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final match in call.allMatches(source)) {
        var depth = 0;
        var end = match.end - 1;
        for (; end < source.length; end++) {
          if (source[end] == '(') depth++;
          if (source[end] == ')' && --depth == 0) break;
        }
        final literal = size.firstMatch(source.substring(match.end, end));
        if (literal == null) continue;
        final value = double.parse(literal.group(1)!);
        final scale = match.group(1) == 'chrome'
            ? AppType.chromeScale
            : AppType.editorialScale;
        if (!scale.contains(value)) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          offScale.add('${file.path}:${line + 1} ${match.group(1)} $value');
        }
      }
    }
    expect(offScale, isEmpty);
  });

  test('raw font sizes stay on the chrome scale', () {
    final raw = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)\b');
    final offScale = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          for (final m in raw.allMatches(file.readAsStringSync()))
            if (!AppType.chromeScale.contains(double.parse(m.group(1)!)))
              '${file.path} ${m.group(0)}',
    ];
    expect(offScale, isEmpty);
  });
}
