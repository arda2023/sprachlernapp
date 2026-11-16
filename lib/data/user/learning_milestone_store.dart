import 'package:drift/drift.dart';

import '../../domain/learning_milestone.dart';
import 'user_database.dart';

/// The database belongs to one local learning account. A successful insert
/// both persists the achievement and hands its one-time celebration to the
/// caller.
class LearningMilestoneStore {
  const LearningMilestoneStore(this._db);

  final UserDatabase _db;

  Future<bool> claim(LearningMilestone milestone) async {
    await _db.customStatement(
      'CREATE TABLE IF NOT EXISTS learning_milestone_marks '
      '(milestone TEXT PRIMARY KEY NOT NULL)',
    );
    return await _db.customUpdate(
          'INSERT OR IGNORE INTO learning_milestone_marks (milestone) VALUES (?)',
          variables: [Variable(milestone.name)],
        ) ==
        1;
  }

  /// Select the earliest persisted qualifying pass. A previous achievement
  /// predating the introduction of the celebration must not fire retroactively.
  Future<PracticeMilestoneResult> practice(Set<String> passIds) async {
    if (passIds.isEmpty) {
      return (successful: false, milestones: const <LearningMilestone>[]);
    }
    const mastery = LearningMilestone.firstMasteredWord;
    const topic = LearningMilestone.firstTopicPractice;
    final eligible = await _db
        .customSelect(
          'SELECT id FROM review_log WHERE revealed = 0 AND id IN '
          '(${List.filled(passIds.length, '?').join(',')}) LIMIT 1',
          variables: passIds.map(Variable.new).toList(),
        )
        .getSingleOrNull();
    if (eligible == null) {
      return (successful: false, milestones: const <LearningMilestone>[]);
    }

    final awards = <LearningMilestone>[];
    final firstTopic = await _firstPass(
      'INNER JOIN generated_vocabulary_additions a ON a.card_id = r.card_id '
      'WHERE r.revealed = 0 AND r.created_at >= a.added_at',
    );
    final firstMastery = await _firstPass(
      'WHERE r.box_before < 5 AND r.box_after = 5',
    );
    if (passIds.contains(firstTopic) && await claim(topic)) awards.add(topic);
    if (passIds.contains(firstMastery) && await claim(mastery)) {
      awards.add(mastery);
    }
    return (successful: true, milestones: awards);
  }

  Future<String?> _firstPass(String predicate) async {
    final row = await _db
        .customSelect(
          'SELECT r.id FROM review_log r $predicate '
          'ORDER BY r.created_at, r.rowid LIMIT 1',
        )
        .getSingleOrNull();
    return row?.read<String>('id');
  }
}
