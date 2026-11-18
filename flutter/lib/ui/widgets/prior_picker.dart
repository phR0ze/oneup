import 'package:flutter/material.dart';
import '../../const.dart';

/// The result of the prior picker: a date and whether the whole week containing it was selected
/// (true) or just that single day (false).
typedef PriorSelection = ({DateTime date, bool week});

/// Monday at 00:00 of the week containing the given date
DateTime weekStartOf(DateTime date) {
  final mon = date.subtract(Duration(days: date.weekday - 1));
  return DateTime(mon.year, mon.month, mon.day);
}

/// Dialog allowing the user to select either a single prior day or a whole prior week. Tapping a
/// day selects just that day; tapping the week button at the left of a row selects the whole week.
class PriorPickerDialog extends StatefulWidget {
  const PriorPickerDialog({super.key, required this.initial});
  final PriorSelection initial;

  @override
  State<PriorPickerDialog> createState() => _PriorPickerDialogState();
}

class _PriorPickerDialogState extends State<PriorPickerDialog> {
  late PriorSelection _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  String _fmt(DateTime d) => '${_monthAbbr(d.month)} ${d.day}';

  String _monthAbbr(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];

  String _label() {
    final d = _selected.date;
    if (_selected.week) {
      final start = weekStartOf(d);
      final end = start.add(const Duration(days: 6));
      return 'Week: ${_fmt(start)} – ${_fmt(end)}, ${start.year}';
    }
    return 'Day: ${_fmt(d)}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300, minWidth: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 15, 5, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Day or Week',
                style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_label(),
                style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
              _MonthCalendar(
                selected: _selected,
                firstDate: DateTime(2020),
                lastDate: now,
                onChanged: (sel) => setState(() => _selected = sel),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 5),
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.green),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    onPressed: () => Navigator.pop<PriorSelection>(context, _selected),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final PriorSelection selected;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<PriorSelection> onChanged;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  late DateTime _month;

  static const _rowHeight = 32.0;

  // Monday-first to match the app's Monday–Sunday week ranges, so each row is exactly one week
  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selected.date.year, widget.selected.date.month);
  }

  bool get _canPrev => _month.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
  bool get _canNext => _month.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = widget.selected.date;
    final selectedDay = DateTime(sel.year, sel.month, sel.day);
    final selectedWeek = widget.selected.week ? weekStartOf(sel) : null;

    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    // DateTime.weekday: 1=Mon..7=Sun → offset for Mon-first grid: Mon=0..Sun=6
    final startOffset = firstDay.weekday - 1;
    final rowCount = ((startOffset + daysInMonth) / 7).ceil();

    final dayRows = List.generate(rowCount, (row) {
      final rowMonday = DateTime(_month.year, _month.month, 1 - startOffset + row * 7);
      final isWeekSelected = selectedWeek == rowMonday;
      final weekDisabled = rowMonday.isAfter(widget.lastDate)
        || rowMonday.add(const Duration(days: 6)).isBefore(widget.firstDate);

      final days = List.generate(7, (col) {
        final day = row * 7 + col - startOffset + 1;
        if (day < 1 || day > daysInMonth) return const Expanded(child: SizedBox());
        final date = DateTime(_month.year, _month.month, day);
        return Expanded(
          child: _DayCell(
            day: day,
            isSelected: !widget.selected.week && date == selectedDay,
            isToday: date == today,
            isDisabled: date.isAfter(widget.lastDate) || date.isBefore(widget.firstDate),
            onTap: () => widget.onChanged((date: date, week: false)),
          ),
        );
      });

      return Row(
        children: [
          Expanded(
            child: _WeekButton(
              isSelected: isWeekSelected,
              isDisabled: weekDisabled,
              onTap: () => widget.onChanged((date: rowMonday, week: true)),
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              height: _rowHeight - 2,
              decoration: isWeekSelected
                ? BoxDecoration(
                    color: Const.neutralPointsValueBgColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(15),
                  )
                : null,
              child: Row(children: days),
            ),
          ),
        ],
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month/year header — same 8-column structure as the grid so arrows align
        Row(
          children: [
            Expanded(
              flex: 6,
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDialog<DateTime>(
                    context: context,
                    builder: (ctx) => Dialog(
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: YearPicker(
                          firstDate: widget.firstDate,
                          lastDate: widget.lastDate,
                          selectedDate: _month,
                          onChanged: (date) => Navigator.pop(ctx, date),
                        ),
                      ),
                    ),
                  );
                  if (picked != null) {
                    setState(() => _month = DateTime(picked.year, _month.month));
                  }
                },
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Text(
                      '${_monthNames[_month.month]} ${_month.year}',
                      style: textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _canPrev
                    ? () => setState(() => _month = DateTime(_month.year, _month.month - 1))
                    : null,
                  child: Icon(Icons.chevron_left,
                    color: _canPrev ? Colors.black : Colors.black26),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _canNext
                    ? () => setState(() => _month = DateTime(_month.year, _month.month + 1))
                    : null,
                  child: Icon(Icons.chevron_right,
                    color: _canNext ? Colors.black : Colors.black26),
                ),
              ),
            ),
          ],
        ),

        // Weekday letters, with an empty leading column above the week buttons
        Row(
          children: [
            const Expanded(child: SizedBox()),
            ..._weekdayLetters.map((d) => Expanded(
              child: Center(
                child: Text(d,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
              ),
            )),
          ],
        ),

        // Day grid — fixed height for 6 rows so buttons don't shift between months
        SizedBox(
          height: 6 * _rowHeight,
          child: Column(
            children: dayRows.map((r) => SizedBox(height: _rowHeight, child: r)).toList(),
          ),
        ),
      ],
    );
  }
}

/// Button at the left of each calendar row that selects the whole week
class _WeekButton extends StatelessWidget {
  const _WeekButton({
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Select whole week',
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Center(
          child: Container(
            width: 28,
            height: 26,
            decoration: BoxDecoration(
              color: isSelected ? Const.neutralPointsValueBgColor : null,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDisabled ? Colors.black12 : Const.neutralPointsValueBgColor,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.date_range,
              size: 16,
              color: isDisabled ? Colors.black26 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = isSelected
      ? const BoxDecoration(shape: BoxShape.circle, color: Const.neutralPointsValueBgColor)
      : isToday
        ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Const.neutralPointsValueBgColor, width: 1.5),
          )
        : null;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: decoration,
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isDisabled ? Colors.black26 : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
