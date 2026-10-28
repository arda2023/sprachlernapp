/// Bounded replacement-only segmentation. Titles, initials and decimal points
/// are protected; ambiguous ellipses/internal terminators fail closed. This is
/// not a linguistic quality validator and never validates editorial dialogs.
bool onePersonalSentence(String text) {
  if (text.contains('\n') || text.contains('\r')) return false;
  var s = text.trim();
  s = s.replaceAllMapped(RegExp(r'(?<=\d)\.(?=\d)'), (_) => '·');
  s = s.replaceAllMapped(
    RegExp(
      r'\b(?:Mr|Mrs|Ms|Dr|Prof|Sr|Sra|Srta|Dra|Eng|St)\.(?=\s+\p{L})',
      unicode: true,
      caseSensitive: false,
    ),
    (m) => m[0]!.replaceAll('.', '·'),
  );
  s = s.replaceAllMapped(
    RegExp(r'\b(?:[A-Za-z]\.){2,}(?=\s+\p{L})', unicode: true),
    (m) => m[0]!.replaceAll('.', '·'),
  );
  s = s.replaceAllMapped(
    RegExp(r'\b[A-Z]\.(?=\s+[A-Z][\p{L}]+)', unicode: true),
    (m) => m[0]!.replaceAll('.', '·'),
  );
  s = s.replaceAllMapped(
    RegExp(r'\b(?:etc|approx|ex)\.(?=\s+[a-záéíóúãõç])', caseSensitive: false),
    (m) => m[0]!.replaceAll('.', '·'),
  );
  final ends = RegExp(r'''[.!?…]+["'”’»)]*\s*''').allMatches(s).toList();
  return ends.length == 1 && ends.single.end == s.length;
}
