const _monthsDe = [
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', //
  'August', 'September', 'Oktober', 'November', 'Dezember',
];

/// German long date in local time: 2027-03-12 → "12. März 2027".
String formatDateDe(DateTime date) {
  final local = date.toLocal();
  return '${local.day}. ${_monthsDe[local.month - 1]} ${local.year}';
}
