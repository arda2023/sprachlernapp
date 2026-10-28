import 'package:flutter/cupertino.dart';

import '../../../domain/streak.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/popover_content.dart';
import '../../../widgets/svg_glyph.dart';

/// Popover content behind the flame: current streak, earned week stars and a
/// month calendar where streak days join into bands and star days stand out.
/// Drawn in white for the coloured popover.
class StreakCalendar extends StatefulWidget {
  const StreakCalendar({super.key, required this.summary, required this.today});

  final StreakSummary summary;
  final DateTime today;

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

const _months = [
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', //
  'August', 'September', 'Oktober', 'November', 'Dezember',
];
const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const _ink = Color(0xFFFFFFFF);
// Text on the popover is bold or 18 pt+ and never translucent (white on
// #E26C00 is 3.3:1, see PopoverText); quieter text is lighter in weight only.
const _muted = _ink;

class _StreakCalendarState extends State<StreakCalendar> {
  late DateTime _month = DateTime(widget.today.year, widget.today.month);

  DateTime get _earliest {
    final days = widget.summary.activeDays;
    if (days.isEmpty) return _month;
    final first = days.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(first.year, first.month);
  }

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final current = DateTime(widget.today.year, widget.today.month);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: const Icon(
                    CupertinoIcons.flame_fill,
                    size: 26,
                    color: _ink,
                  ),
                  value: s.current == 1 ? '1 Tag' : '${s.current} Tage',
                  label: 'Aktueller Streak',
                ),
              ),
              Container(width: 1, color: const Color(0x40FFFFFF)),
              Expanded(
                child: _Stat(
                  icon: const GlyphIcon(
                    AppGlyphs.starSolid,
                    size: 24,
                    color: _ink,
                  ),
                  value: s.weeks == 1 ? '1 Woche' : '${s.weeks} Wochen',
                  label: 'Wochensterne',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _NavButton(
              icon: CupertinoIcons.chevron_left,
              label: 'Vorheriger Monat',
              onTap: _month.isAfter(_earliest) ? () => _shift(-1) : null,
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: AppType.chrome(
                    size: 17,
                    weight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ),
            _NavButton(
              icon: CupertinoIcons.chevron_right,
              label: 'Nächster Monat',
              onTap: _month.isBefore(current) ? () => _shift(1) : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _MonthGrid(month: _month, summary: s, today: widget.today),
        const SizedBox(height: 12),
        Text(
          '7 Tage am Stück ergeben einen Wochenstern. Deine Sterne bleiben, '
          'auch wenn eine Serie einmal reißt.',
          style: PopoverText.small(),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppType.chrome(
                      size: 18,
                      weight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  Text(label, style: PopoverText.caption()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: CupertinoButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? const Color(0x66FFFFFF) : _ink,
        ),
      ),
    ),
  );
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.summary,
    required this.today,
  });

  final DateTime month;
  final StreakSummary summary;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final lead = first.weekday - 1;
    final length = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((lead + length) / 7).ceil();
    bool on(int day) =>
        summary.activeDays.contains(DateTime(month.year, month.month, day));
    final todayDay = calendarDay(today);

    return Column(
      children: [
        Row(
          children: [
            for (final name in _weekdays)
              Expanded(
                child: Center(
                  child: Text(name, style: PopoverText.caption()),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final n = r * 7 + c - lead + 1;
                        if (n < 1 || n > length) {
                          return const SizedBox(height: 38);
                        }
                        final day = DateTime(month.year, month.month, n);
                        final isOn = on(n);
                        return _DayCell(
                          day: n,
                          on: isOn,
                          star: summary.starDays.contains(day),
                          today: day == todayDay,
                          joinLeft: isOn && c > 0 && n > 1 && on(n - 1),
                          joinRight: isOn && c < 6 && n < length && on(n + 1),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.on,
    required this.star,
    required this.today,
    required this.joinLeft,
    required this.joinRight,
  });

  final int day;
  final bool on, star, today, joinLeft, joinRight;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(19);
    final label =
        '$day.${star
            ? ', Wochenstern'
            : on
            ? ', geübt'
            : ''}${today ? ', heute' : ''}';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 38,
        decoration: on
            ? BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.horizontal(
                  left: joinLeft ? Radius.zero : radius,
                  right: joinRight ? Radius.zero : radius,
                ),
              )
            : null,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: star ? _ink : null,
                border: today && !star
                    ? Border.all(color: _ink, width: 1.5)
                    : null,
              ),
              child: Text(
                '$day',
                style: AppType.chrome(
                  size: 15,
                  weight: on || today ? FontWeight.w800 : FontWeight.w700,
                  color: star
                      ? context.appColors.popover
                      : on || today
                      ? _ink
                      : _muted,
                  tabular: true,
                ),
              ),
            ),
            if (star)
              const Positioned(
                top: -5,
                right: -3,
                child: GlyphIcon(
                  AppGlyphs.starSolid,
                  size: 14,
                  color: Color(0xFFFFD27A),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
