import 'package:flutter/painting.dart';

import '../domain/emphasis.dart';

/// [source] on [style], with its `*…*` forms in italic w600 `textPrimary`:
/// the citation convention of print grammars, never an ink.
TextSpan emphasisSpan(String source, TextStyle style) => TextSpan(
  style: style,
  children: [
    for (final piece in parseEmphasis(source))
      TextSpan(
        text: piece.text,
        style: piece.emphasis
            ? emphasisStyle.copyWith(color: style.color)
            : null,
      ),
  ],
);

const emphasisStyle = TextStyle(
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.w600,
);
