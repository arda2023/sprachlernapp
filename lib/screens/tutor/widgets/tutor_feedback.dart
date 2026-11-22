import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../domain/tutor.dart';
import '../../../theme/app_theme.dart';
import 'tutor_info_chip.dart';

Color tutorOutcomeColor(AppPalette colors, TutorOutcome outcome) =>
    switch (outcome) {
      TutorOutcome.correct => colors.success,
      TutorOutcome.acceptable => colors.active,
      TutorOutcome.incorrect => colors.error,
    };

Color tutorOutcomeTint(AppPalette colors, TutorOutcome outcome) =>
    switch (outcome) {
      TutorOutcome.correct => colors.successTint,
      TutorOutcome.acceptable => colors.activeTint,
      TutorOutcome.incorrect => colors.errorTint,
    };

enum TutorDimension {
  meaning('Bedeutung'),
  grammar('Grammatik'),
  naturalness('Natürlichkeit');

  const TutorDimension(this.label);
  final String label;

  String verdict(int score) => switch ((this, score)) {
    (meaning, 2) => 'richtig übertragen',
    (meaning, 1) => 'kleine Abweichung',
    (meaning, _) => 'Bedeutung verändert',
    (grammar, 2) => 'fehlerfrei',
    (grammar, 1) => 'kleiner Fehler',
    (grammar, _) => 'größerer Fehler',
    (naturalness, 2) => 'natürlich formuliert',
    (naturalness, 1) => 'etwas ungewohnt',
    (naturalness, _) => 'unnatürlich formuliert',
  };

  // Exactly one sentence: definition and verdict are joined by a colon.
  String explanation(int score) => switch (this) {
    meaning =>
      'Bedeutung prüft, ob die Aussage erhalten bleibt: ${switch (score) {
        2 => 'Hier ist alles Wesentliche richtig übertragen',
        1 => 'Hier bleibt die Kernaussage mit einer kleinen Abweichung erhalten',
        _ => 'Hier fehlt oder verändert sich ein wesentlicher Teil der Aussage',
      }}.',
    grammar =>
      'Grammatik prüft Zeitformen, Endungen und Satzbau: ${switch (score) {
        2 => 'Hier ist alles korrekt',
        1 => 'Hier stört ein kleiner Fehler das Verständnis nicht',
        _ => 'Hier gibt es einen größeren Fehler',
      }}.',
    naturalness =>
      'Natürlichkeit prüft, wie üblich die Formulierung klingt: ${switch (score) {
        2 => 'Hier klingt sie natürlich',
        1 => 'Hier ist sie verständlich, aber etwas ungewohnt',
        _ => 'Hier klingt sie deutlich unnatürlich',
      }}.',
  };
}

class TutorFeedback extends StatelessWidget {
  const TutorFeedback({super.key, required this.attempt});
  final TutorAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final largeLabels = MediaQuery.textScalerOf(context).scale(13) > 18;
    final colors = context.appColors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 650),
      builder: (context, t, _) {
        final prose = Curves.easeOut.transform(
          ((t - .62) / .38).clamp(0.0, 1.0),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flex(
              direction: largeLabels ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: largeLabels
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.start,
              children: [
                for (final (i, dimension) in TutorDimension.values.indexed)
                  // flex 0 keeps the stacked large-text rows unflexed.
                  Flexible(
                    flex: largeLabels ? 0 : 1,
                    fit: FlexFit.tight,
                    child: Builder(
                      builder: (context) {
                        final score = [
                          attempt.scores.meaning,
                          attempt.scores.grammar,
                          attempt.scores.naturalness,
                        ][i];
                        final entry = ((t - i * .12) / .4).clamp(0.0, 1.0);
                        final color = switch (score) {
                          2 => colors.success,
                          1 => colors.active,
                          _ => colors.error,
                        };
                        return Opacity(
                          opacity: Curves.easeOut.transform(entry),
                          child: Transform.scale(
                            scale:
                                .85 + .15 * Curves.easeOutBack.transform(entry),
                            child: TutorPopoverButton(
                              key: ValueKey('tutor-score-${dimension.name}'),
                              label:
                                  '${dimension.label}: ${dimension.verdict(score)}',
                              explanation: dimension.explanation(score),
                              builder: (context, open) => Container(
                                width: double.infinity,
                                padding: largeLabels
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      )
                                    : const EdgeInsets.symmetric(
                                        horizontal: 2,
                                        vertical: 8,
                                      ),
                                decoration: BoxDecoration(
                                  color: open ? colors.popover : null,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Flex(
                                  direction: largeLabels
                                      ? Axis.horizontal
                                      : Axis.vertical,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomPaint(
                                      size: const Size(32, 32),
                                      painter: TutorVerdictPainter(
                                        score: score,
                                        progress: entry,
                                        color: open ? colors.onActive : color,
                                      ),
                                    ),
                                    const SizedBox(width: 10, height: 5),
                                    Flexible(
                                      flex: largeLabels ? 1 : 0,
                                      child: Text(
                                        dimension.label,
                                        textAlign: largeLabels
                                            ? TextAlign.start
                                            : TextAlign.center,
                                        style: AppType.chrome(
                                          size: 13,
                                          weight: FontWeight.w500,
                                          color: open
                                              ? colors.onActive
                                              : colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Opacity(
              opacity: prose,
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      attempt.feedbackDe,
                      key: const Key('tutor-feedback-text'),
                      style: AppType.chrome(
                        size: 15,
                        height: 1.35,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Idealer Satz',
                      style: AppType.chrome(size: 13, color: colors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attempt.idealAnswer,
                      key: const Key('tutor-ideal-answer'),
                      style: AppType.editorial(
                        size: 17,
                        height: 1.35,
                        weight: FontWeight.w400,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Draws the verdict, like the completion screen's traced check. The optional
/// ring and six dots reuse its small, one-shot celebration vocabulary.
class TutorVerdictPainter extends CustomPainter {
  const TutorVerdictPainter({
    required this.score,
    required this.progress,
    required this.color,
    this.celebrate = false,
  });
  final int score;
  final double progress;
  final Color color;
  final bool celebrate;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    canvas.drawCircle(
      const Offset(16, 16),
      16,
      Paint()..color = color.withValues(alpha: .13),
    );
    if (celebrate && progress > 0 && progress < 1) {
      final ring = Curves.easeOutCubic.transform(progress);
      canvas.drawCircle(
        const Offset(16, 16),
        12 + ring * 11,
        Paint()
          ..color = color.withValues(alpha: 1 - progress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * (1 - progress),
      );
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        canvas.drawCircle(
          Offset(
            16 + math.cos(a) * (16 + 8 * ring),
            16 + math.sin(a) * (16 + 8 * ring),
          ),
          1.4 * (1 - progress),
          Paint()..color = color,
        );
      }
    }
    final paths = switch (score) {
      2 => [
        Path()
          ..moveTo(9, 16)
          ..lineTo(14, 21)
          ..lineTo(23, 11),
      ],
      1 => [
        for (final y in [13.0, 19.0])
          Path()
            ..moveTo(8, y)
            ..cubicTo(13, y - 6, 19, y + 6, 24, y),
      ],
      _ => [
        Path()
          ..moveTo(10, 10)
          ..lineTo(22, 22),
        Path()
          ..moveTo(22, 10)
          ..lineTo(10, 22),
      ],
    };
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.2;
    for (final (i, path) in paths.indexed) {
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(
          0,
          metric.length * (progress * paths.length - i).clamp(0.0, 1.0),
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TutorVerdictPainter old) =>
      old.score != score ||
      old.progress != progress ||
      old.color != color ||
      old.celebrate != celebrate;
}
