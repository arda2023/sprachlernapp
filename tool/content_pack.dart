import 'dart:io';

class HeadwordEntry {
  const HeadwordEntry({
    required this.headword,
    required this.forms,
    required this.totalFrequency,
  });

  final String headword;
  final List<String> forms;
  final int totalFrequency;
}

List<HeadwordEntry> readWordlist(String path) {
  final lines = File(path).readAsLinesSync();
  final entries = <HeadwordEntry>[];
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final parts = line.split(',');
    if (parts.length != 3) {
      throw FormatException('Unerwartete Zeile: $line');
    }
    entries.add(
      HeadwordEntry(
        headword: parts[0],
        forms: parts[1].split('|'),
        totalFrequency: int.parse(parts[2]),
      ),
    );
  }
  return entries;
}

void main() {
  final entries = readWordlist('tool/data/wordlist_1k.csv');
  stdout.writeln('Einträge: ${entries.length}');
  for (final e in entries.take(5)) {
    stdout.writeln('${e.headword}: ${e.forms}');
  }
  final broken = entries.where((e) => !e.forms.contains(e.headword));
  stdout.writeln('Headword nicht in eigener Formenliste: ${broken.length}');
}
