import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/learning_reminder_copy.dart';

void main() {
  final first = DateTime.utc(2026, 11, 19);

  test('a stable calendar seed varies each copy in an inactivity cycle', () {
    final copies = [
      for (final (attempt, offset) in [0, 2, 5].indexed)
        learningReminderCopy(
          day: first.add(Duration(days: offset)),
          attempt: attempt,
          hasDueReviews: false,
        ),
    ];
    expect(copies.toSet(), hasLength(3));
    expect(
      learningReminderCopy(day: first, attempt: 0, hasDueReviews: false),
      copies.first,
    );
  });

  test(
    'due reviews outrank purpose, which only influences some first nudges',
    () {
      final travel = learningReminderPurposeCode('Reisen');
      expect(travel, 'travel');
      final days = List.generate(10, (i) => first.add(Duration(days: i)));
      var influenced = 0;
      for (final day in days) {
        LearningReminderCopy copy(int attempt, bool due, [String? purpose]) =>
            learningReminderCopy(
              day: day,
              attempt: attempt,
              hasDueReviews: due,
              purpose: purpose,
            );
        expect(copy(0, true, travel), copy(0, true));
        expect(copy(1, false, travel), copy(1, false));
        if (copy(0, false, travel) != copy(0, false)) influenced++;
      }
      expect(influenced, 2);
    },
  );
}
