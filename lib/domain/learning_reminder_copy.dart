typedef LearningReminderCopy = ({String title, String body});

String? learningReminderPurposeCode(Object? label) => switch (label) {
  'travel' || 'Reisen' => 'travel',
  'work' || 'Englisch im Beruf' || 'Beruf' => 'work',
  'everyday' || 'Alltag' => 'everyday',
  'culture' || 'Kultur' => 'culture',
  _ => null,
};

const _general = <LearningReminderCopy>[
  (
    title: 'Zeit für ein paar Wörter',
    body: 'Mach mit einer kurzen Übung weiter.',
  ),
  (title: 'Ein paar Minuten zum Üben?', body: 'Deine nächste Runde wartet.'),
  (
    title: 'Lust auf eine kurze Runde?',
    body: 'Üb ein paar Wörter in deinem Tempo.',
  ),
  (title: 'Ein Moment zum Lernen', body: 'Üb in deinem Tempo weiter.'),
  (title: 'Passt eine kleine Übung?', body: 'Probier ein paar Sätze.'),
  (title: 'Bereit für die nächste Runde?', body: 'Ein paar Minuten genügen.'),
  (title: 'Kurz Zeit zum Lernen?', body: 'Frisch ein paar Wörter auf.'),
];

const _review = <LearningReminderCopy>[
  (title: 'Wörter zum Wiederholen', body: 'Welche fallen dir noch ein?'),
  (
    title: 'Zeit für eine Wiederholung',
    body: 'Frisch ein paar fällige Wörter auf.',
  ),
  (title: 'Schon im Kopf?', body: 'Ein paar Wörter sind wieder dran.'),
];

const _purpose = <String, LearningReminderCopy>{
  'travel': (
    title: 'Ein paar Wörter für unterwegs',
    body: 'Gönn dir eine kurze Übung.',
  ),
  'work': (
    title: 'Zeit für eine kurze Lernpause',
    body: 'Üb ein paar Sätze zwischen zwei Aufgaben.',
  ),
  'everyday': (
    title: 'Ein bisschen Sprache im Alltag',
    body: 'Ein paar Minuten zum Üben?',
  ),
  'culture': (
    title: 'Sprache entdecken',
    body: 'Nimm dir ein paar Minuten für eine Übung.',
  ),
};

/// Later reminders stay general because schedules can outlive the last sync.
/// The optional purpose affects at most the first attempt of some cycles.
LearningReminderCopy learningReminderCopy({
  required DateTime day,
  required int attempt,
  required bool hasDueReviews,
  String? purpose,
}) {
  final seed = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  if (attempt == 0) {
    if (hasDueReviews) return _review[seed % _review.length];
    if (_purpose[purpose] case final copy? when seed % 5 == 0) return copy;
  }
  return _general[seed % _general.length];
}
